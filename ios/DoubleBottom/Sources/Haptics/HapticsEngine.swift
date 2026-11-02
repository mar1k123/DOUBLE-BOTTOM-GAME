import Foundation
#if canImport(CoreHaptics)
import CoreHaptics
#endif

/// Тактильный движок на `Core Haptics` (раздел 8.5):
/// 1. Закрытие чемодана в `SEALED` (`<= 3°` на 250 мс) — двойной металлический щелчок латунного замка.
/// 2. Приоткрытие щели (`3°–25°`) — нарастающие тики натяжения пружины каждые `5°`.
/// 3. Пересечение порога коммита (`>= 25°`) — резкий «срыв пломбы» и тяжёлый удар крышки.
/// 4. Удар штампа по паспорту — глухой низкочастотный удар с коротким послезвучием.
/// 5. Допрос на внешнем экране — приглушённый двойной импульс «пульса» (`60–90 BPM`) при пике «Нервомера».
@MainActor
public final class HapticsEngine {
    public var isEnabled: Bool = true
    private var lastSlitTickBucket: Int = -1

    #if canImport(CoreHaptics)
    private var engine: CHHapticEngine?
    #endif

    public init() {
        prepareHapticsIfSupported()
    }

    public func prepareHapticsIfSupported() {
        #if canImport(CoreHaptics)
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            engine = nil
        }
        #endif
    }

    /// 1. Двойной металлический щелчок латунного замка при опечатывании чемодана (`SEALED`).
    public func playSuitcaseSealLatch() {
        playTransientPair(
            firstIntensity: 0.85,
            firstSharpness: 0.90,
            secondDelay: 0.065,
            secondIntensity: 1.0,
            secondSharpness: 0.95
        )
    }

    /// 2. Тики натяжения пружины каждые 5° в диапазоне щели `3°–25°`.
    public func updateSlitAngle(_ angleDegrees: Double) {
        guard angleDegrees > 3.0, angleDegrees < 25.0 else {
            lastSlitTickBucket = -1
            return
        }
        let bucket = Int(angleDegrees / 5.0)
        guard bucket != lastSlitTickBucket else { return }
        lastSlitTickBucket = bucket

        let normalized = Float((angleDegrees - 3.0) / 22.0)
        playSingleTransient(
            intensity: 0.35 + 0.55 * normalized,
            sharpness: 0.50 + 0.40 * normalized
        )
    }

    /// 3. Резкий «срыв пломбы» и тяжёлый удар крышки при пересечении порога коммита (`>= 25°`).
    public func playCommitSealBreakSnap() {
        playTransientPair(
            firstIntensity: 1.0,
            firstSharpness: 1.0,
            secondDelay: 0.09,
            secondIntensity: 0.95,
            secondSharpness: 0.20
        )
    }

    /// 4. Глухой низкочастотный удар штампа КПП по паспорту.
    public func playPassportStampThud() {
        playTransientPair(
            firstIntensity: 1.0,
            firstSharpness: 0.15,
            secondDelay: 0.05,
            secondIntensity: 0.45,
            secondSharpness: 0.10
        )
    }

    /// 5. Приглушённый двойной импульс «пульса» (lub-dub) при высоком значении «Нервомера».
    public func playNervometerHeartbeatPulse() {
        playTransientPair(
            firstIntensity: 0.55,
            firstSharpness: 0.20,
            secondDelay: 0.18,
            secondIntensity: 0.40,
            secondSharpness: 0.15
        )
    }

    private func playSingleTransient(intensity: Float, sharpness: Float) {
        guard isEnabled else { return }
        #if canImport(CoreHaptics)
        guard let engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        if let pattern = try? CHHapticPattern(events: [event], parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
        #endif
    }

    private func playTransientPair(
        firstIntensity: Float,
        firstSharpness: Float,
        secondDelay: TimeInterval,
        secondIntensity: Float,
        secondSharpness: Float
    ) {
        guard isEnabled else { return }
        #if canImport(CoreHaptics)
        guard let engine else { return }
        let e1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: firstIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: firstSharpness)
            ],
            relativeTime: 0
        )
        let e2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: secondIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: secondSharpness)
            ],
            relativeTime: secondDelay
        )
        if let pattern = try? CHHapticPattern(events: [e1, e2], parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
        #endif
    }
}
