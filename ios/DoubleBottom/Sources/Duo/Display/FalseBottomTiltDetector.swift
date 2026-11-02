import Foundation
import Combine
#if canImport(CoreMotion)
import CoreMotion
#endif

/// Протокол детектора гироскопического покачивания для поиска «Двойного дна» (раздел 4.2 и 5.3).
/// Чтобы обнаружить предмет в скрытом слоте во время COMMITTED вскрытия, инспектор должен
/// в течение 6 секунд плавно наклонить раскрытый телефон влево-вправо (2 качка >= 25°).
@MainActor
public protocol FalseBottomTiltDetecting: ObservableObject {
    var completedSwings: Int { get }
    var currentRollDegrees: Double { get }
    var remainingSeconds: Double { get }
    var isFound: Bool { get }
    var isActive: Bool { get }

    func startSearchWindow()
    func stopSearchWindow()
    func simulateManualSwing()
}

@MainActor
public final class FalseBottomTiltDetector: FalseBottomTiltDetecting {
    @Published public private(set) var completedSwings: Int = 0
    @Published public private(set) var currentRollDegrees: Double = 0.0
    @Published public private(set) var remainingSeconds: Double = Tuning.falseBottomTiltWindowSec
    @Published public private(set) var isFound: Bool = false
    @Published public private(set) var isActive: Bool = false

    private var timer: Timer?
    private var lastPeakDirection: Int = 0 // -1 (влево), +1 (вправо), 0 (центр)
    private var startTimestamp: Date?

    #if canImport(CoreMotion)
    private let motionManager = CMMotionManager()
    #endif

    public init() {}

    public func startSearchWindow() {
        stopSearchWindow()
        completedSwings = 0
        currentRollDegrees = 0.0
        remainingSeconds = Tuning.falseBottomTiltWindowSec
        isFound = false
        isActive = true
        lastPeakDirection = 0
        startTimestamp = Date()

        #if canImport(CoreMotion)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self, let motion else { return }
                let rollDeg = motion.attitude.roll * 180.0 / .pi
                Task { @MainActor in
                    self.processRollAngle(rollDeg)
                }
            }
        }
        #endif

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickTimer()
            }
        }
    }

    public func stopSearchWindow() {
        isActive = false
        timer?.invalidate()
        timer = nil
        #if canImport(CoreMotion)
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        #endif
    }

    public func simulateManualSwing() {
        guard isActive, !isFound else { return }
        let nextDir = (lastPeakDirection <= 0) ? 1 : -1
        let simulatedAngle = Double(nextDir) * (Tuning.falseBottomTiltRequiredAngleDeg + 4.0)
        processRollAngle(simulatedAngle)
    }

    public func processRollAngle(_ rollDegrees: Double) {
        guard isActive, !isFound else { return }
        currentRollDegrees = rollDegrees

        let threshold = Tuning.falseBottomTiltRequiredAngleDeg
        if rollDegrees >= threshold && lastPeakDirection != 1 {
            lastPeakDirection = 1
            registerSwing()
        } else if rollDegrees <= -threshold && lastPeakDirection != -1 {
            lastPeakDirection = -1
            registerSwing()
        }
    }

    private func registerSwing() {
        completedSwings += 1
        if completedSwings >= Tuning.falseBottomRequiredSwings {
            isFound = true
            stopSearchWindow()
        }
    }

    private func tickTimer() {
        guard isActive, let start = startTimestamp else { return }
        let elapsed = Date().timeIntervalSince(start)
        let left = max(0.0, Tuning.falseBottomTiltWindowSec - elapsed)
        remainingSeconds = left
        if left <= 0.0 {
            stopSearchWindow()
        }
    }
}
