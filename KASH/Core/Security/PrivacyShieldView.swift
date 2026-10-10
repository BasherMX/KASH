import SwiftUI
import LocalAuthentication

// MARK: - PrivacyShieldView
/// Pantalla de protección y bloqueo que se sobrepone:
/// 1. Cuando la app requiere autenticación biométrica forzosa al iniciar.
/// 2. Cuando el usuario cambia al App Switcher (desenfoque para proteger datos financieros).
struct PrivacyShieldView: View {
    @ObservedObject var authManager = BiometricAuthManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Fondo con desenfoque de privacidad
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Color.black.opacity(colorScheme == .dark ? 0.75 : 0.4)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Logo e ícono de seguridad
                ZStack {
                    Circle()
                        .fill(Color(hex: "#2563EB").opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: iconForBiometry)
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(Color(hex: "#3B82F6"))
                }

                VStack(spacing: 8) {
                    Text("KASH")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Finanzas Personales Seguras")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                if let errorMsg = authManager.authErrorMessage {
                    Text(errorMsg)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(hex: "#EF4444"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Botón para reintentar desbloqueo
                Button {
                    Task {
                        _ = await authManager.authenticate()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: iconForBiometry)
                            .font(.system(size: 16, weight: .semibold))
                        Text(buttonTitleForBiometry)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#2563EB"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(hex: "#2563EB").opacity(0.4), radius: 10, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private var iconForBiometry: String {
        switch authManager.biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield.fill"
        }
    }

    private var buttonTitleForBiometry: String {
        switch authManager.biometryType {
        case .faceID:
            return "Desbloquear con Face ID"
        case .touchID:
            return "Desbloquear con Touch ID"
        default:
            return "Desbloquear KASH"
        }
    }
}
