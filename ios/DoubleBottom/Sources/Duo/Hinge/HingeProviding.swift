import Foundation
import Core

/// Дискретные позы шарнира iPhone Duo (соответствует DeviceHinge.Status в iOS 27.1).
public enum HingeDiscretePosture: String, Codable, Hashable, Sendable {
    case closed        = "closed"         // ~0°–3°
    case slitPeek      = "slitPeek"       // ~3°–25°
    case partiallyOpen = "partiallyOpen"  // ~25°–100° (laptop / tent posture)
    case fullyOpen     = "fullyOpen"      // ~100°–180°
}

/// Единичный отсчёт датчика шарнира (Раздел 5.5).
public struct HingeSample: Equatable, Sendable {
    /// Угол раскрытия в градусах (0...180) или nil, если сырой API вернул только дискретный статус до интерполяции
    public let angleDegrees: Double?
    /// Дискретное положение шарнира
    public let discretePosture: HingeDiscretePosture
    /// true, если угол интерполирован из дискретного состояния или сгенерирован ползунком
    public let isSynthetic: Bool
    /// Монотонная метка времени (секунды)
    public let timestamp: TimeInterval

    public init(
        angleDegrees: Double?,
        discretePosture: HingeDiscretePosture,
        isSynthetic: Bool,
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        self.angleDegrees = angleDegrees
        self.discretePosture = discretePosture
        self.isSynthetic = isSynthetic
        self.timestamp = timestamp
    }
}

/// Единый протокол источника данных шарнира (Раздел 5.5).
/// Весь код правил, сцен и звука зависит только от этого протокола.
public protocol HingeProviding: Sendable {
    var samples: AsyncStream<HingeSample> { get }
}

/// 1. DuoHingeProvider — адаптер к нативному Hinge API iOS 27.1 (`.onHingeChange` / `UIHingeInteraction`).
/// ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ APPLE (iOS 27.1 / Xcode 27.1):
/// В iOS 27.1 модификатор `onHingeChange { oldContext, newContext in }` и `UIHingeInteraction`
/// передают `DeviceHingeContext` (`hinge?.angle: Angle`, `hinge?.status: DeviceHinge.Status`).
/// Если на конкретной ревизии прошивки `hinge?.angle` возвращает `nil` и доступен только `status`,
/// провайдер автоматически интерполирует угол EMA-фильтром и выставляет `isSynthetic = true`.
public final class DuoHingeProvider: HingeProviding, @unchecked Sendable {
    private let continuation: AsyncStream<HingeSample>.Continuation
    public let samples: AsyncStream<HingeSample>
    private var smoothedAngle: Double = 120.0

    public init() {
        var cont: AsyncStream<HingeSample>.Continuation!
        self.samples = AsyncStream<HingeSample> { c in
            cont = c
        }
        self.continuation = cont
    }

    /// Вызывается из SwiftUI `.onHingeChange` или `UIHingeInteraction`
    public func ingestHardwareUpdate(
        reportedAngleDegrees: Double?,
        posture: HingeDiscretePosture,
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        if let exactAngle = reportedAngleDegrees {
            let clamped = min(180.0, max(0.0, exactAngle))
            smoothedAngle = clamped
            continuation.yield(
                HingeSample(
                    angleDegrees: clamped,
                    discretePosture: posture,
                    isSynthetic: false,
                    timestamp: timestamp
                )
            )
        } else {
            // Запасной вариант (Раздел 5.5 п.1): интерполяция в 3 ступени при отсутствии непрерывного угла
            let targetAngle: Double
            switch posture {
            case .closed:        targetAngle = 0.0
            case .slitPeek:      targetAngle = 14.0
            case .partiallyOpen: targetAngle = 45.0
            case .fullyOpen:     targetAngle = 135.0
            }
            smoothedAngle = smoothedAngle * 0.65 + targetAngle * 0.35
            continuation.yield(
                HingeSample(
                    angleDegrees: smoothedAngle,
                    discretePosture: posture,
                    isSynthetic: true,
                    timestamp: timestamp
                )
            )
        }
    }
}

/// 2. SimulatedHingeProvider — для симулятора Duo в Device Hub и для отладки на iPad/Mac (ползунок, клавиши `[` и `]`, жест).
public final class SimulatedHingeProvider: HingeProviding, @unchecked Sendable {
    private let continuation: AsyncStream<HingeSample>.Continuation
    public let samples: AsyncStream<HingeSample>
    private(set) public var currentAngle: Double

    public init(initialAngle: Double = 120.0) {
        self.currentAngle = initialAngle
        var cont: AsyncStream<HingeSample>.Continuation!
        self.samples = AsyncStream<HingeSample> { c in
            cont = c
        }
        self.continuation = cont
        emit(angle: initialAngle)
    }

    public func setAngle(_ angle: Double, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        let clamped = min(180.0, max(0.0, angle))
        currentAngle = clamped
        emit(angle: clamped, timestamp: timestamp)
    }

    public func stepAngle(by delta: Double) {
        setAngle(currentAngle + delta)
    }

    private func emit(angle: Double, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        let posture: HingeDiscretePosture
        if angle <= 3.0 {
            posture = .closed
        } else if angle < 25.0 {
            posture = .slitPeek
        } else if angle < 100.0 {
            posture = .partiallyOpen
        } else {
            posture = .fullyOpen
        }
        continuation.yield(
            HingeSample(
                angleDegrees: angle,
                discretePosture: posture,
                isSynthetic: true,
                timestamp: timestamp
            )
        )
    }
}

/// 3. AccessibilityHingeProvider — для игроков, которым трудно физически открывать телефон:
/// крупный экранный ползунок и кнопки быстрых ступеней («Закрыть», «Щёлочка 1/2/3», «Вскрыть», «Открыть»).
public final class AccessibilityHingeProvider: HingeProviding, @unchecked Sendable {
    private let innerProvider: SimulatedHingeProvider
    public var samples: AsyncStream<HingeSample> { innerProvider.samples }

    public init(initialAngle: Double = 120.0) {
        self.innerProvider = SimulatedHingeProvider(initialAngle: initialAngle)
    }

    public func setAccessibleAngle(_ angle: Double) {
        innerProvider.setAngle(angle)
    }
}
