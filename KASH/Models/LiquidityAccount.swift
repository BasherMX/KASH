import Foundation
import SwiftData

// MARK: - Frecuencia de Cuota en Préstamos
enum InstallmentFrequency: String, CaseIterable, Codable {
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case bimonthly = "bimonthly"

    var title: String {
        switch self {
        case .weekly: return "Semanal"
        case .biweekly: return "Quincenal"
        case .monthly: return "Mensual"
        case .bimonthly: return "Bimestral"
        }
    }
}

// MARK: - Tipo de Cuenta de Liquidez
enum AccountType: String, CaseIterable, Codable {
    case debit = "debit"                   // Cuenta de débito
    case cash = "cash"                     // Efectivo
    case savings = "savings"               // Cuenta de rendimiento / cajita
    case loan = "loan"                     // Préstamo personal / pasivo fijo

    var title: String {
        switch self {
        case .debit: return "Tarjeta de Débito"
        case .cash: return "Efectivo"
        case .savings: return "Ahorro / Rendimiento"
        case .loan: return "Préstamo / Crédito Personal"
        }
    }

    var defaultIcon: String {
        switch self {
        case .debit: return "creditcard"
        case .cash: return "banknote"
        case .savings: return "sparkles.rectangle.stack"
        case .loan: return "doc.text.below.ecg"
        }
    }
}

// MARK: - Cuenta de Liquidez / Activo (Débito, Efectivo, Ahorro, Préstamo)
/// Representa el dinero propio real del usuario. Solo el saldo de cuentas débito, efectivo y ahorros
/// compone la liquidez disponible real del usuario.
@Model
final class LiquidityAccount {
    @Attribute(.unique) var id: UUID
    var name: String                       // Ej. "BBVA Nómina", "Efectivo", "Cajita Nu"
    var institution: String                // Ej. "BBVA", "Efectivo", "Nu"
    var availableBalance: Decimal          // Saldo líquido positivo o saldo deudor si es préstamo
    var accountTypeRaw: String             // "debit", "cash", "savings", "loan"
    var colorHex: String
    var iconName: String
    var isActive: Bool
    var displayOrder: Int = 0
    var updatedAt: Date

    // Campos de Préstamo / Amortización
    var totalInstallments: Int = 0         // Plazo total en mensualidades / quincenas
    var paidInstallments: Int = 0          // Mensualidades / quincenas ya cubiertas
    var installmentAmount: Decimal = 0     // Monto de cada pago periódico
    var installmentFrequencyRaw: String = "monthly" // weekly, biweekly, monthly, bimonthly

    @Relationship(deleteRule: .nullify, inverse: \Transaction.liquidityAccount)
    var transactions: [Transaction]? = []

    var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .debit }
        set { accountTypeRaw = newValue.rawValue }
    }

    var installmentFrequency: InstallmentFrequency {
        get { InstallmentFrequency(rawValue: installmentFrequencyRaw) ?? .monthly }
        set { installmentFrequencyRaw = newValue.rawValue }
    }

    init(
        name: String,
        institution: String,
        availableBalance: Decimal,
        accountType: AccountType = .debit,
        colorHex: String = "#2563EB",
        iconName: String = "banknote.fill",
        isActive: Bool = true,
        displayOrder: Int = 0,
        totalInstallments: Int = 0,
        paidInstallments: Int = 0,
        installmentAmount: Decimal = 0,
        installmentFrequency: InstallmentFrequency = .monthly
    ) {
        self.id = UUID()
        self.name = name
        self.institution = institution
        self.availableBalance = availableBalance
        self.accountTypeRaw = accountType.rawValue
        self.colorHex = colorHex
        self.iconName = iconName
        self.isActive = isActive
        self.displayOrder = displayOrder
        self.totalInstallments = totalInstallments
        self.paidInstallments = paidInstallments
        self.installmentAmount = installmentAmount
        self.installmentFrequencyRaw = installmentFrequency.rawValue
        self.updatedAt = Date()
    }
}
