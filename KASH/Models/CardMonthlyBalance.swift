import Foundation
import SwiftData

// MARK: - Saldo por Tarjeta en Corte Mensual
@Model
final class CardMonthlyBalance {
    @Attribute(.unique) var id: UUID
    var balanceUsed: Decimal               // Saldo deudor al corte
    var recordedAt: Date                   // Fecha y hora del registro
    var card: CreditCard?
    var monthlyRecord: MonthlyRecord?

    init(balanceUsed: Decimal, recordedAt: Date = Date(), card: CreditCard? = nil, monthlyRecord: MonthlyRecord? = nil) {
        self.id = UUID()
        self.balanceUsed = balanceUsed
        self.recordedAt = recordedAt
        self.card = card
        self.monthlyRecord = monthlyRecord
    }
}
