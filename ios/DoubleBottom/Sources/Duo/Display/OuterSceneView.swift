import SwiftUI

/// Внешний экран 5.4" (`OuterSceneView`, ~466x678 pt в портрете, `compact` width).
/// Отображает обложку паспорта и бланк таможенной декларации КПП «Ласточка», шкалу «Нервомера»
/// с доверительным интервалом, кнопку 5-секундного рентгена (X-Ray), кнопки решений Инспектора
/// (`ПРОПУСТИТЬ`, `ВСКРЫТЬ`, `ПРИНЯТЬ ВЗЯТКУ`), а также мигающий глаз «ВАС ПРОВЕРЯЮТ» в фазе щели досмотра.
///
/// АРХИТЕКТУРНЫЙ ИНВАРИАНТ (Раздел 2.4 и 11.2):
/// `OuterSceneView` принимает ТОЛЬКО `PublicProjection` и callbacks действий инспектора.
/// Он физически не имеет ссылки на `SecretState` или `RoundStateMachine.secretState`,
/// что исключает любую утечку содержимого чемодана или двойного дна на внешний экран.
public struct OuterSceneView: View {
    public let projection: PublicProjection
    public let stampHistory: [PassportStampRecord]
    public let captainQuoteRu: String
    public let isStandByReducedLuminance: Bool

    public let onActivateXRay: () -> Void
    public let onDecidePass: (Bool) -> Void
    public let onCommitOpenInspection: () -> Void
    public let onAdvanceNextRound: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var eyePulsePhase: Bool = false

    public init(
        projection: PublicProjection,
        stampHistory: [PassportStampRecord] = [],
        captainQuoteRu: String = "«Документы на стол. Честному пассажиру скрывать нечего.»",
        isStandByReducedLuminance: Bool = false,
        onActivateXRay: @escaping () -> Void = {},
        onDecidePass: @escaping (Bool) -> Void = { _ in },
        onCommitOpenInspection: @escaping () -> Void = {},
        onAdvanceNextRound: @escaping () -> Void = {}
    ) {
        self.projection = projection
        self.stampHistory = stampHistory
        self.captainQuoteRu = captainQuoteRu
        self.isStandByReducedLuminance = isStandByReducedLuminance
        self.onActivateXRay = onActivateXRay
        self.onDecidePass = onDecidePass
        self.onCommitOpenInspection = onCommitOpenInspection
        self.onAdvanceNextRound = onAdvanceNextRound
    }

    public var body: some View {
        ZStack {
            // Тёмно-оливковый/угольный фон паспорта с латунной рамкой
            Color(red: 0.08, green: 0.09, blue: 0.08)
                .ignoresSafeArea()

            if isStandByReducedLuminance {
                standByAlwaysOnView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        topCheckpointHeader
                        PassportPortraitView(
                            smugglerName: projection.smugglerName,
                            roundNumber: projection.roundNumber,
                            stampHistory: stampHistory
                        )

                        if projection.isBeingWatchedEyeVisible {
                            beingWatchedEyeBanner
                        }

                        publicDeclarationCard
                        nervometerAndXRayPanel
                        phaseControlsSection
                        captainVeraFooterQuote
                        scoreboardFooter
                    }
                    .padding(14)
                }
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    eyePulsePhase = true
                }
            }
        }
    }

    // MARK: - 1. Always On / StandBy компактный виджет (при отложенном на стол закрытом устройстве)

    private var standByAlwaysOnView: some View {
        VStack(spacing: 16) {
            Text("КПП «ЛАСТОЧКА» • ДЕЖУРНЫЙ РЕЖИМ")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.75))

            Text("РАУНД \(projection.roundNumber) • \(projection.phase.rawValue)")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 16) {
                ForEach(projection.players) { player in
                    VStack(spacing: 4) {
                        Text(player.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                        Text("\(player.coins) МОНЕТ")
                            .font(.system(size: 18, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                }
            }
        }
        .padding(20)
    }

    // MARK: - 2. Шапка КПП «Ласточка»

    private var topCheckpointHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("КПП «ЛАСТОЧКА» • ВНЕШНИЙ ЭКРАН ПАСПОРТА")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                Text("Инспектор: \(projection.inspectorName) • Угол петли: \(String(format: "%.1f°", projection.hingeAngleDegrees))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                Text("УЛИКИ: \(projection.inspectorClueTokens)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.2))
            )
        }
    }

    // MARK: - 3. Мигающий глаз «ВАС ПРОВЕРЯЮТ» (когда инспектор приоткрывает щель 3°–25°)

    private var beingWatchedEyeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                .font(.system(size: 22))
                .foregroundStyle(.red)
                .scaleEffect(eyePulsePhase ? 1.12 : 0.94)

            VStack(alignment: .leading, spacing: 2) {
                Text("ВАС ПРОВЕРЯЮТ! КРЫШКА ПРИОТКРЫТА (\(String(format: "%.1f°", projection.hingeAngleDegrees)))")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.red)
                Text("Держите каменное лицо: при угле >= 25° чемодан будет вскрыт официально.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.75), lineWidth: 1.5)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Внимание: инспектор приоткрыл щель досмотра. Вас проверяют.")
    }

    // MARK: - 4. Публичный бланк таможенной декларации

    private var publicDeclarationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ТАМОЖЕННАЯ ДЕКЛАРАЦИЯ")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(red: 0.18, green: 0.14, blue: 0.10))
                Spacer()
                Text(projection.phase == .packing ? "ЗАПОЛНЯЕТСЯ..." : "ОПЕЧАТАНО")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.72, green: 0.18, blue: 0.16).opacity(0.15))
                    )
                    .foregroundStyle(Color(red: 0.72, green: 0.18, blue: 0.16))
            }

            if let declaration = projection.declaration {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("КАТЕГОРИЯ ГРУЗА:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.black.opacity(0.6))
                        Text(declaration.declaredCategory.titleRu.uppercased())
                            .font(.system(size: 15, weight: .black, design: .serif))
                            .foregroundStyle(.black)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("КОЛИЧЕСТВО:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.black.opacity(0.6))
                        Text("\(declaration.declaredCount) МЕСТ(А)")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                    }
                }

                if declaration.bribeOfferedCoins > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "banknote.fill")
                            .foregroundStyle(Color(red: 0.62, green: 0.15, blue: 0.14))
                        Text("В ПАСПОРТ ВЛОЖЕНО «ЧАЕВЫХ»: +\(declaration.bribeOfferedCoins) МОНЕТ(Ы)")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(red: 0.62, green: 0.15, blue: 0.14))
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.62, green: 0.15, blue: 0.14).opacity(0.12))
                    )
                }
            } else {
                Text("Пассажир ещё укладывает чемодан и заполняет декларацию...")
                    .font(.system(size: 12))
                    .foregroundStyle(.black.opacity(0.7))
                    .padding(.vertical, 6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.93, green: 0.89, blue: 0.79))
        )
    }

    // MARK: - 5. Шкала «Нервомера» (с полосой погрешности ±8) и кнопка X-Ray на 5 секунд

    private var nervometerAndXRayPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ПРИБОР «НЕРВОМЕР-64» (НЕ ЯВЛЯЕТСЯ ДЕТЕКТОРОМ ЛЖИ)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                    Text("Режим: \(projection.nervometerModeLabelRu) • Доверительный интервал: \(Int(projection.nervometerConfidenceLow))–\(Int(projection.nervometerConfidenceHigh))%")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                Text("\(Int(projection.nervometerScore.rounded()))%")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(nervometerColor)
            }

            // Графическая шкала с полосой неопределённости
            GeometryReader { geo in
                let width = geo.size.width
                let lowX = width * CGFloat(projection.nervometerConfidenceLow / 100.0)
                let highX = width * CGFloat(projection.nervometerConfidenceHigh / 100.0)
                let scoreX = width * CGFloat(projection.nervometerScore / 100.0)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    // Доверительный интервал (uncertainty band)
                    Capsule()
                        .fill(nervometerColor.opacity(0.35))
                        .frame(width: max(8, highX - lowX), height: 12)
                        .offset(x: lowX)

                    // Стрелка-индикатор текущего индекса
                    Circle()
                        .fill(.white)
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, min(width - 14, scoreX - 7)))
                }
            }
            .frame(height: 14)

            // Кнопка рентгена X-Ray (1 жетон улики, 5 секунд) или силуэт рентгена
            if projection.xRayRevealedSilhouette != nil {
                HStack(spacing: 10) {
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("РЕНТГЕН-СНИМОК СЛУЧАЙНОГО ОТСЕКА:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan)
                        Text("Силуэт: \(projection.xRayRevealedSizeLabel ?? "неизвестно") • Взятка в этом раунде заблокирована")
                            .font(.system(size: 11))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.cyan.opacity(0.14)))
            } else if projection.phase == .decision || projection.phase == .slit {
                Button {
                    onActivateXRay()
                } label: {
                    HStack {
                        Image(systemName: "rays")
                        Text("ВКЛЮЧИТЬ РЕНТГЕН X-RAY НА 5 С (-1 УЛИКА)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        Spacer()
                        Text("Осталось: \(projection.inspectorClueTokens)")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(projection.inspectorClueTokens > 0
                                  ? Color.cyan.opacity(0.2)
                                  : Color.white.opacity(0.06))
                    )
                    .foregroundStyle(projection.inspectorClueTokens > 0 ? .cyan : .white.opacity(0.35))
                }
                .disabled(projection.inspectorClueTokens <= 0)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - 6. Кнопки решений Инспектора и штамп вердикта

    @ViewBuilder
    private var phaseControlsSection: some View {
        switch projection.phase {
        case .packing:
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Color(red: 0.78, green: 0.64, blue: 0.35))
                Text("ОЖИДАНИЕ: Пассажир укладывает багаж на внутреннем экране и захлопнет крышку (<= 3°).")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))

        case .sealed, .decision, .slit:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    // Кнопка ПРОПУСТИТЬ (без взятки)
                    Button {
                        onDecidePass(false)
                    } label: {
                        VStack(spacing: 2) {
                            Text("ПРОПУСТИТЬ")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                            Text("Без досмотра")
                                .font(.system(size: 10))
                                .opacity(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.8)))
                        .foregroundStyle(.black)
                    }

                    // Кнопка ВСКРЫТЬ ЧЕМОДАН (или открыть крышку >= 25°)
                    Button {
                        onCommitOpenInspection()
                    } label: {
                        VStack(spacing: 2) {
                            Text("ВСКРЫТЬ (>=25°)")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                            Text("Полный досмотр")
                                .font(.system(size: 10))
                                .opacity(0.85)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.85)))
                        .foregroundStyle(.white)
                    }
                }

                // Кнопка ПРИНЯТЬ ВЗЯТКУ И ПРОПУСТИТЬ (если предложена и рентген не включался)
                if let bribe = projection.declaration?.bribeOfferedCoins,
                   bribe > 0,
                   projection.xRayRevealedSilhouette == nil {
                    Button {
                        onDecidePass(true)
                    } label: {
                        HStack {
                            Image(systemName: "hand.Wave.fill")
                            Text("ПРИНЯТЬ «ЧАЕВЫЕ» (+\(bribe) МОН.) И ПРОПУСТИТЬ")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.78, green: 0.64, blue: 0.35))
                        )
                        .foregroundStyle(.black)
                    }
                }
            }

        case .committed, .resolution, .handover:
            verdictBannerView
        }
    }

    private var verdictBannerView: some View {
        let stamp = projection.verdictStampText ?? "ДОСМОТРЕНО"
        let isConfiscated = stamp == "КОНФИСКОВАНО"

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ШТАМП КПП: \(stamp)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isConfiscated ? Color.red : Color.green, lineWidth: 2)
                    )
                    .foregroundStyle(isConfiscated ? .red : .green)

                Spacer()

                if let outcome = projection.outcome {
                    Text("П:\(outcome.smugglerDeltaCoins >= 0 ? "+" : "")\(outcome.smugglerDeltaCoins) | И:\(outcome.inspectorDeltaCoins >= 0 ? "+" : "")\(outcome.inspectorDeltaCoins)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                }
            }

            if let summary = projection.outcome?.summaryRu {
                Text(summary)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Button {
                onAdvanceNextRound()
            } label: {
                HStack {
                    Text("СЛЕДУЮЩИЙ РАУНД (СМЕНА РОЛЕЙ)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.78, green: 0.64, blue: 0.35))
                )
                .foregroundStyle(.black)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.07))
        )
    }

    // MARK: - 7. Реплика капитана Веры Лисицыной и Табло счёта

    private var captainVeraFooterQuote: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.wave.2.fill")
                .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
            Text("Кап. Лисицына: \(captainQuoteRu)")
                .font(.system(size: 11, design: .serif))
                .italic()
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.35)))
    }

    private var scoreboardFooter: some View {
        HStack(spacing: 8) {
            ForEach(projection.players) { player in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.name)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("Улики: \(player.clueTokens)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Text("\(player.coins) м.")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
            }
        }
    }

    private var nervometerColor: Color {
        if projection.nervometerScore >= 72 {
            return .red
        } else if projection.nervometerScore >= 56 {
            return .orange
        } else {
            return .green
        }
    }
}
