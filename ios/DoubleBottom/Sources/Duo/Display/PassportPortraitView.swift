import SwiftUI

/// Процедурный генератор паспортного портрета и штампов на обложке КПП «Ласточка» (раздел 8.2).
/// Создаёт не менее 12 детерминированных комбинаций силуэта, головного убора, очков и шарфа
/// по индексу раунда и имени контрабандиста — полностью в коде (`Canvas` + `Path`), без внешних PNG.
/// Помечено: ЗАМЕНИТЬ АРТОМ (при подключении авторских иллюстраций).
public struct PassportPortraitView: View {
    public let smugglerName: String
    public let roundNumber: Int
    public let stampHistory: [PassportStampRecord]

    public init(
        smugglerName: String,
        roundNumber: Int,
        stampHistory: [PassportStampRecord] = []
    ) {
        self.smugglerName = smugglerName
        self.roundNumber = roundNumber
        self.stampHistory = stampHistory
    }

    private var traitHash: Int {
        let scalarSum = smugglerName.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return abs(scalarSum + roundNumber * 17)
    }

    private var hatStyle: Int { traitHash % 3 }        // 0: фетровая шляпа, 1: берет, 2: фуражка
    private var glassesStyle: Int { (traitHash / 3) % 2 } // 0: круглые очки, 1: без очков / пенсне
    private var scarfStyle: Int { (traitHash / 6) % 2 }   // 0: высокий воротник плаща, 1: клетчатый шарф

    public var body: some View {
        HStack(spacing: 12) {
            // 1. Векторный портрет в рамке с водяным знаком Альтавии/Нордмарка
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.88, green: 0.83, blue: 0.72))

                Canvas { context, size in
                    let w = size.width
                    let h = size.height

                    // Гильоширная сетка фона паспорта
                    for step in stride(from: 0.0, through: h, by: 6.0) {
                        var line = Path()
                        line.move(to: CGPoint(x: 0, y: step))
                        line.addLine(to: CGPoint(x: w, y: step))
                        context.stroke(line, with: .color(.black.opacity(0.07)), lineWidth: 0.6)
                    }

                    // Плечи и воротник плаща / шарф
                    var coat = Path()
                    coat.move(to: CGPoint(x: w * 0.12, y: h))
                    coat.addQuadCurve(
                        to: CGPoint(x: w * 0.88, y: h),
                        control: CGPoint(x: w * 0.50, y: h * 0.58)
                    )
                    coat.closeSubpath()
                    context.fill(coat, with: .color(Color(red: 0.16, green: 0.14, blue: 0.12)))

                    if scarfStyle == 1 {
                        let scarfRect = CGRect(x: w * 0.30, y: h * 0.66, width: w * 0.40, height: h * 0.14)
                        context.fill(
                            Path(roundedRect: scarfRect, cornerRadius: 4),
                            with: .color(Color(red: 0.52, green: 0.18, blue: 0.16))
                        )
                    }

                    // Голова и шея
                    let headRect = CGRect(x: w * 0.31, y: h * 0.30, width: w * 0.38, height: h * 0.40)
                    context.fill(
                        Path(ellipseIn: headRect),
                        with: .color(Color(red: 0.24, green: 0.20, blue: 0.17))
                    )

                    // Очки
                    if glassesStyle == 0 {
                        let leftEye = CGRect(x: w * 0.35, y: h * 0.44, width: w * 0.12, height: w * 0.12)
                        let rightEye = CGRect(x: w * 0.53, y: h * 0.44, width: w * 0.12, height: w * 0.12)
                        context.stroke(Path(ellipseIn: leftEye), with: .color(Color(red: 0.85, green: 0.72, blue: 0.42)), lineWidth: 1.6)
                        context.stroke(Path(ellipseIn: rightEye), with: .color(Color(red: 0.85, green: 0.72, blue: 0.42)), lineWidth: 1.6)
                    }

                    // Головной убор (3 варианта -> 3 * 2 * 2 = 12 комбинаций)
                    var hat = Path()
                    if hatStyle == 0 {
                        // Нуарная фетровая шляпа
                        hat.addRect(CGRect(x: w * 0.18, y: h * 0.28, width: w * 0.64, height: h * 0.06))
                        hat.addRoundedRect(in: CGRect(x: w * 0.28, y: h * 0.14, width: w * 0.44, height: h * 0.16), cornerSize: CGSize(width: 6, height: 6))
                    } else if hatStyle == 1 {
                        // Берет Альтавии
                        hat.addEllipse(in: CGRect(x: w * 0.24, y: h * 0.16, width: w * 0.52, height: h * 0.18))
                    } else {
                        // Дорожная фуражка Нордмарка
                        hat.addRect(CGRect(x: w * 0.25, y: h * 0.26, width: w * 0.50, height: h * 0.06))
                        hat.addRect(CGRect(x: w * 0.28, y: h * 0.15, width: w * 0.44, height: h * 0.12))
                    }
                    context.fill(hat, with: .color(Color(red: 0.11, green: 0.10, blue: 0.09)))
                }

                // Сургучная печать в углу фотографии
                Circle()
                    .strokeBorder(Color(red: 0.68, green: 0.16, blue: 0.14).opacity(0.65), lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("КПП")
                            .font(.system(size: 6, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(red: 0.68, green: 0.16, blue: 0.14).opacity(0.75))
                    )
                    .offset(x: 24, y: 28)
            }
            .frame(width: 78, height: 92)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
            )
            .accessibilityHidden(true)

            // 2. Паспортные реквизиты и накопленные штампы на обложке
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("ПАСПОРТ ТРАНЗИТА • № 64-0\(roundNumber)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                    Spacer()
                    Text("АЛЬТАВИЯ ⇄ НОРДМАРК")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Text(smugglerName.uppercased())
                    .font(.system(size: 16, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("Пункт перехода: КПП «Ласточка» • Досмотр ведёт кап. В. Лисицына")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)

                // Лента накопленных штампов прошлых раундов
                if stampHistory.isEmpty {
                    Text("ШТАМПОВ В ПАСПОРТЕ ПОКА НЕТ")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 2)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(stampHistory) { stamp in
                                Text("Р\(stamp.roundNumber): \(stamp.stampTitleRu)")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(stampColor(for: stamp.stampTitleRu), lineWidth: 1.2)
                                    )
                                    .foregroundStyle(stampColor(for: stamp.stampTitleRu))
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func stampColor(for title: String) -> Color {
        switch title {
        case "КОНФИСКОВАНО":
            return .red
        case "ДОСМОТРЕНО":
            return .green
        default:
            return Color(red: 0.78, green: 0.64, blue: 0.35)
        }
    }
}

/// Запись об одном поставленном штампе на обложке паспорта за матч.
public struct PassportStampRecord: Identifiable, Equatable, Sendable {
    public let id: String
    public let roundNumber: Int
    public let stampTitleRu: String

    public init(roundNumber: Int, stampTitleRu: String) {
        self.id = "stamp_\(roundNumber)_\(stampTitleRu)"
        self.roundNumber = roundNumber
        self.stampTitleRu = stampTitleRu
    }
}
