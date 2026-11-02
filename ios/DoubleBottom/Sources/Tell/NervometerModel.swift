import Foundation

/// Выходной снимок прибора «Нервомер-64» (раздел 6.3).
public struct NervometerReading: Equatable, Sendable {
    public let rawScore: Double
    public let smoothedScore: Double
    public let confidenceLow: Double
    public let confidenceHigh: Double
    public let meanZScore: Double
    public let modeLabelRu: String

    public init(
        rawScore: Double,
        smoothedScore: Double,
        confidenceLow: Double,
        confidenceHigh: Double,
        meanZScore: Double,
        modeLabelRu: String
    ) {
        self.rawScore = rawScore
        self.smoothedScore = smoothedScore
        self.confidenceLow = confidenceLow
        self.confidenceHigh = confidenceHigh
        self.meanZScore = meanZScore
        self.modeLabelRu = modeLabelRu
    }
}

/// Математическая модель «Нервомера» (раздел 6.3):
/// 1. Для каждого признака $i$ вычисляется $|z_i| = |x_i - \mu_i| / \sigma_i$.
/// 2. Базовый индекс: $N = \text{clamp}(50 + k \cdot \text{mean}(|z_i|), 0, 100)$.
/// 3. Сглаживание экспоненциальным скользящим средним (EMA с коэффициентом $\alpha = 0.22$).
/// 4. Игровой шум $\pm 8$ пунктов и доверительный интервал (полоса неопределённости),
///    чтобы прибор оставался генератором поводов для обвинений, а не абсолютным детектором лжи.
public final class NervometerModel {
    public private(set) var baseline: BaselineProfile
    public private(set) var currentSmoothedScore: Double = Tuning.nervometerBaseScore
    public let sensitivityK: Double
    public let emaAlpha: Double
    public let noiseAmplitude: Double

    public init(
        baseline: BaselineProfile = .neutralDefault,
        sensitivityK: Double = Tuning.nervometerSensitivityK,
        emaAlpha: Double = Tuning.nervometerEMAAlpha,
        noiseAmplitude: Double = Tuning.nervometerNoiseAmplitude
    ) {
        self.baseline = baseline
        self.sensitivityK = sensitivityK
        self.emaAlpha = emaAlpha
        self.noiseAmplitude = noiseAmplitude
    }

    public func updateBaseline(_ newBaseline: BaselineProfile) {
        self.baseline = newBaseline
        self.currentSmoothedScore = Tuning.nervometerBaseScore
    }

    /// Чистая детерминированная формула расчёта z-отклонения и индекса $N$ до шума.
    public static func computeUnfilteredScore(
        featureVector: [Double],
        baseline: BaselineProfile,
        sensitivityK: Double = Tuning.nervometerSensitivityK
    ) -> (score: Double, meanAbsZ: Double) {
        let count = min(featureVector.count, min(baseline.featureMeans.count, baseline.featureStdDevs.count))
        guard count > 0 else {
            return (Tuning.nervometerBaseScore, 0.0)
        }

        var zSum = 0.0
        for i in 0..<count {
            let sigma = max(0.0001, baseline.featureStdDevs[i])
            let z = abs(featureVector[i] - baseline.featureMeans[i]) / sigma
            // Ограничиваем одиночный выброс z <= 6.0, чтобы случайный чих не уводил шкалу в 100 навсегда
            zSum += min(6.0, z)
        }

        let meanZ = zSum / Double(count)
        let raw = min(100.0, max(0.0, Tuning.nervometerBaseScore + sensitivityK * meanZ))
        return (raw, meanZ)
    }

    /// Обновляет показание прибора по новому кадру `FacialLandmarkSample` с EMA-сглаживанием и игровым шумом `±8`.
    public func processSample(
        _ sample: FacialLandmarkSample,
        injectedNoiseOffset: Double? = nil
    ) -> NervometerReading {
        let (unfiltered, meanZ) = Self.computeUnfilteredScore(
            featureVector: sample.featureVector,
            baseline: baseline,
            sensitivityK: sensitivityK
        )

        let noise = injectedNoiseOffset ?? Double.random(in: -noiseAmplitude...noiseAmplitude)
        let noisyTarget = min(100.0, max(0.0, unfiltered + noise))

        currentSmoothedScore = emaAlpha * noisyTarget + (1.0 - emaAlpha) * currentSmoothedScore
        let clampedSmoothed = min(100.0, max(0.0, currentSmoothedScore))

        let low = max(0.0, clampedSmoothed - noiseAmplitude)
        let high = min(100.0, clampedSmoothed + noiseAmplitude)

        return NervometerReading(
            rawScore: unfiltered,
            smoothedScore: clampedSmoothed,
            confidenceLow: low,
            confidenceHigh: high,
            meanZScore: meanZ,
            modeLabelRu: "Камера (Vision RGB)"
        )
    }
}
