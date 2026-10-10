import Foundation
import SwiftData

// MARK: - Configuración de Usuario y Sistema
@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var monthlyIncome: Decimal             // Sueldo mensual neto
    var debtAllocationPercentage: Double   // % de sueldo para abono de deuda (0.0 - 1.0)
    var debtReminderDayOfMonth: Int        // Día del mes para recordatorio de corte
    var paymentReminderDaysBefore: Int     // Días de anticipación para avisar pagos
    var biometricLockMandatory: Bool       // Face ID / Touch ID Obligatorio
    var isPrivacyModeEnabled: Bool         // Ocultar saldos por defecto
    var terminalCommissionRate: Double     // Tasa terminal para simulador (ej. 0.0406 = 4.06%)
    var defaultCashbackRate: Double        // Cashback por defecto (ej. 0.10 = 10%)
    var lastBackupDate: Date?

    init(
        monthlyIncome: Decimal = 0,
        debtAllocationPercentage: Double = 0.60,
        debtReminderDayOfMonth: Int = 5,
        paymentReminderDaysBefore: Int = 3,
        biometricLockMandatory: Bool = true,
        isPrivacyModeEnabled: Bool = false,
        terminalCommissionRate: Double = 0.0406,
        defaultCashbackRate: Double = 0.10
    ) {
        self.id = UUID()
        self.monthlyIncome = monthlyIncome
        self.debtAllocationPercentage = debtAllocationPercentage
        self.debtReminderDayOfMonth = debtReminderDayOfMonth
        self.paymentReminderDaysBefore = paymentReminderDaysBefore
        self.biometricLockMandatory = biometricLockMandatory
        self.isPrivacyModeEnabled = isPrivacyModeEnabled
        self.terminalCommissionRate = terminalCommissionRate
        self.defaultCashbackRate = defaultCashbackRate
        self.lastBackupDate = nil
    }
}
