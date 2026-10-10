import SwiftUI
import UIKit

// MARK: - BurnRateIndicatorView
/// Comparativa de Velocidad de Endeudamiento:
/// Gastos acumulados vs Abonos a Deuda realizados
struct BurnRateIndicatorView: View {
    let monthlyExpenses: Decimal
    let monthlyPayments: Decimal

    private var isAmortizing: Bool {
        monthlyPayments >= monthlyExpenses
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Velocidad de Endeudamiento")
                        .font(.kashBodyBold)
                    Text("Burn Rate vs. Payoff Rate")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                // Badge de Estado
                HStack(spacing: 4) {
                    Circle()
                        .fill(isAmortizing ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                        .frame(width: 8, height: 8)

                    Text(isAmortizing ? "Amortizando Deuda" : "Sobreendeudamiento")
                        .font(.kashMicro)
                        .foregroundStyle(isAmortizing ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isAmortizing ? Color(hex: "#10B981") : Color(hex: "#EF4444")).opacity(0.12), in: Capsule())
            }

            // Comparador visual de barras
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Gastos del mes (Nuevas deudas)")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        PrivacyAwareText(amount: monthlyExpenses, font: .kashCaptionBold)
                    }
                    ProgressView(value: NSDecimalNumber(decimal: monthlyExpenses).doubleValue, total: max(1, maxAmount))
                        .tint(Color(hex: "#EF4444"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Abonos y Pagos a Deuda")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        PrivacyAwareText(amount: monthlyPayments, font: .kashCaptionBold)
                    }
                    ProgressView(value: NSDecimalNumber(decimal: monthlyPayments).doubleValue, total: max(1, maxAmount))
                        .tint(Color(hex: "#10B981"))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var maxAmount: Double {
        let exp = NSDecimalNumber(decimal: monthlyExpenses).doubleValue
        let pay = NSDecimalNumber(decimal: monthlyPayments).doubleValue
        return max(exp, pay) * 1.15
    }
}
