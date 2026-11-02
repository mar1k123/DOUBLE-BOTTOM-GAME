import Foundation

/// Селектор пикового эмоционального кадра (раздел 7.2).
/// Выбирает по 1 лучшему кадру для Контрабандиста и Инспектора из окна `[t_commit - 1.5s, t_commit + 3.0s]`
/// по максимуму выразительности мимики (отклонение бровей, глаз и рта от нейтрали) с штрафом за смаз движения головы.
public struct EmotionPeakSelector {
    public init() {}

    /// Вычисляет индекс эмоциональной выразительности кадра (чем выше, тем ярче эмоция и меньше смаз).
    public static func expressivenessScore(
        for sample: FacialLandmarkSample,
        baseline: BaselineProfile = .neutralDefault
    ) -> Double {
        let (nervScore, meanZ) = NervometerModel.computeUnfilteredScore(
            featureVector: sample.featureVector,
            baseline: baseline
        )
        // Поощряем широкое открытие глаз/рта или улыбку, но штрафуем за сильный поворот головы (motion blur)
        let mouthBonus = abs(sample.mouthCornerLift) * 120.0 + sample.mouthAspectRatio * 45.0
        let eyeBonus = abs(sample.eyeAspectRatio - 0.28) * 80.0
        let blurPenalty = max(0.0, sample.headPoseDelta - 0.22) * 65.0

        return nervScore + meanZ * 10.0 + mouthBonus + eyeBonus - blurPenalty
    }

    /// Возвращает лучший кадр для указанной роли из кольцевого буфера.
    public static func selectBestFrame(
        from buffer: FrameRingBuffer,
        for role: ProtocolSubjectRole,
        baseline: BaselineProfile = .neutralDefault
    ) -> BufferedProtocolFrame? {
        let candidates = buffer.allCandidateFrames(for: role)
        guard !candidates.isEmpty else { return nil }

        return candidates.max { lhs, rhs in
            expressivenessScore(for: lhs.landmarkSample, baseline: baseline)
                < expressivenessScore(for: rhs.landmarkSample, baseline: baseline)
        }
    }
}
