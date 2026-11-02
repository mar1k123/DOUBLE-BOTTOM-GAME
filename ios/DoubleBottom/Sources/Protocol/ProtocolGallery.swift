import SwiftUI

/// Галерея карточек «Протокол вскрытия» в конце матча (раздел 7.3 и 7.4).
/// Позволяет просмотреть каждый вскрытый раунд, сохранить карточку в медиатеку или поделиться через `ShareLink`.
/// При закрытии матча все несохранённые карточки удаляются из оперативной памяти.
public struct ProtocolGalleryView: View {
    @ObservedObject public var exportManager: ProtocolExportManager
    public var onFinishAndPurgeRAM: () -> Void

    public init(
        exportManager: ProtocolExportManager,
        onFinishAndPurgeRAM: @escaping () -> Void
    ) {
        self.exportManager = exportManager
        self.onFinishAndPurgeRAM = onFinishAndPurgeRAM
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("АРХИВ КПП «ЛАСТОЧКА» • ПРОТОКОЛЫ ВСКРЫТИЯ ЗА МАТЧ")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                    Text("Все снимки хранятся только в оперативной памяти и будут удалены после закрытия этого экрана.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                Button {
                    exportManager.purgeMatchGalleryFromRAM()
                    onFinishAndPurgeRAM()
                } label: {
                    Text("ЗАКРЫТЬ И ОЧИСТИТЬ ПАМЯТЬ")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.8)))
                        .foregroundStyle(.white)
                }
            }

            if let statusMessage = exportManager.lastSaveStatusMessageRu {
                Text(statusMessage)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
            }

            if exportManager.matchProtocolCards.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("В этом матче ни один чемодан не был вскрыт официально (угол >= 25°).")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 16) {
                        ForEach(exportManager.matchProtocolCards) { card in
                            protocolCardTile(card)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }

    private func protocolCardTile(_ card: InspectionProtocolCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ДЕЛО № 64-\(card.roundNumber) • \(card.stampTextRu)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(card.stampTextRu.contains("КОНФИСКОВАНО") ? Color.red : Color.green)
                Spacer()
                if card.falseBottomDiscovered {
                    Text("ДВОЙНОЕ ДНО!")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .foregroundStyle(.white)
                }
            }

            // Два портретных окна (с учётом раздельного согласия каждого игрока)
            HStack(spacing: 12) {
                portraitSlotView(
                    roleTitle: "ПАССАЖИР",
                    playerName: card.smugglerName,
                    consentGranted: card.smugglerConsentGranted
                )
                portraitSlotView(
                    roleTitle: "ИНСПЕКТОР",
                    playerName: card.inspectorName,
                    consentGranted: card.inspectorConsentGranted
                )
            }

            Text("Обнаружено при вскрытии: \(card.discoveredItemTitlesRu.joined(separator: ", "))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.85))
                .lineLimit(2)

            Text(card.coinSettlementSummaryRu)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.20, green: 0.16, blue: 0.12))

            HStack(spacing: 8) {
                Button {
                    Task {
                        _ = await exportManager.saveCardToPhotoLibrary(card)
                    }
                } label: {
                    Label("Сохранить в Фото", systemImage: "square.and.arrow.down")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.85)))
                        .foregroundStyle(Color(red: 0.93, green: 0.89, blue: 0.79))
                }

                ShareLink(
                    item: "Протокол КПП «Ласточка» (Раунд №\(card.roundNumber)): \(card.stampTextRu) — \(card.discoveredItemTitlesRu.joined(separator: ", ")). \(card.coinSettlementSummaryRu)"
                ) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.72, green: 0.18, blue: 0.16)))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(14)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.91, green: 0.86, blue: 0.75))
                .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
        )
    }

    private func portraitSlotView(
        roleTitle: String,
        playerName: String,
        consentGranted: Bool
    ) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.15, green: 0.14, blue: 0.13))
                    .frame(height: 110)

                if consentGranted {
                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.rectangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.85))
                        Text("СНИМОК NOIR")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.45))
                        Text("СЕКРЕТНО")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.red.opacity(0.85), lineWidth: 1.2)
                            )
                            .foregroundStyle(.red)
                    }
                }
            }
            Text("\(roleTitle): \(playerName)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
