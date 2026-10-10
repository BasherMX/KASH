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

    @Published var isUnlocked: Bool = true
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
        } catch {
            self.isUnlocked = false
            self.authErrorMessage = error.localizedDescription
            return false
        }
    }

    /// Bloquea la aplicación (llamado al pasar a segundo plano)
    func lockApp() {
        self.isUnlocked = false
    }
}
