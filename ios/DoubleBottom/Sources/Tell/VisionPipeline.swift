import Foundation
import CoreGraphics
#if canImport(Vision)
import Vision
import CoreVideo
#endif

/// Набор геометрических лицевых признаков одного кадра (раздел 6.2).
/// Вычисляется исключительно из 2D-точек `VNDetectFaceLandmarksRequest` в оперативной памяти;
/// никакие биометрические шаблоны или фотографии не сохраняются на диск.
public struct FacialLandmarkSample: Equatable, Sendable {
    public let timestamp: TimeInterval
    /// Отношение раскрытия глаз (Eye Aspect Ratio, EAR) — детекция морганий и прищура.
    public let eyeAspectRatio: Double
    /// Подъём уголков губ относительно центра рта (асимметрия/нервная ухмылка).
    public let mouthCornerLift: Double
    /// Отношение раскрытия рта (Mouth Aspect Ratio, MAR) — сжатые губы или вздох.
    public let mouthAspectRatio: Double
    /// Нормированное расстояние «бровь — верхнее веко».
    public let browToEyeDistance: Double
    /// Суммарная угловая дельта поворота/наклона головы (`|yaw| + |pitch| + |roll|`, рад).
    public let headPoseDelta: Double
    /// Смещение зрачка относительно центра контура глаза (proxy бегающего взгляда).
    public let gazeOffsetProxy: Double

    public init(
        timestamp: TimeInterval,
        eyeAspectRatio: Double,
        mouthCornerLift: Double,
        mouthAspectRatio: Double,
        browToEyeDistance: Double,
        headPoseDelta: Double,
        gazeOffsetProxy: Double
    ) {
        self.timestamp = timestamp
        self.eyeAspectRatio = eyeAspectRatio
        self.mouthCornerLift = mouthCornerLift
        self.mouthAspectRatio = mouthAspectRatio
        self.browToEyeDistance = browToEyeDistance
        self.headPoseDelta = headPoseDelta
        self.gazeOffsetProxy = gazeOffsetProxy
    }

    /// Вектор из 6 численных признаков для расчёта z-отклонений от индивидуальной калибровки.
    public var featureVector: [Double] {
        [
            eyeAspectRatio,
            mouthCornerLift,
            mouthAspectRatio,
            browToEyeDistance,
            headPoseDelta,
            gazeOffsetProxy
        ]
    }
}

/// Конвейер компьютерного зрения `Vision` на фоновой очереди (12–15 FPS).
public final class VisionPipeline: Sendable {
    public init() {}

    #if canImport(Vision)
    public func extractLandmarks(from pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> FacialLandmarkSample? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            guard let face = request.results?.first,
                  let landmarks = face.landmarks else {
                return nil
            }
            return Self.computeSample(face: face, landmarks: landmarks, timestamp: timestamp)
        } catch {
            return nil
        }
    }

    private static func computeSample(
        face: VNFaceObservation,
        landmarks: VNFaceLandmarks2D,
        timestamp: TimeInterval
    ) -> FacialLandmarkSample {
        let leftEAR = aspectRatio(of: landmarks.leftEye?.normalizedPoints ?? [])
        let rightEAR = aspectRatio(of: landmarks.rightEye?.normalizedPoints ?? [])
        let ear = (leftEAR + rightEAR) * 0.5

        let outerLips = landmarks.outerLips?.normalizedPoints ?? []
        let mar = aspectRatio(of: outerLips)
        let mouthLift = computeMouthCornerLift(points: outerLips)

        let browDist = computeBrowToEyeDistance(
            brow: landmarks.leftEyebrow?.normalizedPoints ?? [],
            eye: landmarks.leftEye?.normalizedPoints ?? []
        )

        let yaw = abs(face.yaw?.doubleValue ?? 0.0)
        let pitch = abs(face.pitch?.doubleValue ?? 0.0)
        let roll = abs(face.roll?.doubleValue ?? 0.0)
        let headPose = yaw + pitch + roll

        let gazeProxy = computeGazeOffset(
            pupil: landmarks.leftPupil?.normalizedPoints ?? [],
            eye: landmarks.leftEye?.normalizedPoints ?? []
        )

        return FacialLandmarkSample(
            timestamp: timestamp,
            eyeAspectRatio: ear,
            mouthCornerLift: mouthLift,
            mouthAspectRatio: mar,
            browToEyeDistance: browDist,
            headPoseDelta: headPose,
            gazeOffsetProxy: gazeProxy
        )
    }
    #endif

    public static func aspectRatio(of points: [CGPoint]) -> Double {
        guard points.count >= 4 else { return 0.28 }
        let xs = points.map { Double($0.x) }
        let ys = points.map { Double($0.y) }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else {
            return 0.28
        }
        let width = max(0.001, maxX - minX)
        let height = max(0.0, maxY - minY)
        return height / width
    }

    public static func computeMouthCornerLift(points: [CGPoint]) -> Double {
        guard points.count >= 4 else { return 0.0 }
        let sortedByX = points.sorted { $0.x < $1.x }
        guard let leftCorner = sortedByX.first, let rightCorner = sortedByX.last else { return 0.0 }
        let centerY = points.map { Double($0.y) }.reduce(0.0, +) / Double(points.count)
        let cornerMeanY = (Double(leftCorner.y) + Double(rightCorner.y)) * 0.5
        return cornerMeanY - centerY
    }

    public static func computeBrowToEyeDistance(brow: [CGPoint], eye: [CGPoint]) -> Double {
        guard !brow.isEmpty, !eye.isEmpty else { return 0.12 }
        let browY = brow.map { Double($0.y) }.reduce(0.0, +) / Double(brow.count)
        let eyeY = eye.map { Double($0.y) }.reduce(0.0, +) / Double(eye.count)
        return abs(browY - eyeY)
    }

    public static func computeGazeOffset(pupil: [CGPoint], eye: [CGPoint]) -> Double {
        guard let p = pupil.first, !eye.isEmpty else { return 0.0 }
        let eyeCenterX = eye.map { Double($0.x) }.reduce(0.0, +) / Double(eye.count)
        let eyeCenterY = eye.map { Double($0.y) }.reduce(0.0, +) / Double(eye.count)
        let dx = Double(p.x) - eyeCenterX
        let dy = Double(p.y) - eyeCenterY
        return (dx * dx + dy * dy).squareRoot()
    }
}
