import SwiftUI

/// Внутренний экран 7.6" (`InnerSceneView`, ~890x626 pt в альбоме, regular size classes).
/// Отображает содержимое чемодана и интерактивный стол укладки ТОВАРИЩА ПАССАЖИРА в фазе `PACKING`,
/// уровни щели досмотра 1–3 (`3°–25°`) в фазе `INSPECTION` и полное вскрытие чемодана (`>= 25°`) в фазе `COMMITTED`.
/// Защищён `PresentationPolicy`: в фазах `SEALED` и `DECISION` при угле `< 3°` рендерит пустой чёрный экран без секретных View в иерархии.
public struct InnerSceneView: View {
    @ObservedObject var stateMachine: RoundStateMachine
    @ObservedObject var tiltDetector: FalseBottomTiltDetector
    public var colorblindPatternsEnabled: Bool

    @State private var selectedMulliganIDs: Set<String> = []
    @State private var selectedLegalCategory: LegalCategory = .food
    @State private var declaredCount: Int = 2
    @State private var bribeAmount: Int = 0

    public init(
        stateMachine: RoundStateMachine,
        tiltDetector: FalseBottomTiltDetector,
        colorblindPatternsEnabled: Bool = true
    ) {
        self.stateMachine = stateMachine
        self.tiltDetector = tiltDetector
        self.colorblindPatternsEnabled = colorblindPatternsEnabled
    }

    public var body: some View {
        let mode = PresentationPolicy.innerDisplayMode(
            phase: stateMachine.phase,
            hingeAngle: stateMachine.hingeAngleDegrees,
            secretState: stateMachine.secretState
        )

        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.04)
                .ignoresSafeArea()

            switch mode {
            case .blackout:
                blackoutShieldView

            case .packingInteractive(let secret):
                packingDeskView(secret: secret)

            case .slitLevel1(let totalWeightKg, let maxWeightKg):
                slitLevel1WeightView(totalWeightKg: totalWeightKg, maxWeightKg: maxWeightKg)

            case .slitLevel2(let silhouettes, let totalWeightKg):
                slitLevel2SilhouettesView(silhouettes: silhouettes, totalWeightKg: totalWeightKg)

            case .slitLevel3(let hintedSilhouettes, let totalWeightKg, let accuracy):
                slitLevel3HintsView(
                    hintedSilhouettes: hintedSilhouettes,
                    totalWeightKg: totalWeightKg,
                    accuracy: accuracy
                )

            case .committedFullReveal(let secret, let falseBottomFound):
                committedFullInspectionView(secret: secret, falseBottomFound: falseBottomFound)
            }
        }
        .onChange(of: stateMachine.phase) { _, newPhase in
            if newPhase == .committed {
                if stateMachine.secretState?.packedCase.falseBottomItem != nil {
                    tiltDetector.startSearchWindow()
                }
            } else {
                tiltDetector.stopSearchWindow()
            }
        }
        .onChange(of: tiltDetector.isFound) { _, found in
            if found {
                stateMachine.registerFalseBottomFoundByTilt()
            }
        }
    }

    // MARK: - 1. Blackout Shield (Защита от утечки при закрытой крышке)

    private var blackoutShieldView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.35))
            Text("ЧЕМОДАН ОПЕЧАТАН • ВНУТРЕННИЙ ЭКРАН ПОГАШЕН")
                .font(.system(.caption, design: .monospaced))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.35))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Чемодан опечатан. Внутренний экран заблокирован для защиты тайны укладки.")
    }

    // MARK: - 2. Фаза PACKING (Укладка, Муллиган, Двойное дно и Декларация)

    private func packingDeskView(secret: SecretState) -> some View {
        HStack(spacing: 0) {
            // Левое крыло: Бархатный ложемент чемодана (5 основных слотов + 1 слот Двойного дна) + рука из 6 карт
            VStack(alignment: .leading, spacing: 14) {
                headerBanner(
                    title: "УКЛАДКА БАГАЖА • ЛЕВОЕ КРЫЛО",
                    subtitle: "Видимых слотов: \(secret.packedCase.visibleItems.count)/\(Tuning.maxVisibleSuitcaseSlots) • Вес: \(String(format: "%.1f", secret.packedCase.totalWeightKg))/\(String(format: "%.1f", Tuning.maxSuitcaseWeightKg)) кг"
                )

                // Слоты чемодана
                VStack(alignment: .leading, spacing: 8) {
                    Text("ВИДИМЫЕ ОТСЕКИ ЧЕМОДАНА (1–5 ПРЕДМЕТОВ)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 8)], spacing: 8) {
                        ForEach(secret.packedCase.visibleItems) { card in
                            packedCardTile(card: card, isFalseBottom: false)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.23, green: 0.11, blue: 0.13).opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.35), lineWidth: 1)
                        )
                )

                // Скрытый отсек «Двойное дно»
                falseBottomSlotView(secret: secret)

                // Рука контрабандиста + Муллиган
                handAndMulliganSection(secret: secret)

                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Центральный сгиб шарнира (Fold Crease Safe Zone — 28 pt)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.85), Color(red: 0.25, green: 0.18, blue: 0.10).opacity(0.5), .black.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 24)
                .overlay(
                    VStack {
                        ForEach(0..<8, id: \.self) { _ in
                            Circle()
                                .fill(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.35))
                                .frame(width: 4, height: 4)
                                .padding(.vertical, 12)
                        }
                    }
                )
                .accessibilityHidden(true)

            // Правое крыло: Бланк таможенной декларации КПП «Ласточка» и подсказка закрытия крышки
            VStack(alignment: .leading, spacing: 16) {
                headerBanner(
                    title: "ТАМОЖЕННАЯ ДЕКЛАРАЦИЯ • ПРАВОЕ КРЫЛО",
                    subtitle: "КПП «Ласточка» • Пошлина легальных: \(Tuning.customsDutyCoins) монета"
                )

                declarationFormPanel(secret: secret)

                Spacer(minLength: 0)

                sealSuitcaseInstructionBanner(secret: secret)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func falseBottomSlotView(secret: SecretState) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                    Text("ПОТАЙНОЙ ОТСЕК «ДВОЙНОЕ ДНО»")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                }
                Text("Вмещает 1 предмет до \(String(format: "%.1f", Tuning.falseBottomMaxWeightKg)) кг (не виден на рентгене и в щели, но даёт штраф +\(Tuning.falseBottomExtraPenaltyCoins) при обнаружении наклоном)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            if let hidden = secret.packedCase.falseBottomItem {
                packedCardTile(card: hidden, isFalseBottom: true)
                    .frame(width: 155)
            } else {
                Text("ПУСТО")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(.white.opacity(0.25))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func handAndMulliganSection(secret: SecretState) -> some View {
        let packedIDs = Set(secret.packedCase.allItems.map(\.id))
        let availableHand = secret.dealtHand.filter { !packedIDs.contains($0.id) }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("РУКА КОНТРАБАНДИСТА (ДОСТУПНО: \(availableHand.count))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                if !secret.hasUsedMulligan {
                    Button {
                        let ids = Array(selectedMulliganIDs.prefix(Tuning.maxMulliganCards))
                        if !ids.isEmpty {
                            stateMachine.performSmugglerMulligan(discardCardIDs: ids)
                            selectedMulliganIDs.removeAll()
                        }
                    } label: {
                        Label(
                            "СБРОСИТЬ (\(selectedMulliganIDs.count)/\(Tuning.maxMulliganCards))",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedMulliganIDs.isEmpty
                                      ? Color.white.opacity(0.08)
                                      : Color(red: 0.78, green: 0.64, blue: 0.35))
                        )
                        .foregroundStyle(selectedMulliganIDs.isEmpty ? .white.opacity(0.4) : .black)
                    }
                    .frame(minHeight: 44)
                    .disabled(selectedMulliganIDs.isEmpty)
                } else {
                    Text("МУЛЛИГАН ИСПОЛЬЗОВАН")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableHand) { card in
                        handCardView(card: card, secret: secret)
                    }
                }
            }
        }
    }

    private func handCardView(card: ItemCard, secret: SecretState) -> some View {
        let isSelectedForMulligan = selectedMulliganIDs.contains(card.id)
        let canFitFalseBottom = card.hasFalseBottomTag
            && card.weightKg <= Tuning.falseBottomMaxWeightKg
            && secret.packedCase.falseBottomItem == nil

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                categoryBadge(for: card)
                Spacer()
                Text(String(format: "%.1f кг", card.weightKg))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Text(card.titleRu)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("Ценность: +\(card.baseValueCoins) • Штраф: -\(card.contrabandPenaltyCoins)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))

            HStack(spacing: 6) {
                Button {
                    addCardToSuitcase(card: card, intoFalseBottom: false, secret: secret)
                } label: {
                    Text("В отсек")
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.78, green: 0.64, blue: 0.35)))
                        .foregroundStyle(.black)
                }

                if canFitFalseBottom {
                    Button {
                        addCardToSuitcase(card: card, intoFalseBottom: true, secret: secret)
                    } label: {
                        Text("В дно")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .frame(minHeight: 36)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.purple.opacity(0.75)))
                            .foregroundStyle(.white)
                    }
                }

                if !secret.hasUsedMulligan {
                    Button {
                        toggleMulliganSelection(cardID: card.id)
                    } label: {
                        Image(systemName: isSelectedForMulligan ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .frame(width: 36, height: 36)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Выбрать \(card.titleRu) для сброса муллиганом")
                }
            }
        }
        .padding(10)
        .frame(width: 195)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelectedForMulligan
                                ? Color.orange
                                : (card.isContraband ? Color.red.opacity(0.55) : Color.green.opacity(0.45)),
                            lineWidth: 1.5
                        )
                )
        )
    }

    private func packedCardTile(card: ItemCard, isFalseBottom: Bool) -> some View {
        Button {
            if let secret = stateMachine.secretState {
                removeCardFromSuitcase(cardID: card.id, secret: secret)
            }
        } label: {
            HStack(spacing: 8) {
                categoryBadge(for: card)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.titleRu)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(String(format: "%.1f", card.weightKg)) кг • +\(card.baseValueCoins) м.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer(minLength: 4)
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(8)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFalseBottom ? Color.purple.opacity(0.28) : Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(card.isContraband ? Color.red.opacity(0.6) : Color.green.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Убрать \(card.titleRu) из чемодана")
    }

    private func declarationFormPanel(secret: SecretState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ЗАЯВЛЕННАЯ ЛЕГАЛЬНАЯ КАТЕГОРИЯ")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.20, green: 0.16, blue: 0.12))

            HStack(spacing: 8) {
                ForEach(LegalCategory.allCases, id: \.self) { category in
                    let isSelected = secret.declaration.declaredCategory == category
                    Button {
                        selectedLegalCategory = category
                        syncDeclaration(secret: secret)
                    } label: {
                        Text(category.titleRu)
                            .font(.system(size: 12, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color(red: 0.16, green: 0.13, blue: 0.10) : Color.black.opacity(0.08))
                            )
                            .foregroundStyle(isSelected ? Color(red: 0.95, green: 0.90, blue: 0.78) : .black)
                    }
                }
            }

            Divider().background(Color.black.opacity(0.2))

            HStack {
                Text("ЗАЯВЛЕННОЕ ЧИСЛО ПРЕДМЕТОВ:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.20, green: 0.16, blue: 0.12))
                Spacer()
                Stepper(
                    value: Binding(
                        get: { secret.declaration.declaredCount },
                        set: { newValue in
                            declaredCount = newValue
                            syncDeclaration(secret: secret)
                        }
                    ),
                    in: Tuning.minVisibleSuitcaseSlots...Tuning.maxVisibleSuitcaseSlots
                ) {
                    Text("\(secret.declaration.declaredCount) шт.")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                }
                .frame(width: 170, minHeight: 44)
            }

            Divider().background(Color.black.opacity(0.2))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("МОНЕТЫ В ПАСПОРТ («ЧАЕВЫЕ ИНСПЕКТОРУ»)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.20, green: 0.16, blue: 0.12))
                    Text("Нельзя совмещать со сканером X-Ray или честным досмотром")
                        .font(.system(size: 10))
                        .foregroundStyle(.black.opacity(0.65))
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0...Tuning.maxBribeCoins, id: \.self) { amount in
                        let active = secret.declaration.bribeOfferedCoins == amount
                        Button {
                            bribeAmount = amount
                            syncDeclaration(secret: secret)
                        } label: {
                            Text("\(amount)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(active ? Color(red: 0.72, green: 0.18, blue: 0.16) : Color.black.opacity(0.1))
                                )
                                .foregroundStyle(active ? .white : .black)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.93, green: 0.89, blue: 0.79))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        )
    }

    private func sealSuitcaseInstructionBanner(secret: SecretState) -> some View {
        let canSeal = !secret.packedCase.visibleItems.isEmpty
            && secret.packedCase.totalWeightKg <= Tuning.maxSuitcaseWeightKg

        return HStack(spacing: 12) {
            Image(systemName: canSeal ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundStyle(canSeal ? Color(red: 0.78, green: 0.64, blue: 0.35) : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(canSeal
                     ? "ЗАКРОЙТЕ КРЫШКУ IPHONE DUO (УГОЛ <= 3° НА 250 МС), ЧТОБЫ ОПЕЧАТАТЬ ЧЕМОДАН"
                     : "ПОЛОЖИТЕ МИНИМУМ 1 ВИДИМЫЙ ПРЕДМЕТ (ДО 6.0 КГ)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("После щелчка латунного замка чемодан перейдёт в фазу SEALED. Передайте устройство Инспектору.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.16, green: 0.12, blue: 0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.55), lineWidth: 1)
                )
        )
    }

    // MARK: - 3. Уровни щели досмотра (SLIT 3°–25°)

    private func slitLevel1WeightView(totalWeightKg: Double, maxWeightKg: Double) -> some View {
        VStack(spacing: 16) {
            slitWarningHeader(level: 1, rangeText: "3°–10° • ВЕСОВОЙ ДАТЧИК ПЕТЛИ")

            Text(String(format: "%.1f / %.1f КГ", totalWeightKg, maxWeightKg))
                .font(.system(size: 46, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))

            ProgressView(value: min(totalWeightKg, maxWeightKg), total: maxWeightKg)
                .tint(totalWeightKg > 4.5 ? .red : Color(red: 0.78, green: 0.64, blue: 0.35))
                .frame(maxWidth: 420)

            Text("ВНИМАНИЕ: Угол >= 25° необратимо вскроет чемодан!")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.orange)
        }
        .padding(24)
    }

    private func slitLevel2SilhouettesView(silhouettes: [SilhouetteDescriptor], totalWeightKg: Double) -> some View {
        VStack(spacing: 18) {
            slitWarningHeader(level: 2, rangeText: "10°–18° • СИЛУЭТЫ И РАЗМЕРЫ ВИДИМЫХ ПРЕДМЕТОВ")

            HStack(spacing: 16) {
                ForEach(silhouettes) { item in
                    VStack(spacing: 8) {
                        silhouetteShapeView(shape: item.silhouette, tint: .gray)
                            .frame(width: 90, height: 90)
                        Text(item.sizeLabel.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(String(format: "%.1f кг", item.weightKg))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
            }

            Text("Суммарный вес (включая обшивку): \(String(format: "%.1f", totalWeightKg)) кг • Двойное дно скрыто от щели")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(24)
    }

    private func slitLevel3HintsView(
        hintedSilhouettes: [HintedSilhouetteDescriptor],
        totalWeightKg: Double,
        accuracy: Double
    ) -> some View {
        VStack(spacing: 18) {
            slitWarningHeader(
                level: 3,
                rangeText: "18°–25° • ЦВЕТОВОЙ НАМЁК КАТЕГОРИИ (ТОЧНОСТЬ \(Int(accuracy * 100))% • -1 УЛИКА)"
            )

            HStack(spacing: 16) {
                ForEach(hintedSilhouettes) { item in
                    let tintColor = item.appearsSuspiciousRed ? Color.red : Color.green
                    VStack(spacing: 8) {
                        ZStack {
                            silhouetteShapeView(shape: item.silhouette, tint: tintColor)
                                .frame(width: 96, height: 96)

                            if colorblindPatternsEnabled {
                                Text(item.appearsSuspiciousRed ? "⚠️ ШТРИХ" : "✓ ТОЧКИ")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.black.opacity(0.75)))
                                    .foregroundStyle(.white)
                            }
                        }

                        Text(item.appearsSuspiciousRed ? "ПОДОЗРИТЕЛЬНО" : "ПОХОЖЕ НА НОРМУ")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(tintColor)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(tintColor.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        tintColor.opacity(0.7),
                                        style: StrokeStyle(
                                            lineWidth: 1.5,
                                            dash: item.appearsSuspiciousRed ? [5, 3] : []
                                        )
                                    )
                            )
                    )
                }
            }

            Text("ОСТОРОЖНО: До необратимого вскрытия чемодана осталось меньше \(Int(max(0, 25.0 - stateMachine.hingeAngleDegrees)))°!")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.red)
        }
        .padding(24)
    }

    // MARK: - 4. Фаза COMMITTED (Полное вскрытие чемодана >= 25° + поиск Двойного дна)

    private func committedFullInspectionView(secret: SecretState, falseBottomFound: Bool) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ПРОТОКОЛ ВСКРЫТИЯ БАГАЖА • КПП «ЛАСТОЧКА»")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                    Text("Заявлено в декларации: \(secret.declaration.declaredCount)x «\(secret.declaration.declaredCategory.titleRu)»")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                if let outcome = stateMachine.lastOutcome {
                    Text(outcome.summaryRu)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
                        .foregroundStyle(.white)
                }
            }

            // Основные вскрытые предметы
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 12)], spacing: 12) {
                ForEach(secret.packedCase.visibleItems) { card in
                    revealedItemCard(card: card, isFromFalseBottom: false)
                }
            }

            // Панель поиска Двойного дна наклоном устройства (6 секунд, 2 качка >= 25°)
            if let hiddenItem = secret.packedCase.falseBottomItem {
                if falseBottomFound || tiltDetector.isFound {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ВСКРЫТО ДВОЙНОЕ ДНО! ОБНАРУЖЕН ТАЙНИК (+2 К ШТРАФУ)")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundStyle(.red)
                            Text("\(hiddenItem.titleRu) • Базовый штраф: \(hiddenItem.contrabandPenaltyCoins) + \(Tuning.falseBottomExtraPenaltyCoins) за тайник")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.22)))
                } else if tiltDetector.isActive {
                    HStack(spacing: 14) {
                        Image(systemName: "gyroscope")
                            .font(.system(size: 26))
                            .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ПОДОЗРЕНИЕ НА ДВОЙНОЕ ДНО: ПОКАЧАЙТЕ ТЕЛЕФОН ВЛЕВО-ВПРАВО (>= 25°)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                            Text("Качков выполнено: \(tiltDetector.completedSwings)/\(Tuning.falseBottomRequiredSwings) • Осталось времени: \(String(format: "%.1f", tiltDetector.remainingSeconds)) с")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Spacer()

                        Button {
                            tiltDetector.simulateManualSwing()
                        } label: {
                            Text("КАЧНУТЬ ЧЕМОДАН")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 12)
                                .frame(minHeight: 44)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.78, green: 0.64, blue: 0.35)))
                                .foregroundStyle(.black)
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                }
            }
        }
        .padding(22)
    }

    private func revealedItemCard(card: ItemCard, isFromFalseBottom: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                categoryBadge(for: card)
                Spacer()
                Text(card.isContraband ? "КОНТРАБАНДА" : "ЛЕГАЛЬНО")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(card.isContraband ? .red : .green)
            }
            Text(card.titleRu)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text(card.flavorTextRu)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(card.isContraband ? Color.red.opacity(0.16) : Color.green.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(card.isContraband ? Color.red : Color.green, lineWidth: 1.5)
                )
        )
    }

    // MARK: - Helpers

    private func headerBanner(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
            Text(subtitle)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private func slitWarningHeader(level: Int, rangeText: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(level == 3 ? Color.red : Color.orange)
                .frame(width: 10, height: 10)
            Text("ЩЕЛЬ ДОСМОТРА • УРОВЕНЬ \(level) (\(rangeText))")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.1)))
    }

    private func categoryBadge(for card: ItemCard) -> some View {
        let label: String
        let color: Color
        if card.isContraband {
            label = colorblindPatternsEnabled ? "⚠️ КОНТРАБАНДА" : "КОНТРАБАНДА"
            color = .red
        } else {
            label = card.legalCategory?.titleRu.uppercased() ?? "ЛЕГАЛЬНО"
            color = .green
        }
        return Text(label)
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.25)))
            .foregroundStyle(color)
    }

    private func silhouetteShapeView(shape: SilhouetteShape, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(0.25))
            Image(systemName: iconName(for: shape))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(tint)
        }
    }

    private func iconName(for shape: SilhouetteShape) -> String {
        switch shape {
        case .bottle: return "wineglass.fill"
        case .wheel: return "circle.grid.cross.fill"
        case .crate: return "shippingbox.fill"
        case .box: return "cube.box.fill"
        case .tube: return "cylinder.fill"
        case .statue: return "crown.fill"
        case .ingot: return "rectangle.fill.on.rectangle.fill"
        case .apparatus: return "antenna.radiowaves.left.and.right"
        }
    }

    private func toggleMulliganSelection(cardID: String) {
        if selectedMulliganIDs.contains(cardID) {
            selectedMulliganIDs.remove(cardID)
        } else if selectedMulliganIDs.count < Tuning.maxMulliganCards {
            selectedMulliganIDs.insert(cardID)
        }
    }

    private func addCardToSuitcase(card: ItemCard, intoFalseBottom: Bool, secret: SecretState) {
        var visible = secret.packedCase.visibleItems
        var falseBottom = secret.packedCase.falseBottomItem

        if intoFalseBottom {
            falseBottom = card
        } else {
            guard visible.count < Tuning.maxVisibleSuitcaseSlots else { return }
            visible.append(card)
        }

        let newWeight = visible.reduce(0.0) { $0 + $1.weightKg } + (falseBottom?.weightKg ?? 0.0)
        guard newWeight <= Tuning.maxSuitcaseWeightKg else { return }

        stateMachine.configurePacking(
            visibleItems: visible,
            falseBottomItem: falseBottom,
            declaration: secret.declaration
        )
    }

    private func removeCardFromSuitcase(cardID: String, secret: SecretState) {
        var visible = secret.packedCase.visibleItems
        var falseBottom = secret.packedCase.falseBottomItem

        if falseBottom?.id == cardID {
            falseBottom = nil
        } else {
            visible.removeAll { $0.id == cardID }
        }

        guard !visible.isEmpty else { return }
        stateMachine.configurePacking(
            visibleItems: visible,
            falseBottomItem: falseBottom,
            declaration: secret.declaration
        )
    }

    private func syncDeclaration(secret: SecretState) {
        let updated = Declaration(
            declaredCategory: selectedLegalCategory,
            declaredCount: declaredCount,
            bribeOfferedCoins: bribeAmount
        )
        stateMachine.configurePacking(
            visibleItems: secret.packedCase.visibleItems,
            falseBottomItem: secret.packedCase.falseBottomItem,
            declaration: updated
        )
    }
}
