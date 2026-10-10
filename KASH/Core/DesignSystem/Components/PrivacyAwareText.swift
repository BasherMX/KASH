import SwiftUI

// MARK: - PrivacyAwareText
/// Componente para renderizar cifras financieras respetando el modo de privacidad del usuario.
/// Si `isPrivacyModeEnabled` es true, muestra `$ ••••••` para evitar miradas indiscretas.
struct PrivacyAwareText: View {
    let amount: Decimal
    var formatStyle: FloatingPointFormatStyle<Double>.Currency = .currency(code: "MXN")
    var font: Font = .kashAmountMedium
    var foregroundColor: Color? = nil

    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled: Bool = false

    var body: some View {
        Group {
            if isPrivacyModeEnabled {
                Text("$ ••••••")
            } else {
                Text(amount.formatted(.currency(code: "MXN")))
            }
        }
        .font(font)
        .foregroundStyle(foregroundColor ?? .primary)
        .contentTransition(.numericText())
    }
}

// MARK: - Botón Rápido de Privacidad (Ojo 👁️)
struct PrivacyToggleButton: View {
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled: Bool = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPrivacyModeEnabled.toggle()
            }
        } label: {
            Image(systemName: isPrivacyModeEnabled ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isPrivacyModeEnabled ? Color.amber : Color.secondary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel(isPrivacyModeEnabled ? "Mostrar saldos" : "Ocultar saldos")
    }
}

private extension Color {
    static let amber = Color(hex: "#F59E0B")
}
