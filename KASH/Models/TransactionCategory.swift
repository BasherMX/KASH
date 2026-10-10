import Foundation
import SwiftData

// MARK: - Tipo de Transacción
enum TransactionType: String, CaseIterable, Codable {
    case expense = "expense"               // Gasto/Compra diaria
    case income = "income"                 // Ingreso a cuenta de débito/efectivo
    case cardPayment = "cardPayment"       // Pago/Transferencia a Tarjeta de Crédito
    case transfer = "transfer"             // Traspaso entre cuentas de liquidez

    var title: String {
        switch self {
        case .expense: return "Gasto / Compra"
        case .income: return "Ingreso"
        case .cardPayment: return "Pago a Tarjeta"
        case .transfer: return "Transferencia"
        }
    }

    var icon: String {
        switch self {
        case .expense: return "arrow.up.right.circle.fill"
        case .income: return "arrow.down.left.circle.fill"
        case .cardPayment: return "creditcard.and.123"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

// MARK: - Categorías de Transacción
@Model
final class TransactionCategory {
    @Attribute(.unique) var id: UUID
    var name: String                       // Ej. "Supermercado", "Servicios", "Nómina"
    var iconName: String                   // SF Symbol
    var colorHex: String
    var categoryTypeRaw: String            // "expense", "income"
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]? = []

    var categoryType: TransactionType {
        get { TransactionType(rawValue: categoryTypeRaw) ?? .expense }
        set { categoryTypeRaw = newValue.rawValue }
    }

    init(name: String, iconName: String, colorHex: String, categoryType: TransactionType = .expense, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.categoryTypeRaw = categoryType.rawValue
        self.isDefault = isDefault
    }
}
