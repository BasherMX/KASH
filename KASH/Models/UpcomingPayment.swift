import Foundation
import SwiftData

// MARK: - Estado de Pago
enum PaymentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case paid = "paid"
    case partial = "partial"

    var title: String {
        switch self {
        case .pending: return "Pendiente"
        case .paid: return "Pagado"
        case .partial: return "Parcial"
        }
    }

    var badgeColorHex: String {
        switch self {
        case .pending: return "#F59E0B"  // Amber
        case .paid: return "#10B981"     // Emerald
        case .partial: return "#3B82F6"  // Blue
        }
    }
}

// MARK: - Próximo Pago del Mes
@Model
final class UpcomingPayment {
    @Attribute(.unique) var id: UUID
    var concept: String
    var dueDate: Date
    var minimumPayment: Decimal
    var fullPaymentNoInterest: Decimal
    var actualAmountToPay: Decimal
    var statusRaw: String                  // "pending", "paid", "partial"
    var paymentDate: Date?
    var card: CreditCard?

    var status: PaymentStatus {
        get { PaymentStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        concept: String,
        dueDate: Date,
        minimumPayment: Decimal = 0,
        fullPaymentNoInterest: Decimal = 0,
        actualAmountToPay: Decimal = 0,
        status: PaymentStatus = .pending,
        card: CreditCard? = nil
    ) {
        self.id = UUID()
        self.concept = concept
        self.dueDate = dueDate
        self.minimumPayment = minimumPayment
        self.fullPaymentNoInterest = fullPaymentNoInterest
        self.actualAmountToPay = actualAmountToPay
        self.statusRaw = status.rawValue
        self.card = card
    }
}
