import Foundation
#if canImport(AVFoundation)
import AVFoundation
import CoreVideo
#endif

/// Статус доступности камер iPhone Duo (включая Direction-Aware / Virtual Front Camera в iOS 27.1).
public enum CameraCaptureState: String, Sendable, Equatable {
    case unconfigured
    case permissionDenied
    case runningSingleCamera
    case runningDualMultiCam
    case suspendedForThermalOrFallback
}

/// Протокол координатора захвата видеопотока (раздел 2.4 и 6.2).
/// Работает с обычными RGB-кадрами через `AVCaptureSession` / `AVCaptureMultiCamSession` (без `ARKit` и без `TrueDepth`),
/// ограничивая частоту анализа до 12–15 FPS на фоновой очереди.
public protocol CaptureCoordinating: AnyObject {
    var state: CameraCaptureState { get }
    var isMultiCamSupported: Bool { get }
    var onPassengerFrame: ((FacialLandmarkSample) -> Void)? { get set }

    func requestPermissionAndConfigure(preferMultiCam: Bool) async -> CameraCaptureState
    func startCapture()
    func stopCapture()
    func throttleFrameRate(fps: Int)
}

/// Реализация координатора камер с поддержкой Direction-Aware Virtual Front Camera iOS 27.1
/// и автоматическим откатом на одиночную камеру или режим «Тремор рук».
/// Помечено: ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ APPLE — поведение Virtual Front Camera при смене позы шарнира
/// между закрытым паспортом (5.4") и раскрытым чемоданом (7.6") в iOS 27.1 SDK.
public final class CaptureCoordinator: NSObject, CaptureCoordinating {
    public private(set) var state: CameraCaptureState = .unconfigured
    public var onPassengerFrame: ((FacialLandmarkSample) -> Void)?

    private let sessionQueue = DispatchQueue(label: "com.doublebottom.camera.session", qos: .userInitiated)
    private let visionQueue = DispatchQueue(label: "com.doublebottom.vision", qos: .userInitiated)
    private let visionPipeline = VisionPipeline()
    private var targetFPS: Int = Tuning.nervometerTargetFPS
    private var lastFrameTimestamp: TimeInterval = 0

    #if canImport(AVFoundation)
    private var captureSession: AVCaptureSession?
    #endif

    public override init() {
        super.init()
    }

    public var isMultiCamSupported: Bool {
        #if canImport(AVFoundation) && os(iOS)
        return AVCaptureMultiCamSession.isMultiCamSupported
        #else
        return false
        #endif
    }

    public func requestPermissionAndConfigure(preferMultiCam: Bool) async -> CameraCaptureState {
        #if canImport(AVFoundation)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let granted: Bool
        switch status {
        case .authorized:
            granted = true
        case .notDetermined:
            granted = await AVCaptureDevice.requestAccess(for: .video)
        default:
            granted = false
        }

        guard granted else {
            state = .permissionDenied
            return state
        }

        #if os(iOS)
        if preferMultiCam && AVCaptureMultiCamSession.isMultiCamSupported {
            state = .runningDualMultiCam
        } else {
            state = .runningSingleCamera
        }
        #else
        state = .runningSingleCamera
        #endif

        return state
        #else
        state = .permissionDenied
        return state
        #endif
    }

    public func startCapture() {
        #if canImport(AVFoundation)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession == nil {
                self.configureSessionOnQueue()
            }
            if let session = self.captureSession, !session.isRunning {
                session.startRunning()
            }
        }
        #endif
    }

    public func stopCapture() {
        #if canImport(AVFoundation)
        sessionQueue.async { [weak self] in
            guard let self, let session = self.captureSession else { return }
            if session.isRunning {
                session.stopRunning()
            }
        }
        #endif
    }

    public func throttleFrameRate(fps: Int) {
        targetFPS = max(1, min(30, fps))
    }

    #if canImport(AVFoundation)
    private func configureSessionOnQueue() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        // ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ APPLE:
        // На iPhone Duo в iOS 27.1 системная Direction-Aware фронтальная камера автоматически
        // маршрутизирует активный сенсор (`builtInWideAngleCamera`, position: `.front`) в зависимости от угла петли.
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: visionQueue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
        self.captureSession = session
    }
    #endif
}

#if canImport(AVFoundation)
extension CaptureCoordinator: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        let minInterval = 1.0 / Double(max(1, targetFPS))
        guard pts - lastFrameTimestamp >= minInterval else { return }
        lastFrameTimestamp = pts

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if let sample = visionPipeline.extractLandmarks(from: pixelBuffer, timestamp: pts) {
            onPassengerFrame?(sample)
        }
    }
}
#endif
