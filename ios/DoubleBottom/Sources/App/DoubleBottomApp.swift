import SwiftUI

/// Корневой координатор вертикального среза «ДВОЙНОЕ ДНО» (`DoubleBottomRootView`).
/// Объединяет `RoundStateMachine`, `SimulatedHingeProvider` / `HardwareHingeProvider`,
/// `InnerSceneView` (7.6"), `OuterSceneView` (5.4"), `FalseBottomTiltDetector`,
/// `NoirAudioSynthesizer`, `HapticsEngine`, `CaptainVoiceService`, `ThermalMonitor`
/// и `ProtocolGalleryView` в единый готовый к запуску цикл.
public struct DoubleBottomRootView: View {
    @StateObject private var stateMachine: RoundStateMachine
    @StateObject private var simulatedHinge = SimulatedHingeProvider(initialAngle: 115.0)
    @StateObject private var tiltDetector = FalseBottomTiltDetector()
    @StateObject private var audioSynth = NoirAudioSynthesizer()
    @StateObject private var captainVoice = CaptainVoiceService()
    @StateObject private var thermalMonitor = ThermalMonitor()
    @StateObject private var protocolExport = ProtocolExportManager()

    @State private var haptics = HapticsEngine()
    @State private var stampHistory: [PassportStampRecord] = []
    @State private var showProtocolGallery: Bool = false
    @State private var showConsentSheet: Bool = false
    @State private var isCameraEnabled: Bool = true
    @State private var useSplitSimulatorLayout: Bool = true

    public init() {
        let initialPlayers = [
            PlayerProfile(id: "p1", name: "Марк (Пассажир)", coins: Tuning.startingCoins, clueTokens: Tuning.startingClueTokens),
            PlayerProfile(id: "p2", name: "Кап. Лисицына", coins: Tuning.startingCoins, clueTokens: Tuning.startingClueTokens, botStrategy: .adaptiveAI)
        ]
        let deck = DeckBuilder.loadDefaultCatalog()
        _stateMachine = StateObject(wrappedValue: RoundStateMachine(players: initialPlayers, catalog: deck))
    }

    public var body: some View {
        let projection = stateMachine.makePublicProjection()

        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.04)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topDeveloperToolbar(projection: projection)

                if useSplitSimulatorLayout {
                    // Одновременный показ Внешнего экрана 5.4" и Внутреннего экрана 7.6" для отладки на Mac / iPad / iPhone
                    HStack(spacing: 14) {
                        OuterSceneView(
                            projection: projection,
                            stampHistory: stampHistory,
                            captainQuoteRu: captainVoice.currentLineRu,
                            onActivateXRay: {
                                stateMachine.activateXRayScan()
                                audioSynth.playCue(.typewriterKeyTick)
                            },
                            onDecidePass: { acceptBribe in
                                stateMachine.decidePass(acceptBribe: acceptBribe)
                                haptics.playPassportStampThud()
                                audioSynth.playCue(.customsStampThud)
                                captainVoice.triggerLine(for: acceptBribe ? .bribeAccepted : .cleanInspection)
                                recordStampIfNeeded()
                            },
                            onCommitOpenInspection: {
                                simulatedHinge.setAngle(115.0)
                                stateMachine.commitOpenInspection()
                                haptics.playCommitSealBreakSnap()
                                audioSynth.playCue(.contrabandAlarm)
                                recordProtocolAndStampAfterCommit()
                            },
                            onAdvanceNextRound: {
                                advanceToNextRound()
                            }
                        )
                        .frame(width: 390)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        InnerSceneView(
                            stateMachine: stateMachine,
                            tiltDetector: tiltDetector,
                            colorblindPatternsEnabled: true
                        )
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(12)
                } else {
                    // Автоматическое переключение сцен по углу физического шарнира iPhone Duo
                    if stateMachine.hingeAngleDegrees <= Tuning.sealedThresholdDegrees
                        && (stateMachine.phase == .sealed || stateMachine.phase == .decision) {
                        OuterSceneView(
                            projection: projection,
                            stampHistory: stampHistory,
                            captainQuoteRu: captainVoice.currentLineRu,
                            onActivateXRay: { stateMachine.activateXRayScan() },
                            onDecidePass: { acceptBribe in
                                stateMachine.decidePass(acceptBribe: acceptBribe)
                                recordStampIfNeeded()
                            },
                            onCommitOpenInspection: {
                                stateMachine.commitOpenInspection()
                                recordProtocolAndStampAfterCommit()
                            },
                            onAdvanceNextRound: { advanceToNextRound() }
                        )
                    } else {
                        InnerSceneView(
                            stateMachine: stateMachine,
                            tiltDetector: tiltDetector,
                            colorblindPatternsEnabled: true
                        )
                    }
                }
            }
        }
        // Подписка на реальный шарнир iOS 27.1 (плюс симуляторный ползунок угла)
        .observeHardwareHingeIfAvailable { angle, timestamp in
            handleHingeAngleChange(angle: angle, timestamp: timestamp)
        }
        .onChange(of: simulatedHinge.currentAngleDegrees) { _, newAngle in
            handleHingeAngleChange(angle: newAngle, timestamp: Date().timeIntervalSinceReferenceDate)
        }
        .sheet(isPresented: $showProtocolGallery) {
            ProtocolGalleryView(exportManager: protocolExport) {
                showProtocolGallery = false
            }
        }
        .sheet(isPresented: $showConsentSheet) {
            CameraPrivacyConsentView(
                isCameraNervometerEnabled: $isCameraEnabled,
                isPassengerProtocolConsentGranted: $protocolExport.consentState.smugglerPhotoConsentGranted,
                isInspectorProtocolConsentGranted: $protocolExport.consentState.inspectorPhotoConsentGranted
            ) {
                showConsentSheet = false
            }
        }
    }

    private func topDeveloperToolbar(projection: PublicProjection) -> some View {
        HStack(spacing: 14) {
            Text("ДВОЙНОЕ ДНО • iPhone Duo (iOS 27.1)")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))

            HStack(spacing: 8) {
                Text("УГОЛ ПЕТЛИ: \(String(format: "%.1f°", stateMachine.hingeAngleDegrees))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Slider(
                    value: Binding(
                        get: { simulatedHinge.currentAngleDegrees },
                        set: { simulatedHinge.setAngle($0) }
                    ),
                    in: 0...180,
                    step: 0.5
                )
                .frame(width: 180)
                .tint(Color(red: 0.78, green: 0.64, blue: 0.35))
            }

            Button("Опечатать (0°)") {
                let now = Date().timeIntervalSinceReferenceDate
                simulatedHinge.setAngle(0.0, at: now)
                simulatedHinge.setAngle(0.0, at: now + 0.30)
                haptics.playSuitcaseSealLatch()
                audioSynth.playCue(.brassLatchClick)
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .buttonStyle(.bordered)
            .tint(Color(red: 0.78, green: 0.64, blue: 0.35))

            Button("Щель 19°") {
                simulatedHinge.setAngle(19.0)
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .buttonStyle(.bordered)
            .tint(.orange)

            Button("Протоколы (\(protocolExport.matchProtocolCards.count))") {
                showProtocolGallery = true
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .buttonStyle(.bordered)
            .tint(.white)

            Button("Приватность") {
                showConsentSheet = true
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .buttonStyle(.bordered)
            .tint(.cyan)

            Spacer()

            Toggle("2 экрана рядом", isOn: $useSplitSimulatorLayout)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white)
                .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.85))
    }

    private func handleHingeAngleChange(angle: Double, timestamp: TimeInterval) {
        let previousPhase = stateMachine.phase
        stateMachine.updateHingeAngle(angle, timestamp: timestamp)
        haptics.updateSlitAngle(angle)
        audioSynth.updateHingeTension(angleDegrees: angle)

        if previousPhase != .slit && stateMachine.phase == .slit {
            captainVoice.triggerLine(for: .slitOpened)
        } else if previousPhase != .committed && stateMachine.phase == .committed {
            haptics.playCommitSealBreakSnap()
            audioSynth.playCue(.contrabandAlarm)
            recordProtocolAndStampAfterCommit()
        }
    }

    private func recordStampIfNeeded() {
        guard let stamp = stateMachine.makePublicProjection().verdictStampText else { return }
        let record = PassportStampRecord(roundNumber: stateMachine.roundNumber, stampTitleRu: stamp)
        if !stampHistory.contains(record) {
            stampHistory.append(record)
        }
    }

    private func recordProtocolAndStampAfterCommit() {
        recordStampIfNeeded()
        guard let secret = stateMachine.secretState,
              let outcome = stateMachine.lastOutcome else { return }

        captainVoice.triggerLine(for: outcome.contrabandFound ? .contrabandCaught : .cleanInspection)

        let composer = ProtocolComposer()
        let projection = stateMachine.makePublicProjection()
        let card = composer.composeProtocolCard(
            roundNumber: stateMachine.roundNumber,
            smugglerName: projection.smugglerName,
            inspectorName: projection.inspectorName,
            smugglerFrame: nil,
            inspectorFrame: nil,
            smugglerConsent: protocolExport.consentState.smugglerPhotoConsentGranted,
            inspectorConsent: protocolExport.consentState.inspectorPhotoConsentGranted,
            packedCase: secret.packedCase,
            outcome: outcome
        )
        protocolExport.appendCard(card)
    }

    private func advanceToNextRound() {
        simulatedHinge.setAngle(115.0)
        stateMachine.advanceToNextRound()
        captainVoice.triggerLine(for: .roundStart)
    }
}
