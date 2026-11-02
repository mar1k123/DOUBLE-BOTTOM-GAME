import XCTest
@testable import DoubleBottom

final class NervometerTests: XCTestCase {
    func testCalibrationAndZeroDeviationScore() {
        let calibrator = FaceBaselineCalibrator()
        for i in 0..<18 {
            let delta = (i % 2 == 0) ? 0.01 : -0.01
            calibrator.appendSample(
                FacialLandmarkSample(
                    timestamp: Double(i) * 0.33,
                    eyeAspectRatio: 0.28 + delta,
                    mouthCornerLift: 0.00 + delta * 0.5,
                    mouthAspectRatio: 0.14 + delta,
                    browToEyeDistance: 0.12 + delta,
                    headPoseDelta: 0.05 + delta,
                    gazeOffsetProxy: 0.02 + delta * 0.5
                )
            )
        }

        let profile = calibrator.finalizeProfile()
        XCTAssertEqual(profile.sampleCount, 18)

        // Кадр, в точности совпадающий со средним значением калибровки, должен давать 50.0 до шума.
        let exactMeanSample = FacialLandmarkSample(
            timestamp: 7.0,
            eyeAspectRatio: profile.featureMeans[0],
            mouthCornerLift: profile.featureMeans[1],
            mouthAspectRatio: profile.featureMeans[2],
            browToEyeDistance: profile.featureMeans[3],
            headPoseDelta: profile.featureMeans[4],
            gazeOffsetProxy: profile.featureMeans[5]
        )

        let (unfilteredScore, meanZ) = NervometerModel.computeUnfilteredScore(
            featureVector: exactMeanSample.featureVector,
            baseline: profile
        )
        XCTAssertEqual(meanZ, 0.0, accuracy: 0.0001)
        XCTAssertEqual(unfilteredScore, 50.0, accuracy: 0.0001)
    }

    func testHighFacialDeviationRaisesNervometerScoreAndClampsTo100() {
        let model = NervometerModel(baseline: .neutralDefault)
        let agitatedSample = FacialLandmarkSample(
            timestamp: 10.0,
            eyeAspectRatio: 0.48,     // сильное расширение глаз
            mouthCornerLift: 0.09,    // нервная ухмылка
            mouthAspectRatio: 0.32,   // приоткрытый рот
            browToEyeDistance: 0.22,  // поднятые брови
            headPoseDelta: 0.30,      // наклон головы
            gazeOffsetProxy: 0.09     // бегающий взгляд
        )

        let reading = model.processSample(agitatedSample, injectedNoiseOffset: 0.0)
        XCTAssertGreaterThan(reading.rawScore, 80.0)
        XCTAssertLessThanOrEqual(reading.rawScore, 100.0)
        XCTAssertGreaterThan(reading.smoothedScore, 55.0)
        XCTAssertEqual(reading.confidenceHigh - reading.confidenceLow, 16.0, accuracy: 0.1)
    }

    func testTremorFallbackCalculatesBoundedScore() {
        let tremor = TremorModel()
        let calmReading = tremor.updateFromMotionSample(
            userAccelerationX: 0.004,
            userAccelerationY: 0.004,
            userAccelerationZ: 0.004,
            rotationRateMagnitude: 0.03,
            injectedNoiseOffset: 0.0
        )
        XCTAssertEqual(calmReading.rawScore, 50.0, accuracy: 0.5)

        let shakyReading = tremor.updateFromMotionSample(
            userAccelerationX: 0.12,
            userAccelerationY: 0.09,
            userAccelerationZ: 0.11,
            rotationRateMagnitude: 0.65,
            injectedNoiseOffset: 0.0
        )
        XCTAssertGreaterThan(shakyReading.rawScore, 75.0)
        XCTAssertLessThanOrEqual(shakyReading.rawScore, 100.0)
    }
}
