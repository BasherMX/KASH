import Foundation
import SwiftData

// MARK: - Transacciones Diarias & Transferencias / Pagos
@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var concept: String                    // Ej. "Super Chedraui", "Abono Plata Card"
    var amount: Decimal                    // Monto de la transacción
    var transactionDate: Date              // Fecha y hora
    var typeRaw: String                    // "expense", "income", "cardPayment", "transfer"
    var notes: String?
    var createdAt: Date

    @Relationship var creditCard: CreditCard?
    @Relationship var liquidityAccount: LiquidityAccount?
    @Relationship var destinationCard: CreditCard?     // Para pagos a TDC desde cuenta de débito
    @Relationship var category: TransactionCategory?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(
        concept: String,
        amount: Decimal,
        transactionDate: Date = Date(),
        type: TransactionType = .expense,
        notes: String? = nil,
        creditCard: CreditCard? = nil,
        liquidityAccount: LiquidityAccount? = nil,
        destinationCard: CreditCard? = nil,
        category: TransactionCategory? = nil
    ) {
        self.id = UUID()
        self.concept = concept
        self.amount = amount
        self.transactionDate = transactionDate
        self.typeRaw = type.rawValue
        self.notes = notes
        self.creditCard = creditCard
        self.liquidityAccount = liquidityAccount
        self.destinationCard = destinationCard
        self.category = category
        self.createdAt = Date()
    }
}
