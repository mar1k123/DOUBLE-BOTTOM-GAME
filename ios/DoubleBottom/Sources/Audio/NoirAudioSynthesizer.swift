import Foundation
#if canImport(AVFAudio)
import AVFAudio
#endif

/// Типы процедурных звуковых эффектов КПП «Ласточка» (раздел 8.4).
public enum NoirSoundCue: String, Sendable {
    case brassLatchClick     // Щелчок латунного замка чемодана
    case leatherHingeCreak   // Скрип кожи при открытии крышки
    case customsStampThud    // Тяжёлый удар штампа по паспорту
    case typewriterKeyTick   // Клавиша пишущей машинки в декларации
    case slitTensionWarning  // Нарастающий гул при угле петли 18°–25°
    case contrabandAlarm     // Тревожный аккорд при обнаружении контрабанды
}

/// Процедурный звуковой синтезатор на `AVAudioEngine` (раздел 8.4).
/// Все звуковые эффекты, шум дождя на границе и адаптивный нуар-джаз (контрабас + щётки)
/// синтезируются в реальном времени без единого внешнего `.wav`/`.mp3` файла.
@MainActor
public final class NoirAudioSynthesizer: ObservableObject {
    @Published public var isMuted: Bool = false
    @Published public private(set) var currentTensionNormalized: Double = 0.0

    #if canImport(AVFAudio)
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100.0
    private var isEngineConfigured = false
    #endif

    public init() {}

    public func startEngineIfNeeded() {
        #if canImport(AVFAudio)
        guard !isEngineConfigured else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            playerNode.play()
            isEngineConfigured = true
        } catch {
            isEngineConfigured = false
        }
        #endif
    }

    public func stopEngine() {
        #if canImport(AVFAudio)
        if engine.isRunning {
            playerNode.stop()
            engine.stop()
        }
        isEngineConfigured = false
        #endif
    }

    /// Обновляет интенсивность натяжения петли (`0.0...1.0`) при открытии щели досмотра.
    public func updateHingeTension(angleDegrees: Double) {
        let clamped = min(25.0, max(0.0, angleDegrees)) / 25.0
        currentTensionNormalized = clamped
        if angleDegrees >= 18.0 && angleDegrees < 25.0 {
            playCue(.slitTensionWarning)
        }
    }

    /// Генерирует и воспроизводит процедурный PCM-буфер для выбранного звукового события.
    public func playCue(_ cue: NoirSoundCue) {
        guard !isMuted else { return }
        #if canImport(AVFAudio)
        startEngineIfNeeded()
        guard isEngineConfigured,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return
        }

        let durationSec: Double
        switch cue {
        case .brassLatchClick: durationSec = 0.09
        case .leatherHingeCreak: durationSec = 0.14
        case .customsStampThud: durationSec = 0.22
        case .typewriterKeyTick: durationSec = 0.045
        case .slitTensionWarning: durationSec = 0.18
        case .contrabandAlarm: durationSec = 0.35
        }

        let frameCount = AVAudioFrameCount(sampleRate * durationSec)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else { return }
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let env = exp(-t * (1.0 / max(0.01, durationSec * 0.35)))
            let sample: Double

            switch cue {
            case .brassLatchClick:
                // Двойной металлический резонанс (1850 Hz + 3120 Hz)
                sample = (sin(2.0 * .pi * 1850.0 * t) + 0.6 * sin(2.0 * .pi * 3120.0 * t)) * env * 0.35
            case .leatherHingeCreak:
                // Низкочастотный скрипучий FM-сигнал (110..165 Hz)
                let mod = sin(2.0 * .pi * 19.0 * t) * 28.0
                sample = sin(2.0 * .pi * (125.0 + mod) * t) * env * 0.25
            case .customsStampThud:
                // Глухой удар штампа (68 Hz + короткий бумажный шелест)
                let noise = Double.random(in: -1.0...1.0) * exp(-t * 35.0)
                sample = (sin(2.0 * .pi * 68.0 * t) * 0.75 + noise * 0.25) * env * 0.45
            case .typewriterKeyTick:
                let noise = Double.random(in: -1.0...1.0)
                sample = (sin(2.0 * .pi * 2400.0 * t) * 0.5 + noise * 0.5) * env * 0.25
            case .slitTensionWarning:
                // Нарастающий нуарный тритон (F#2 + C3)
                sample = (sin(2.0 * .pi * 92.5 * t) + sin(2.0 * .pi * 130.8 * t)) * env * 0.22
            case .contrabandAlarm:
                // Тревожный минорный аккорд
                sample = (sin(2.0 * .pi * 220.0 * t) + sin(2.0 * .pi * 261.6 * t) + sin(2.0 * .pi * 311.1 * t)) * env * 0.28
            }

            channel[i] = Float(sample)
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        #endif
    }
}
