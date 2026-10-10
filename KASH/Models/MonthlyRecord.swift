import Foundation
import SwiftData

// MARK: - Registro Mensual Consolidado
/// Agrupa los saldos deudores registrados de todas las tarjetas para un periodo mensual (ej. 1 de Octubre de 2026).
@Model
final class MonthlyRecord {
    @Attribute(.unique) var id: UUID
    var periodDate: Date                   // Primer día del mes (ej. 2026-10-01)
    var notes: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CardMonthlyBalance.monthlyRecord)
    var balances: [CardMonthlyBalance]? = []

    init(periodDate: Date, notes: String? = nil) {
        self.id = UUID()
        self.periodDate = periodDate
        self.notes = notes
        self.createdAt = Date()
    }

    /// Deuda total acumulada en todas las tarjetas durante este corte
    var totalDebt: Decimal {
        guard let balances = balances else { return 0 }
        return balances.reduce(0) { $0 + $1.balanceUsed }
    }
}
