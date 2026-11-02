import Foundation
import CoreGraphics

/// Роль игрока, к которому относится захваченный кадр для «Протокола вскрытия».
public enum ProtocolSubjectRole: String, Sendable, Equatable {
    case smuggler
    case inspector
}

/// Один буферизованный кадр в оперативной памяти (раздел 7.2).
/// Никогда не записывается во временные файлы на диск; очищается сразу после завершения матча.
public struct BufferedProtocolFrame: Sendable {
    public let id: UUID
    public let role: ProtocolSubjectRole
    public let timestamp: TimeInterval
    public let landmarkSample: FacialLandmarkSample
    public let cgImage: CGImage?

    public init(
        id: UUID = UUID(),
        role: ProtocolSubjectRole,
        timestamp: TimeInterval,
        landmarkSample: FacialLandmarkSample,
        cgImage: CGImage? = nil
    ) {
        self.id = id
        self.role = role
        self.timestamp = timestamp
        self.landmarkSample = landmarkSample
        self.cgImage = cgImage
    }
}

/// Кольцевой буфер кадров в оперативной памяти (раздел 7.2):
/// Хранит последние `1.5 с` (`Tuning.protocolPreCommitBufferSec`) до момента коммита вскрытия (`>= 25°`)
/// и собирает кадры ещё `3.0 с` (`Tuning.protocolPostCommitWindowSec`) после коммита.
/// При отсутствии `AVCaptureMultiCamSession` поддерживает последовательный захват:
/// `0.0–1.5 с` после коммита — реакция Контрабандиста, `1.5–3.0 с` — реакция Инспектора.
public final class FrameRingBuffer {
    public let preCommitDurationSec: TimeInterval
    public let postCommitDurationSec: TimeInterval

    private var preCommitSmugglerFrames: [BufferedProtocolFrame] = []
    private var preCommitInspectorFrames: [BufferedProtocolFrame] = []
    private var postCommitSmugglerFrames: [BufferedProtocolFrame] = []
    private var postCommitInspectorFrames: [BufferedProtocolFrame] = []

    public private(set) var commitTimestamp: TimeInterval?

    public init(
        preCommitDurationSec: TimeInterval = Tuning.protocolPreCommitBufferSec,
        postCommitDurationSec: TimeInterval = Tuning.protocolPostCommitWindowSec
    ) {
        self.preCommitDurationSec = preCommitDurationSec
        self.postCommitDurationSec = postCommitDurationSec
    }

    /// Полная очистка буфера из оперативной памяти.
    public func purgeAllFramesFromRAM() {
        preCommitSmugglerFrames.removeAll()
        preCommitInspectorFrames.removeAll()
        postCommitSmugglerFrames.removeAll()
        postCommitInspectorFrames.removeAll()
        commitTimestamp = nil
    }

    /// Добавляет кадр в кольцевой буфер (до или после коммита вскрытия).
    public func appendFrame(_ frame: BufferedProtocolFrame) {
        if let commitTime = commitTimestamp {
            let elapsedAfterCommit = frame.timestamp - commitTime
            guard elapsedAfterCommit >= 0, elapsedAfterCommit <= postCommitDurationSec else {
                return
            }
            switch frame.role {
            case .smuggler:
                postCommitSmugglerFrames.append(frame)
            case .inspector:
                postCommitInspectorFrames.append(frame)
            }
        } else {
            let cutoff = frame.timestamp - preCommitDurationSec
            switch frame.role {
            case .smuggler:
                preCommitSmugglerFrames.append(frame)
                preCommitSmugglerFrames.removeAll { $0.timestamp < cutoff }
            case .inspector:
                preCommitInspectorFrames.append(frame)
                preCommitInspectorFrames.removeAll { $0.timestamp < cutoff }
            }
        }
    }

    /// Последовательный фоллбэк для одной активной камеры (когда `AVCaptureMultiCamSession` недоступна):
    /// Первые `1.5 с` после коммита кадр приписывается Контрабандисту, следующие `1.5 с` — Инспектору.
    public func appendSingleCameraSequentialFrame(
        timestamp: TimeInterval,
        landmarkSample: FacialLandmarkSample,
        cgImage: CGImage? = nil
    ) {
        let assignedRole: ProtocolSubjectRole
        if let commitTime = commitTimestamp {
            let delta = timestamp - commitTime
            assignedRole = (delta < postCommitDurationSec * 0.5) ? .smuggler : .inspector
        } else {
            assignedRole = .smuggler
        }
        let frame = BufferedProtocolFrame(
            role: assignedRole,
            timestamp: timestamp,
            landmarkSample: landmarkSample,
            cgImage: cgImage
        )
        appendFrame(frame)
    }

    /// Фиксирует момент коммита вскрытия чемодана ($\theta \ge 25^\circ$).
    public func markCommit(at timestamp: TimeInterval) {
        guard commitTimestamp == nil else { return }
        commitTimestamp = timestamp
        let cutoff = timestamp - preCommitDurationSec
        preCommitSmugglerFrames.removeAll { $0.timestamp < cutoff }
        preCommitInspectorFrames.removeAll { $0.timestamp < cutoff }
    }

    public func allCandidateFrames(for role: ProtocolSubjectRole) -> [BufferedProtocolFrame] {
        switch role {
        case .smuggler:
            return preCommitSmugglerFrames + postCommitSmugglerFrames
        case .inspector:
            return preCommitInspectorFrames + postCommitInspectorFrames
        }
    }
}
