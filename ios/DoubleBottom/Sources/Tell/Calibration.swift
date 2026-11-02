import Foundation

/// Индивидуальный базовый профиль «каменного лица» игрока (раздел 6.3).
/// Хранится ТОЛЬКО в оперативной памяти на время текущего матча и уничтожается при выходе.
public struct BaselineProfile: Equatable, Sendable {
    public let featureMeans: [Double]
    public let featureStdDevs: [Double]
    public let sampleCount: Int

    public init(featureMeans: [Double], featureStdDevs: [Double], sampleCount: Int) {
        self.featureMeans = featureMeans
        self.featureStdDevs = featureStdDevs
        self.sampleCount = sampleCount
    }

    /// Дефолтный профиль на случай пропуска калибровки.
    public static let neutralDefault = BaselineProfile(
        featureMeans: [0.28, 0.00, 0.14, 0.12, 0.05, 0.02],
        featureStdDevs: [0.04, 0.02, 0.03, 0.02, 0.04, 0.015],
        sampleCount: 1
    )
}

/// Калибратор 6-секундного окна «Каменное лицо: смотрите спокойно на штамп КПП» перед началом раунда.
public final class FaceBaselineCalibrator {
    private var collectedSamples: [FacialLandmarkSample] = []
    private let minimumStdDevFloor: Double = 0.008

    public init() {}

    public func reset() {
        collectedSamples.removeAll()
    }

    public func appendSample(_ sample: FacialLandmarkSample) {
        collectedSamples.append(sample)
    }

    public var count: Int {
        collectedSamples.count
    }

    /// Строит индивидуальный `BaselineProfile` ($\mu_i, \sigma_i$) по накопленным за 6 секунд кадрам.
    public func finalizeProfile() -> BaselineProfile {
        guard !collectedSamples.isEmpty else {
            return .neutralDefault
        }

        let dimension = collectedSamples[0].featureVector.count
        let n = Double(collectedSamples.count)
        var means = Array(repeating: 0.0, count: dimension)
        var stds = Array(repeating: minimumStdDevFloor, count: dimension)

        for sample in collectedSamples {
            let vec = sample.featureVector
            for i in 0..<dimension {
                means[i] += vec[i] / n
            }
        }

        if collectedSamples.count > 1 {
            for i in 0..<dimension {
                var varianceSum = 0.0
                for sample in collectedSamples {
                    let diff = sample.featureVector[i] - means[i]
                    varianceSum += diff * diff
                }
                let std = (varianceSum / Double(collectedSamples.count - 1)).squareRoot()
                stds[i] = max(minimumStdDevFloor, std)
            }
        }

        return BaselineProfile(
            featureMeans: means,
            featureStdDevs: stds,
            sampleCount: collectedSamples.count
        )
    }
}
