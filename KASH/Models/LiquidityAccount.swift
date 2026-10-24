import Foundation
import SwiftData

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
    var updatedAt: Date

    // Campos de Préstamo / Amortización
    var totalInstallments: Int = 0         // Plazo total en mensualidades / quincenas
    var paidInstallments: Int = 0          // Mensualidades / quincenas ya cubiertas
    var installmentAmount: Decimal = 0     // Monto de cada pago periódico

    @Relationship(deleteRule: .nullify, inverse: \Transaction.liquidityAccount)
    var transactions: [Transaction]? = []

    var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .debit }
        set { accountTypeRaw = newValue.rawValue }
    }

    init(
        name: String,
        institution: String,
        availableBalance: Decimal,
        accountType: AccountType = .debit,
        colorHex: String = "#2563EB",
        iconName: String = "banknote.fill",
        isActive: Bool = true,
        totalInstallments: Int = 0,
        paidInstallments: Int = 0,
        installmentAmount: Decimal = 0
    ) {
        self.id = UUID()
        self.name = name
        self.institution = institution
        self.availableBalance = availableBalance
        self.accountTypeRaw = accountType.rawValue
        self.colorHex = colorHex
        self.iconName = iconName
        self.isActive = isActive
        self.totalInstallments = totalInstallments
        self.paidInstallments = paidInstallments
        self.installmentAmount = installmentAmount
        self.updatedAt = Date()
    }
}
