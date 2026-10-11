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
    var terminalCommissionRate: Double     // Tasa terminal legacy para compatibilidad de respaldo
    var lastBackupDate: Date?

    init(
        monthlyIncome: Decimal = 0,
        debtAllocationPercentage: Double = 0.60,
        debtReminderDayOfMonth: Int = 5,
        paymentReminderDaysBefore: Int = 3,
        biometricLockMandatory: Bool = false,
        isPrivacyModeEnabled: Bool = false,
        terminalCommissionRate: Double = 0.0406
    ) {
        self.id = UUID()
        self.monthlyIncome = monthlyIncome
        self.debtAllocationPercentage = debtAllocationPercentage
        self.debtReminderDayOfMonth = debtReminderDayOfMonth
        self.paymentReminderDaysBefore = paymentReminderDaysBefore
        self.biometricLockMandatory = biometricLockMandatory
        self.isPrivacyModeEnabled = isPrivacyModeEnabled
        self.terminalCommissionRate = terminalCommissionRate
        self.lastBackupDate = nil
    }

    // MARK: - Instancia Única Canónica en SwiftData
    private static let cachedIncomeKey = "kash_cached_monthly_income"

    /// Obtiene y desduplica la instancia canónica de `UserSettings` dentro del `ModelContext`
    @MainActor
    @discardableResult
    static func shared(in context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        let all = (try? context.fetch(descriptor)) ?? []

        if let primary = all.first {
            // Si existían registros duplicados de compilaciones previas, consolidar el ingreso mayor/no-cero y eliminar duplicados
            if all.count > 1 {
                for extra in all.dropFirst() {
                    if primary.monthlyIncome == 0 && extra.monthlyIncome > 0 {
                        primary.monthlyIncome = extra.monthlyIncome
                    }
                    context.delete(extra)
                }
                try? context.save()
            }
            if primary.monthlyIncome == 0,
               let cachedStr = UserDefaults.standard.string(forKey: cachedIncomeKey),
               let cachedVal = Decimal(string: cachedStr, locale: Locale(identifier: "en_US_POSIX")),
               cachedVal > 0 {
                primary.monthlyIncome = cachedVal
                try? context.save()
            }
            return primary
        }

        let initialIncome: Decimal
        if let cachedStr = UserDefaults.standard.string(forKey: cachedIncomeKey),
           let cachedVal = Decimal(string: cachedStr, locale: Locale(identifier: "en_US_POSIX")) {
            initialIncome = cachedVal
        } else {
            initialIncome = 0
        }

        let created = UserSettings(monthlyIncome: initialIncome)
        context.insert(created)
        try? context.save()
        return created
    }

    @MainActor
    static func updateMonthlyIncome(_ income: Decimal, in context: ModelContext) {
        let settings = shared(in: context)
        settings.monthlyIncome = income
        UserDefaults.standard.set("\(income)", forKey: cachedIncomeKey)
        try? context.save()
    }

    @MainActor
    static func clearCachedMonthlyIncome() {
        UserDefaults.standard.removeObject(forKey: cachedIncomeKey)
    }
}
