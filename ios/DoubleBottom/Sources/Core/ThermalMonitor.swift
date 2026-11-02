import Foundation
import Combine

/// Уровень деградации подсистем при нагреве iPhone Duo (раздел 9.2).
public enum ThermalProtectionMode: String, Sendable, Equatable {
    /// Нормальный режим (`.nominal`): Vision 14 FPS, рейтрейсинг включён.
    case normal
    /// Умеренный нагрев (`.fair`): Vision снижается до 9 FPS, рейтрейсинг отключается.
    case throttledFair
    /// Сильный нагрев (`.serious` / `.critical`): Vision и камера полностью выключаются,
    /// «Нервомер» автоматически переходит в режим «Тремор рук» (`CoreMotion`).
    case fallbackTremorOnly
}

/// Монитор теплового состояния `ProcessInfo.processInfo.thermalState` (раздел 9.2).
/// Защищает складываемый корпус iPhone Duo от перегрева при одновременной работе двух экранов,
/// камеры, `Vision` и `Metal`.
@MainActor
public final class ThermalMonitor: ObservableObject {
    @Published public private(set) var protectionMode: ThermalProtectionMode = .normal
    @Published public private(set) var targetVisionFPS: Int = Tuning.nervometerTargetFPS
    @Published public private(set) var isRaytracingAllowed: Bool = true
    @Published public private(set) var forceTremorFallback: Bool = false

    private var notificationObserver: NSObjectProtocol?

    public init() {
        evaluateSystemThermalState(ProcessInfo.processInfo.thermalState)
        notificationObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateSystemThermalState(ProcessInfo.processInfo.thermalState)
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Применяет политику тепловой защиты для переданного `ProcessInfo.ThermalState`.
    public func evaluateSystemThermalState(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal:
            protectionMode = .normal
            targetVisionFPS = Tuning.nervometerTargetFPS
            isRaytracingAllowed = true
            forceTremorFallback = false

        case .fair:
            protectionMode = .throttledFair
            targetVisionFPS = Tuning.nervometerFairThermalFPS
            isRaytracingAllowed = false
            forceTremorFallback = false

        case .serious, .critical:
            protectionMode = .fallbackTremorOnly
            targetVisionFPS = 0
            isRaytracingAllowed = false
            forceTremorFallback = true

        @unknown default:
            protectionMode = .throttledFair
            targetVisionFPS = Tuning.nervometerFairThermalFPS
            isRaytracingAllowed = false
            forceTremorFallback = false
        }
    }
}
