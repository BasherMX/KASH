import Foundation
import SwiftData

// MARK: - Tarjeta de Crédito (Pasivo Revolvente)
/// Representa una tarjeta de crédito. Según la Regla de Oro de KASH,
/// el límite o disponible jamás se considera dinero propio ni liquidez real.
@Model
final class CreditCard {
    @Attribute(.unique) var id: UUID
    var name: String                       // Ej. "PLATA CARD", "HEY BANCO", "NU"
    var institution: String                // Ej. "Plata", "Banregio", "Nu"
    var creditLimit: Decimal               // Límite asignado
    var cutoffDay: Int                     // Día de corte (1-31)
    var paymentDueDay: Int                 // Día límite de pago (1-31)
    var annualInterestRate: Double         // Tasa de interés anual (ej. 0.5900 = 59.0%)
    var recommendedStrategy: String        // Ej. "Categorías 5% Cashback", "Método Avalancha"
    var colorHex: String                   // Color personalizado en formato Hex (#RRGGBB)
    var iconName: String                   // SF Symbol representativo
    var isActive: Bool                     // Activa o Archivada
    var displayOrder: Int                  // Orden de visualización
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CardMonthlyBalance.card)
    var balances: [CardMonthlyBalance]? = []

    @Relationship(deleteRule: .cascade, inverse: \UpcomingPayment.card)
    var upcomingPayments: [UpcomingPayment]? = []

    @Relationship(deleteRule: .nullify, inverse: \Transaction.creditCard)
    var transactions: [Transaction]? = []

    init(
        name: String,
        institution: String,
        creditLimit: Decimal,
        cutoffDay: Int,
        paymentDueDay: Int,
        annualInterestRate: Double = 0.0,
        recommendedStrategy: String = "",
        colorHex: String = "#1E293B",
        iconName: String = "creditcard.fill",
        isActive: Bool = true,
        displayOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.institution = institution
        self.creditLimit = creditLimit
        self.cutoffDay = cutoffDay
        self.paymentDueDay = paymentDueDay
        self.annualInterestRate = annualInterestRate
        self.recommendedStrategy = recommendedStrategy
        self.colorHex = colorHex
        self.iconName = iconName
        self.isActive = isActive
        self.displayOrder = displayOrder
        self.createdAt = Date()
    }

    /// Balances ordenados cronológicamente por la fecha del corte (del más reciente al más antiguo)
    var sortedBalances: [CardMonthlyBalance] {
        guard let balances = balances, !balances.isEmpty else { return [] }
        return balances.sorted {
            let d0 = $0.monthlyRecord?.periodDate ?? $0.recordedAt
            let d1 = $1.monthlyRecord?.periodDate ?? $1.recordedAt
            return d0 > d1
        }
    }

    /// Saldo deudor vigente tomado del corte cronológico más reciente o gastos acumulados
    var currentBalance: Decimal {
        if let latest = sortedBalances.first {
            return latest.balanceUsed
        }
        let totalExpenses = (transactions ?? []).filter { $0.type == .expense }.reduce(0 as Decimal) { $0 + $1.amount }
        let totalPayments = (transactions ?? []).filter { $0.type == .cardPayment }.reduce(0 as Decimal) { $0 + $1.amount }
        return max(0 as Decimal, totalExpenses - totalPayments)
    }

    /// Capacidad de endeudamiento restante (NO es dinero disponible propio)
    var availableCredit: Decimal {
        max(0 as Decimal, creditLimit - currentBalance)
    }

    /// Ratio de utilización del crédito [0.0 - 1.0+]
    var utilizationPercentage: Double {
        guard creditLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: currentBalance / creditLimit).doubleValue
    }
}
