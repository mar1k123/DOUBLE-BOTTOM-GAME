import Foundation
import Combine

/// Режим запуска матча (раздел 10.1–10.3).
public enum GameLaunchMode: String, CaseIterable, Sendable {
    /// Классический локальный матч на 2–6 игроков с передачей одного iPhone Duo по кругу.
    case passAndPlayParty
    /// Соло-режим «Против капитана»: один человек против бота-капитана Веры Лисицыной (`adaptive_ai` / `mixed_bluffer`).
    case soloAgainstCaptain
    /// 40-секундный управляемый демо-раунд для витрины или быстрой демонстрации механики петли.
    case storefrontDemo40s
}

/// Шаг 40-секундного демо-раунда для витрины (раздел 10.3).
public struct StorefrontDemoStep: Identifiable, Equatable, Sendable {
    public let id: Int
    public let startSecond: Int
    public let endSecond: Int
    public let targetHingeAngleDegrees: Double
    public let titleRu: String
    public let instructionRu: String

    public init(
        id: Int,
        startSecond: Int,
        endSecond: Int,
        targetHingeAngleDegrees: Double,
        titleRu: String,
        instructionRu: String
    ) {
        self.id = id
        self.startSecond = startSecond
        self.endSecond = endSecond
        self.targetHingeAngleDegrees = targetHingeAngleDegrees
        self.titleRu = titleRu
        self.instructionRu = instructionRu
    }
}

/// Контроллер соло-режима «Против капитана» и 40-секундного демо-раунда для витрины (раздел 10).
@MainActor
public final class SoloAndStorefrontDemoController: ObservableObject {
    @Published public private(set) var launchMode: GameLaunchMode = .passAndPlayParty
    @Published public private(set) var demoElapsedSeconds: Int = 0
    @Published public private(set) var currentDemoStep: StorefrontDemoStep?
    @Published public private(set) var isDemoRunning: Bool = false

    private let stateMachine: RoundStateMachine
    private let hingeSimulator: SimulatedHingeProvider
    private var demoTimer: Timer?
    private var rng = SeededRandomGenerator(seed: 1964)

    public static let storefrontSteps: [StorefrontDemoStep] = [
        StorefrontDemoStep(
            id: 1,
            startSecond: 0,
            endSecond: 10,
            targetHingeAngleDegrees: 115.0,
            titleRu: "0–10 с • Укладка на внутреннем экране 7.6\"",
            instructionRu: "Внутренний экран раскрыт: уложите «Микроплёнку» в потайной отсек «Двойное дно», а «Альпийский сыр» — в основной слот."
        ),
        StorefrontDemoStep(
            id: 2,
            startSecond: 10,
            endSecond: 18,
            targetHingeAngleDegrees: 1.5,
            titleRu: "10–18 с • Опечатывание чемодана (<= 3° на 250 мс)",
            instructionRu: "Крышка захлопнута: внутренний экран мгновенно гаснет, а на внешнем экране 5.4\" появляется паспорт и шкала «Нервомера»."
        ),
        StorefrontDemoStep(
            id: 3,
            startSecond: 18,
            endSecond: 30,
            targetHingeAngleDegrees: 19.5,
            titleRu: "18–30 с • Щель досмотра (3° -> 14° -> 20°)",
            instructionRu: "Приоткрываем крышку: Уровень 1 показывает вес, Уровень 2 — силуэты, Уровень 3 — цветовой намёк категории (точность 75%)."
        ),
        StorefrontDemoStep(
            id: 4,
            startSecond: 30,
            endSecond: 40,
            targetHingeAngleDegrees: 120.0,
            titleRu: "30–40 с • Необратимое вскрытие (>= 25°) и Протокол",
            instructionRu: "Порог 25° пройден! Чемодан вскрыт официально, качните устройство для поиска «Двойного дна» и получите карточку «Протокол вскрытия»."
        )
    ]

    public init(stateMachine: RoundStateMachine, hingeSimulator: SimulatedHingeProvider) {
        self.stateMachine = stateMachine
        self.hingeSimulator = hingeSimulator
    }

    // MARK: - Соло-режим «Против капитана»

    /// Запускает ход бота-капитана Веры Лисицыной в соло-режиме (когда человек играет за Контрабандиста или Инспектора).
    public func executeSoloBotTurnIfNeeded(humanIsSmuggler: Bool) {
        launchMode = .soloAgainstCaptain
        if !humanIsSmuggler && stateMachine.phase == .packing {
            // Бот-контрабандист укладывает груз и захлопывает чемодан
            guard let secret = stateMachine.secretState else { return }
            let decision = BotDecisionEngine.chooseSmugglerMove(
                hand: secret.dealtHand,
                profile: .mixedBluffer,
                rng: &rng
            )
            stateMachine.configurePacking(
                visibleItems: decision.visibleItems,
                falseBottomItem: decision.falseBottomItem,
                declaration: decision.declaration
            )
            hingeSimulator.setAngle(1.0, at: Date().timeIntervalSinceReferenceDate)
            hingeSimulator.setAngle(1.0, at: Date().timeIntervalSinceReferenceDate + 0.35)
        } else if humanIsSmuggler && (stateMachine.phase == .sealed || stateMachine.phase == .decision) {
            // Бот-инспектор (Капитан Лисицына) анализирует декларацию и Нервомер
            let projection = stateMachine.makePublicProjection()
            guard let decl = projection.declaration else { return }
            let action = BotDecisionEngine.chooseInspectorMove(
                declaration: decl,
                nervometerScore: projection.nervometerScore,
                inspectorClues: projection.inspectorClueTokens,
                profile: .adaptiveAI,
                pastSmugglerBluffRate: 0.50,
                rng: &rng
            )
            if action.shouldInspect {
                if action.useLevel3Slit {
                    hingeSimulator.setAngle(20.0)
                }
                stateMachine.commitOpenInspection()
            } else {
                stateMachine.decidePass(acceptBribe: action.acceptBribe)
            }
        }
    }

    // MARK: - 40-секундный управляемый демо-раунд для витрины

    public func startStorefrontDemo40s() {
        stopStorefrontDemo()
        launchMode = .storefrontDemo40s
        demoElapsedSeconds = 0
        isDemoRunning = true
        applyDemoStep(forSecond: 0)

        demoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickDemoSecond()
            }
        }
    }

    public func stopStorefrontDemo() {
        isDemoRunning = false
        demoTimer?.invalidate()
        demoTimer = nil
    }

    private func tickDemoSecond() {
        guard isDemoRunning else { return }
        demoElapsedSeconds += 1
        if demoElapsedSeconds >= 40 {
            stopStorefrontDemo()
            return
        }
        applyDemoStep(forSecond: demoElapsedSeconds)
    }

    private func applyDemoStep(forSecond second: Int) {
        guard let step = Self.storefrontSteps.first(where: { second >= $0.startSecond && second < $0.endSecond }) else {
            return
        }
        if currentDemoStep?.id != step.id {
            currentDemoStep = step
            let now = Date().timeIntervalSinceReferenceDate
            hingeSimulator.setAngle(step.targetHingeAngleDegrees, at: now)
            if step.targetHingeAngleDegrees <= Tuning.sealedThresholdDegrees {
                hingeSimulator.setAngle(step.targetHingeAngleDegrees, at: now + 0.30)
            }
        }
    }
}
