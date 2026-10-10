import SwiftUI
import WidgetKit
import AppIntents

// MARK: - KASHSmallWidgetView (systemSmall 2x2)
struct KASHSmallWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#3B82F6"))

                Text("DEUDA TOTAL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Spacer()
            }

            Text(entry.totalDebt.formatted(.currency(code: "MXN")))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#10B981"))
                        .frame(width: 6, height: 6)

                    Text("\(entry.healthStatus) (\(Int(entry.utilizationRatio * 100))% uso)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }

                if let card = entry.nextUpcomingCard, let days = entry.nextUpcomingDays {
                    Text("Próx: \(card) (\(days)d)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - KASHMediumWidgetView (systemMedium 4x2 Interactivo)
struct KASHMediumWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header con métricas
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("💳 DEUDA TOTAL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    Text(entry.totalDebt.formatted(.currency(code: "MXN")))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    Text("% UTILIZACIÓN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text("\(Int(entry.utilizationRatio * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("SALUD BURÓ")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text("🟢 \(entry.healthStatus)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }

            Divider()

            // Botones de acción rápida con AppIntents (iOS 17+)
            HStack(spacing: 8) {
                Button(intent: QuickExpenseIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Gasto")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#EF4444"))
                }
                .buttonStyle(.plain)

                Button(intent: QuickIncomeIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Ingreso")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#10B981").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#10B981"))
                }
                .buttonStyle(.plain)

                Button(intent: PayCardIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                        Text("Pagar")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#2563EB"))
                }
                .buttonStyle(.plain)
            }
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}
