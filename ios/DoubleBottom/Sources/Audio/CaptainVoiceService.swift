import Foundation
#if canImport(AVFAudio)
import AVFAudio
#endif

/// Supported game languages (English and French only; no Russian).
public enum GameLanguage: String, Codable, CaseIterable, Sendable {
    case en
    case fr
}

/// Trigger contexts for Customs Captain Vera Lisitsyna at Checkpoint "Swallow" (Section 8.6).
public enum CaptainLineTrigger: String, Codable, CaseIterable, Sendable {
    case roundStart
    case slitOpened
    case highNervometer
    case cleanInspection
    case contrabandCaught
    case bribeAccepted
    case falseBottomFound
}

public struct CaptainLineEntry: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let trigger: CaptainLineTrigger
    public let textEn: String
    public let textFr: String

    public init(id: String, trigger: CaptainLineTrigger, textEn: String, textFr: String) {
        self.id = id
        self.trigger = trigger
        self.textEn = textEn
        self.textFr = textFr
    }

    public func text(for language: GameLanguage) -> String {
        switch language {
        case .en: return textEn
        case .fr: return textFr
        }
    }
}

public struct CaptainLinesCatalog: Codable, Sendable {
    public let captainNameEn: String
    public let captainNameFr: String
    public let checkpointNameEn: String
    public let checkpointNameFr: String
    public let lines: [CaptainLineEntry]
}

/// Service for selecting and voicing Customs Captain Vera Lisitsyna's lines in English (`en`) and French (`fr`).
/// Uses `AVSpeechSynthesizer` with automatic `.premium` / `.enhanced` neural voice selection and multi-clause prosody contouring.
@MainActor
public final class CaptainVoiceService: ObservableObject {
    @Published public var language: GameLanguage = .en
    @Published public private(set) var currentLine: String =
        "\"Welcome to Checkpoint 'Swallow'. Passport and customs declaration on the desk.\""
    public var isSpeechEnabled: Bool = true

    public let lines: [CaptainLineEntry]

    #if canImport(AVFAudio)
    private let synthesizer = AVSpeechSynthesizer()
    #endif

    public init(bundle: Bundle = .main) {
        if let url = bundle.url(forResource: "CaptainLines", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(CaptainLinesCatalog.self, from: data) {
            self.lines = decoded.lines
        } else {
            self.lines = Self.embeddedFallbackLines
        }
    }

    /// Selects a line for the given trigger in the active language (`en` or `fr`) and speaks it with multi-clause prosody.
    @discardableResult
    public func triggerLine(for event: CaptainLineTrigger) -> String {
        let matching = lines.filter { $0.trigger == event }
        let chosen = matching.randomElement()?.text(for: language)
            ?? (language == .fr
                ? "« Le poste-frontière 'Hirondelle' note chacun de vos gestes, voyageur. »"
                : "\"Checkpoint 'Swallow' logs every single movement you make, traveler.\"")
        currentLine = chosen
        speakIfEnabled(chosen, language: language)
        return chosen
    }

    public func speakCustomLine(_ text: String, language: GameLanguage? = nil) {
        let lang = language ?? self.language
        currentLine = text
        speakIfEnabled(text, language: lang)
    }

    private func speakIfEnabled(_ text: String, language: GameLanguage) {
        guard isSpeechEnabled else { return }
        #if canImport(AVFAudio)
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let cleaned = text
            .replacingOccurrences(of: "«", with: "")
            .replacingOccurrences(of: "»", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let selectedVoice = Self.selectBestVoice(for: language)
        let clauses = Self.splitIntoProsodyClauses(cleaned)

        for (index, clause) in clauses.enumerated() {
            let utterance = AVSpeechUtterance(string: clause)
            utterance.voice = selectedVoice
            let baseRate: Float = language == .fr ? 0.48 : 0.47
            let basePitch: Float = language == .fr ? 0.96 : 0.92
            if clause.hasSuffix("?") {
                utterance.pitchMultiplier = basePitch + 0.05
                utterance.rate = baseRate + 0.01
            } else if clause.hasSuffix("!") {
                utterance.pitchMultiplier = basePitch + 0.02
                utterance.rate = baseRate + 0.02
            } else if index == clauses.count - 1 && clauses.count > 1 {
                utterance.pitchMultiplier = basePitch - 0.04
                utterance.rate = baseRate - 0.02
            } else {
                utterance.pitchMultiplier = basePitch
                utterance.rate = baseRate
            }
            utterance.postUtteranceDelay = index < clauses.count - 1 ? 0.14 : 0.04
            synthesizer.speak(utterance)
        }
        #endif
    }

    #if canImport(AVFAudio)
    /// Ranks available system voices to pick the highest-quality female neural/enhanced voice for English or French.
    private static func selectBestVoice(for language: GameLanguage) -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let targetPrefixes = language == .fr ? ["fr-FR", "fr-CA", "fr-CH"] : ["en-GB", "en-US", "en-IE", "en-AU"]
        let preferredNames = language == .fr
            ? ["Audrey", "Amélie", "Amelie", "Aurélie", "Aurelie", "Marie", "Denise", "Eloise"]
            : ["Serena", "Kate", "Martha", "Samantha", "Victoria", "Karen", "Moira", "Sonia"]

        let candidates = allVoices.filter { voice in
            targetPrefixes.contains(where: { voice.language.hasPrefix($0) })
        }

        let sorted = candidates.sorted { a, b in
            scoreVoice(a, preferredNames: preferredNames, targetPrefixes: targetPrefixes) >
            scoreVoice(b, preferredNames: preferredNames, targetPrefixes: targetPrefixes)
        }

        if let best = sorted.first {
            return best
        }
        return AVSpeechSynthesisVoice(language: language == .fr ? "fr-FR" : "en-GB")
    }

    private static func scoreVoice(
        _ voice: AVSpeechSynthesisVoice,
        preferredNames: [String],
        targetPrefixes: [String]
    ) -> Int {
        var score = 0
        if voice.quality == .premium { score += 50 }
        else if voice.quality == .enhanced { score += 35 }
        if voice.gender == .female { score += 20 }
        if let firstPrefix = targetPrefixes.first, voice.language == firstPrefix {
            score += 15
        }
        for (idx, name) in preferredNames.enumerated() {
            if voice.name.localizedCaseInsensitiveContains(name) {
                score += (30 - idx * 2)
                break
            }
        }
        return score
    }
    #endif

    private static func splitIntoProsodyClauses(_ text: String) -> [String] {
        let normalized = text
            .replacingOccurrences(of: " — ", with: ". ")
            .replacingOccurrences(of: " – ", with: ". ")
        let parts = normalized
            .components(separatedBy: CharacterSet(charactersIn: ".;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? [text] : parts
    }

    /// Embedded fallback catalog for unit tests or when bundle JSON is omitted.
    public static let embeddedFallbackLines: [CaptainLineEntry] = [
        CaptainLineEntry(
            id: "fb_1",
            trigger: .roundStart,
            textEn: "\"Checkpoint 'Swallow', night shift. Open the suitcase on your wing, pack the cargo, and fill out the customs form without a single smudge.\"",
            textFr: "« Poste-frontière 'Hirondelle', brigade de nuit. Ouvrez la valise de votre côté, rangez la marchandise et remplissez le formulaire sans rature. »"
        ),
        CaptainLineEntry(
            id: "fb_2",
            trigger: .slitOpened,
            textEn: "\"The slit is open! Watch the brass hinge: two more degrees and the lead seal snaps for good.\"",
            textFr: "« L'entrebâillement s'ouvre ! Surveillez la charnière en laiton : encore deux degrés et le scellé en plomb saute définitivement. »"
        ),
        CaptainLineEntry(
            id: "fb_3",
            trigger: .highNervometer,
            textEn: "\"The Nervometer needle is dancing like an interrogation in Nordmark. Are you carrying Alpine cheese or classified microfilm?\"",
            textFr: "« L'aiguille du Nervomètre danse comme lors d'un interrogatoire à Nordmark. Vous transportez du fromage alpin ou des microfilms classifiés ? »"
        ),
        CaptainLineEntry(
            id: "fb_4",
            trigger: .cleanInspection,
            textEn: "\"All clean! Strictly according to the manifest. The treasury will pay you compensation for wrinkling your velvet lining.\"",
            textFr: "« Tout est en règle ! Strictement conforme au manifeste. La trésorerie vous versera une indemnité pour le velours froissé. »"
        ),
        CaptainLineEntry(
            id: "fb_5",
            trigger: .contrabandCaught,
            textEn: "\"Aha! Contraband uncovered. Put the seizure protocol on the desk and send the cargo straight to the confiscation vault!\"",
            textFr: "« Aha ! Contrebande découverte. Posez le procès-verbal de saisie sur le bureau et envoyez la cargaison au coffre des confiscations ! »"
        ),
        CaptainLineEntry(
            id: "fb_6",
            trigger: .bribeAccepted,
            textEn: "\"Silver marks slipped into the passport quieter than the night rain. Move along while I'm still in a generous mood.\"",
            textFr: "« Les marks d'argent ont glissé dans le passeport plus doucement que la pluie nocturne. Circulez pendant que je suis encore d'humeur généreuse. »"
        ),
        CaptainLineEntry(
            id: "fb_7",
            trigger: .falseBottomFound,
            textEn: "\"A false bottom! One tilt of the suitcase and the hidden compartment sang right out. Writing up the double penalty!\"",
            textFr: "« Un double fond ! Une inclinaison de la valise et la cachette secrète a chanté. Je rédige la pénalité doublée ! »"
        )
    ]
}
