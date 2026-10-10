import Foundation
import LocalAuthentication
import Security

// MARK: - BiometricAuthManager
/// Administrador de autenticación biométrica (Face ID / Touch ID)
/// Cumple con las directrices de `swift-security-skill`:
/// - No asume éxito en simulador.
/// - Implementa evaluación de políticas biométricas de manera segura con fallback a código.
/// - Aísla operaciones para concurrencia segura.
@MainActor
final class BiometricAuthManager: ObservableObject {
    static let shared = BiometricAuthManager()

    @Published var isUnlocked: Bool = false
    @Published var biometryType: LABiometryType = .none
    @Published var authErrorMessage: String? = nil

    private init() {
        checkBiometryType()
    }

    /// Determina qué tipo de biometría está disponible en el hardware
    func checkBiometryType() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.biometryType = context.biometryType
        } else {
            self.biometryType = .none
        }
    }

    /// Solicita autenticación biométrica del usuario
    /// - Parameter reason: Motivo mostrado en el prompt del sistema
    func authenticate(reason: String = "Desbloquea KASH para acceder a tus finanzas") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"

        var error: NSError?
        // Intentar primero con biometría o fallback al código del dispositivo
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            if success {
                self.isUnlocked = true
                self.authErrorMessage = nil
                return true
            } else {
                self.isUnlocked = false
                self.authErrorMessage = "Autenticación fallida"
                return false
            }
        } catch let laError as LAError {
            self.isUnlocked = false
            switch laError.code {
            case .userCancel:
                self.authErrorMessage = "Autenticación cancelada"
            case .userFallback:
                // Permitir reintentar con código si el usuario lo solicita
                return await authenticateWithPasscode(reason: reason)
            case .biometryNotEnrolled:
                self.authErrorMessage = "No hay datos biométricos registrados"
            case .biometryLockout:
                self.authErrorMessage = "Biometría bloqueada temporalmente. Usa tu código."
                return await authenticateWithPasscode(reason: reason)
            default:
                self.authErrorMessage = laError.localizedDescription
            }
            return false
        } catch {
            self.isUnlocked = false
            self.authErrorMessage = error.localizedDescription
            return false
        }
    }

    /// Fallback a código del dispositivo
    private func authenticateWithPasscode(reason: String) async -> Bool {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                self.isUnlocked = true
                self.authErrorMessage = nil
                return true
            }
        } catch {
            self.authErrorMessage = error.localizedDescription
        }
        return false
    }

    /// Bloquea la aplicación (llamado al pasar a segundo plano)
    func lockApp() {
        self.isUnlocked = false
    }
}
