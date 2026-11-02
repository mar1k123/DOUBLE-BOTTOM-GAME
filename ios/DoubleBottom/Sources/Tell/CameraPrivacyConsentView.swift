import SwiftUI

/// Экран согласия и приватности перед использованием камеры для «Нервомера» и «Протокола вскрытия» (раздел 6.5 и 7.4).
/// Также содержит текст `NSCameraUsageDescription` и `NSPhotoLibraryAddUsageDescription` для `Info.plist`.
public struct CameraPrivacyConsentView: View {
    @Binding public var isCameraNervometerEnabled: Bool
    @Binding public var isPassengerProtocolConsentGranted: Bool
    @Binding public var isInspectorProtocolConsentGranted: Bool
    public var onConfirmAndStartCalibration: () -> Void

    public static let infoPlistCameraUsageDescriptionRu =
        "Камера используется только во время раунда для игрового прибора «Нервомер» (оценка мимики на устройстве в оперативной памяти) и по вашему отдельному согласию — для создания памятной карточки «Протокол вскрытия». Видео и биометрия никуда не передаются и не сохраняются на диск без вашего нажатия «Сохранить в Фото»."

    public static let infoPlistPhotoLibraryAddUsageDescriptionRu =
        "Доступ нужен только для сохранения готовой карточки «Протокол вскрытия» в вашу медиатеку по явному нажатию кнопки."

    public init(
        isCameraNervometerEnabled: Binding<Bool>,
        isPassengerProtocolConsentGranted: Binding<Bool>,
        isInspectorProtocolConsentGranted: Binding<Bool>,
        onConfirmAndStartCalibration: @escaping () -> Void
    ) {
        self._isCameraNervometerEnabled = isCameraNervometerEnabled
        self._isPassengerProtocolConsentGranted = isPassengerProtocolConsentGranted
        self._isInspectorProtocolConsentGranted = isInspectorProtocolConsentGranted
        self.onConfirmAndStartCalibration = onConfirmAndStartCalibration
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "hand.raised.shield.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ПРИВАТНОСТЬ И СОГЛАСИЕ • КПП «ЛАСТОЧКА»")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))
                    Text("Все вычисления выполняются локально на iPhone Duo в оперативной памяти")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Text(Self.infoPlistCameraUsageDescriptionRu)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.88))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))

            Toggle(isOn: $isCameraNervometerEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Оптический «Нервомер» (Vision 12–15 FPS)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Если выключить — игра автоматически перейдёт в режим «Тремор рук» по акселерометру без потери геймплея.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .tint(Color(red: 0.78, green: 0.64, blue: 0.35))

            Divider().background(Color.white.opacity(0.15))

            Text("СОГЛАСИЕ НА ФОТОКАРТОЧКУ «ПРОТОКОЛ ВСКРЫТИЯ» (ОПЦИОНАЛЬНО):")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.78, green: 0.64, blue: 0.35))

            Toggle("Пассажир согласен на снимок лица в Протоколе (иначе — силуэт со штампом «СЕКРЕТНО»)", isOn: $isPassengerProtocolConsentGranted)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .tint(Color(red: 0.78, green: 0.64, blue: 0.35))

            Toggle("Инспектор согласен на снимок лица в Протоколе (иначе — силуэт со штампом «СЕКРЕТНО»)", isOn: $isInspectorProtocolConsentGranted)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .tint(Color(red: 0.78, green: 0.64, blue: 0.35))

            Button {
                onConfirmAndStartCalibration()
            } label: {
                Text(isCameraNervometerEnabled
                     ? "НАЧАТЬ 6-СЕКУНДНУЮ КАЛИБРОВКУ «КАМЕННОЕ ЛИЦО»"
                     : "ПРОДОЛЖИТЬ В РЕЖИМЕ «ТРЕМОР РУК» (БЕЗ КАМЕРЫ)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.78, green: 0.64, blue: 0.35))
                    )
                    .foregroundStyle(.black)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.09, green: 0.08, blue: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.78, green: 0.64, blue: 0.35).opacity(0.45), lineWidth: 1)
                )
        )
    }
}
