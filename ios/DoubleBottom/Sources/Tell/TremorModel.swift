import Foundation
#if canImport(CoreMotion)
import CoreMotion
#endif

/// Режим «Тремор рук» (раздел 6.4):
/// Когда камера выключена игроком, закрыта пальцем, не имеет разрешения или отключена из-за перегрева
/// (`ProcessInfo.thermalState >= .serious`), «Нервомер» автоматически переключается на анализ
/// микроколебаний корпуса через акселерометр и гироскоп (`CoreMotion`) в момент передачи устройства
/// и удержания его на весу.
public final class TremorModel {
    private var smoothedScore: Double = Tuning.nervometerBaseScore
    private let emaAlpha: Double
    private let noiseAmplitude: Double

    #if canImport(CoreMotion)
    private let motionManager = CMMotionManager()
    #endif

    public init(
        emaAlpha: Double = Tuning.nervometerEMAAlpha,
        noiseAmplitude: Double = Tuning.nervometerNoiseAmplitude
    ) {
        self.emaAlpha = emaAlpha
        self.noiseAmplitude = noiseAmplitude
    }

    /// Чистая функция расчёта индекса тремора по вектору линейного ускорения пользователя `userAcceleration` (в единицах `g`)
    /// и угловой скорости вращения `rotationRate` (в `рад/с`).
    public static func computeTremorScore(
        userAccelerationX: Double,
        userAccelerationY: Double,
        userAccelerationZ: Double,
        rotationRateMagnitude: Double
    ) -> Double {
        let accelMag = (
            userAccelerationX * userAccelerationX +
            userAccelerationY * userAccelerationY +
            userAccelerationZ * userAccelerationZ
        ).squareRoot()

        // Спокойная рука на весу даёт ~0.015g и ~0.08 рад/с.
        let normalizedJitter = max(0.0, (accelMag - 0.012) * 18.0 + max(0.0, rotationRateMagnitude - 0.06) * 4.5)
        let score = Tuning.nervometerBaseScore + Tuning.nervometerSensitivityK * normalizedJitter
        return min(100.0, max(0.0, score))
    }

    public func updateFromMotionSample(
        userAccelerationX: Double,
        userAccelerationY: Double,
        userAccelerationZ: Double,
        rotationRateMagnitude: Double,
        injectedNoiseOffset: Double? = nil
    ) -> NervometerReading {
        let raw = Self.computeTremorScore(
            userAccelerationX: userAccelerationX,
            userAccelerationY: userAccelerationY,
            userAccelerationZ: userAccelerationZ,
            rotationRateMagnitude: rotationRateMagnitude
        )
        let noise = injectedNoiseOffset ?? Double.random(in: -noiseAmplitude...noiseAmplitude)
        let target = min(100.0, max(0.0, raw + noise))
        smoothedScore = emaAlpha * target + (1.0 - emaAlpha) * smoothedScore

        let clamped = min(100.0, max(0.0, smoothedScore))
        return NervometerReading(
            rawScore: raw,
            smoothedScore: clamped,
            confidenceLow: max(0.0, clamped - noiseAmplitude),
            confidenceHigh: min(100.0, clamped + noiseAmplitude),
            meanZScore: (raw - Tuning.nervometerBaseScore) / max(1.0, Tuning.nervometerSensitivityK),
            modeLabelRu: "Тремор рук (CoreMotion)"
        )
    }
}
