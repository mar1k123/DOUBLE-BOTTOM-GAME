import SwiftUI
import Core
import Rules
import DuoHinge
import DuoDisplay

/// Двухэкранный отладочный стенд `DuoSimulatorView` (Раздел 5.5 п.2 и Раздел 11 `Debug/`).
/// На iPad, Mac или в симуляторе Xcode отображает одновременно оба виртуальных экрана iPhone Duo
/// с правильными пропорциями (внешний 466×678 pt портретный и внутренний 890×626 pt альбомный),
/// боковыми вырезами под вертикальный Dynamic Island, ползунком угла шарнира θ (0°…180°),
/// поддержкой клавиш `[` и `]`, жеста двумя пальцами и панелью телеметрии.
public struct DuoSimulatorView<InnerContent: View, OuterContent: View>: View {
    @ObservedObject private var viewModel: DuoSimulatorViewModel
    private let tuning: Tuning
    private let innerContent: () -> InnerContent
    private let outerContent: () -> OuterContent

    @State private var gestureStartAngle: Double? = nil

    public init(
        viewModel: DuoSimulatorViewModel,
        tuning: Tuning = .standard,
        @ViewBuilder innerContent: @escaping () -> InnerContent,
        @ViewBuilder outerContent: @escaping () -> OuterContent
    ) {
        self.viewModel = viewModel
        self.tuning = tuning
        self.innerContent = innerContent
        self.outerContent = outerContent
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Верхняя панель отладки: угол θ, фаза, зона, выбор провайдера и тепловой статус
            debugHeaderBar

            // Два виртуальных экрана iPhone Duo рядом с пропорциями 466:678 и 890:626
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // 1. Внешний экран (5.4" портретный, ~466×678 pt, compact width)
                    VStack(spacing: 6) {
                        Text("ВНЕШНИЙ ЭКРАН · 5.4″ (466×678 pt)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(red: 0.83, green: 0.66, blue: 0.33))

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color(red: 0.10, green: 0.14, blue: 0.17))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(Color(red: 0.43, green: 0.32, blue: 0.20), lineWidth: 2)
                                )

                            DuoSafeAreaContainer(screenTarget: .outerPortrait, tuning: tuning) {
                                outerContent()
                            }
                            .environment(\.horizontalSizeClass, .compact)

                            // Вертикальный Dynamic Island сбоку (слева)
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 10, height: 88)
                                .padding(.leading, 6)
                        }
                        .aspectRatio(tuning.outerScreenWidthPt / tuning.outerScreenHeightPt, contentMode: .fit)
                    }
                    .frame(maxWidth: geo.size.width * 0.32)

                    // Механический шарнир между экранами
                    hingeSpineIndicator

                    // 2. Внутренний экран (7.6" альбомный, ~890×626 pt, regular size classes)
                    VStack(spacing: 6) {
                        Text("ВНУТРЕННИЙ ЭКРАН · 7.6″ (890×626 pt)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(red: 0.83, green: 0.66, blue: 0.33))

                        ZStack(alignment: .trailing) {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(Color(red: 0.15, green: 0.09, blue: 0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                                        .stroke(Color(red: 0.43, green: 0.32, blue: 0.20), lineWidth: 2)
                                )

                            DuoSafeAreaContainer(screenTarget: .innerLandscape, tuning: tuning) {
                                innerContent()
                            }
                            .environment(\.horizontalSizeClass, .regular)
                            .environment(\.verticalSizeClass, .regular)

                            // Линия сгиба по центру (reservedRegions: .division)
                            Rectangle()
                                .fill(Color(red: 0.83, green: 0.66, blue: 0.33).opacity(0.18))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .position(x: (geo.size.width * 0.62) / 2, y: geo.size.height * 0.45)
                                .allowsHitTesting(false)

                            // Вертикальный Dynamic Island сбоку (справа)
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 10, height: 88)
                                .padding(.trailing, 6)
                        }
                        .aspectRatio(tuning.innerScreenWidthPt / tuning.innerScreenHeightPt, contentMode: .fit)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16)
        .background(Color(red: 0.05, green: 0.05, blue: 0.04))
        // Жест двумя пальцами / перетаскиванием для плавного изменения угла θ
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    let base = gestureStartAngle ?? viewModel.angleDegrees
                    if gestureStartAngle == nil {
                        gestureStartAngle = viewModel.angleDegrees
                    }
                    let delta = Double(value.translation.width) * 0.35
                    viewModel.setAngle(base + delta)
                }
                .onEnded { _ in
                    gestureStartAngle = nil
                }
        )
    }

    private var debugHeaderBar: some View {
        HStack(spacing: 14) {
            Text("ДВОЙНОЕ ДНО · СТЕНД DUO")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.83, green: 0.66, blue: 0.33))

            Text("ФАЗА: \(viewModel.phase.rawValue) · ЗОНА: \(viewModel.zoneDescription) · θ = \(Int(viewModel.angleDegrees.rounded()))°")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white)

            Slider(
                value: Binding(
                    get: { viewModel.angleDegrees },
                    set: { viewModel.setAngle($0) }
                ),
                in: 0...180
            )
            .frame(maxWidth: 180)
            .accessibilityLabel("Ползунок угла раскрытия шарнира iPhone Duo")

            // Кнопки быстрых положений шарнира и эмуляции клавиш [ и ]
            HStack(spacing: 6) {
                Button("[ -5°") { viewModel.stepAngle(by: -5) }
                    .keyboardShortcut("[", modifiers: [])
                Button("0° Закр") { viewModel.setAngle(0) }
                Button("6° Ур.1") { viewModel.setAngle(6) }
                Button("14° Ур.2") { viewModel.setAngle(14) }
                Button("21° Ур.3") { viewModel.setAngle(21) }
                Button("30° Вскр") { viewModel.setAngle(30) }
                Button("120° Откр") { viewModel.setAngle(120) }
                Button("] +5°") { viewModel.stepAngle(by: 5) }
                    .keyboardShortcut("]", modifiers: [])
            }
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .buttonStyle(.bordered)
            .tint(Color(red: 0.83, green: 0.66, blue: 0.33))

            Spacer()

            Text("THERMAL: \(viewModel.thermalLabel)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.gray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.09, green: 0.07, blue: 0.06))
        )
    }

    private var hingeSpineIndicator: some View {
        VStack {
            Circle().fill(Color.black).frame(width: 8, height: 8)
            Spacer()
            Text("\(Int(viewModel.angleDegrees.rounded()))°")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.black)
                .rotationEffect(.degrees(-90))
            Spacer()
            Circle().fill(Color.black).frame(width: 8, height: 8)
        }
        .padding(.vertical, 16)
        .frame(width: 16)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.24, green: 0.19, blue: 0.13),
                            Color(red: 0.83, green: 0.66, blue: 0.33),
                            Color(red: 0.24, green: 0.19, blue: 0.13)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }
}

@MainActor
public final class DuoSimulatorViewModel: ObservableObject {
    @Published public private(set) var angleDegrees: Double
    @Published public var phase: RoundPhase = .packing
    @Published public var zone: HingeZone = .open

    private let simulatedProvider: SimulatedHingeProvider

    public init(initialAngle: Double = 120.0) {
        self.angleDegrees = initialAngle
        self.simulatedProvider = SimulatedHingeProvider(initialAngle: initialAngle)
    }

    public var hingeProvider: HingeProviding {
        simulatedProvider
    }

    public func setAngle(_ newAngle: Double) {
        let clamped = min(180.0, max(0.0, newAngle))
        self.angleDegrees = clamped
        simulatedProvider.setAngle(clamped)
    }

    public func stepAngle(by delta: Double) {
        setAngle(angleDegrees + delta)
    }

    public var zoneDescription: String {
        switch zone {
        case .closed: return "CLOSED"
        case .slit(let level): return "SLIT_\(level.rawValue)"
        case .committed: return "COMMITTED"
        case .open: return "OPEN"
        }
    }

    public var thermalLabel: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return ".nominal"
        case .fair: return ".fair"
        case .serious: return ".serious"
        case .critical: return ".critical"
        @unknown default: return ".unknown"
        }
    }
}
