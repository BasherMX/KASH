import SwiftUI

// MARK: - ZeroDebtEstimatorView
/// Modelo predictivo de amortización que calcula la fecha estimada de Deuda Cero ($0.00)
struct ZeroDebtEstimatorView: View {
    let totalDebt: Decimal
    let monthlyIncome: Decimal
    let allocationPercentage: Double

    private var monthlyPayoffCapacity: Decimal {
        monthlyIncome * Decimal(allocationPercentage)
    }

    private var estimatedMonthsToZero: Int? {
        guard monthlyPayoffCapacity > 0, totalDebt > 0 else { return nil }
        let monthsDouble = NSDecimalNumber(decimal: totalDebt / monthlyPayoffCapacity).doubleValue
        return Int(ceil(monthsDouble))
    }

    private var estimatedZeroDate: Date? {
        guard let months = estimatedMonthsToZero else { return nil }
        return Calendar.current.date(byAdding: .month, value: months, to: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Proyección Deuda Cero ($0.00)")
                        .font(.kashBodyBold)
                    Text("Simulador de amortización continua")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "#10B981"))
            }

            if totalDebt <= 0 {
                HStack(spacing: 8) {
                    Image(systemName: "party.popper.fill")
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("¡Felicidades! Actualmente no tienes deudas registradas. Tu patrimonio está libre de pasivos.")
                        .font(.kashCaption)
                        .foregroundStyle(.secondary)
                }
            } else if monthlyIncome <= 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Para calcular tu fecha estimada de liquidación total:")
                        .font(.kashCaption)
                        .foregroundStyle(.secondary)
                    Text("Configura tu ingreso mensual en Ajustes.")
                        .font(.kashCaptionBold)
                        .foregroundStyle(Color(hex: "#2563EB"))
                }
            } else if let months = estimatedMonthsToZero, let zeroDate = estimatedZeroDate {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fecha Estimada de Liquidación")
                                .font(.kashMicro)
                                .foregroundStyle(.secondary)
                            Text(zeroDate.formatted(.dateTime.month(.wide).year()))
                                .font(.kashAmountMedium)
                                .foregroundStyle(Color(hex: "#10B981"))
                                .textCase(.capitalize)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Tiempo Restante")
                                .font(.kashMicro)
                                .foregroundStyle(.secondary)
                            Text("\(months) \(months == 1 ? "mes" : "meses")")
                                .font(.kashAmountMedium)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Capacidad mensual de abono:")
                            .font(.kashMicro)
                            .foregroundStyle(.secondary)
                        Spacer()
                        PrivacyAwareText(amount: monthlyPayoffCapacity, font: .kashCaptionBold)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
