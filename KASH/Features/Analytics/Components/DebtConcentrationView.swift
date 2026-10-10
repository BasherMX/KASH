import SwiftUI

// MARK: - DebtConcentrationView
/// Detector de concentración de deuda en tarjetas con tasas abusivas (>80% anual)
/// y recomendaciones bajo el Método Avalancha
struct DebtConcentrationView: View {
    let cards: [CreditCard]

    private var toxicDebtCards: [CreditCard] {
        cards.filter { $0.annualInterestRate >= 0.80 && $0.currentBalance > 0 }
    }

    private var totalDebt: Decimal {
        cards.reduce(0) { $0 + $1.currentBalance }
    }

    private var toxicDebtTotal: Decimal {
        toxicDebtCards.reduce(0) { $0 + $1.currentBalance }
    }

    private var toxicRatio: Double {
        guard totalDebt > 0 else { return 0 }
        return NSDecimalNumber(decimal: toxicDebtTotal / totalDebt).doubleValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Concentración de Riesgo (Avalancha)")
                        .font(.kashBodyBold)
                    Text("Deuda en tarjetas con tasa de interés alta (>80%)")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                Text("\(Int(toxicRatio * 100))%")
                    .font(.kashBodyBold)
                    .foregroundStyle(toxicRatio > 0.3 ? Color(hex: "#EF4444") : Color(hex: "#10B981"))
            }

            if toxicDebtCards.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("¡Excelente! No tienes deuda concentrada en tarjetas con tasas de interés abusivas.")
                        .font(.kashCaption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(toxicDebtCards.sorted { $0.annualInterestRate > $1.annualInterestRate }) { card in
                        HStack {
                            Circle()
                                .fill(Color(hex: card.colorHex))
                                .frame(width: 8, height: 8)

                            Text(card.name)
                                .font(.kashCaptionBold)

                            Text("(\(Int(card.annualInterestRate * 100))% anual)")
                                .font(.kashMicro)
                                .foregroundStyle(Color(hex: "#EF4444"))

                            Spacer()

                            PrivacyAwareText(amount: card.currentBalance, font: .kashCaptionBold)
                        }
                    }

                    // Recomendación Avalancha
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(hex: "#F59E0B"))
                            .font(.system(size: 14))

                        Text("Estrategia Avalancha: Destina todos tus abonos extraordinarios a liquidar primero \(toxicDebtCards.first?.name ?? "tu tarjeta más cara") para detener el sangrado de intereses.")
                            .font(.kashMicro)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(Color(hex: "#F59E0B").opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
