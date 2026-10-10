import SwiftUI
import Charts
import SwiftData

// MARK: - CategoryExpensesDonutChart
/// Donut Chart con `SectorMark` para visualizar el desglose de gastos por categoría
struct CategoryExpensesDonutChart: View {
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gastos por Categoría")
                .font(.kashBodyBold)

            if categoryBreakdown.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 180)
                    .overlay {
                        Text("Sin gastos registrados este mes")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
                    }
            } else {
                HStack(spacing: 20) {
                    Chart(categoryBreakdown) { item in
                        SectorMark(
                            angle: .value("Monto", item.amount),
                            innerRadius: .ratio(0.60),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color(hex: item.colorHex))
                    }
                    .frame(width: 140, height: 140)

                    // Ranking Top 4
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categoryBreakdown.prefix(4)) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: item.colorHex))
                                    .frame(width: 8, height: 8)

                                Text(item.name)
                                    .font(.kashCaption)
                                    .lineLimit(1)

                                Spacer()

                                Text("$\(Int(item.amount))")
                                    .font(.kashCaptionBold)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var categoryBreakdown: [CategorySpendingItem] {
        let expenses = transactions.filter { $0.type == .expense }
        var dict: [String: (amount: Double, color: String)] = [:]

        for exp in expenses {
            let catName = exp.category?.name ?? "Otros"
            let colorHex = exp.category?.colorHex ?? "#64748B"
            let val = NSDecimalNumber(decimal: exp.amount).doubleValue

            if let cur = dict[catName] {
                dict[catName] = (amount: cur.amount + val, color: colorHex)
            } else {
                dict[catName] = (amount: val, color: colorHex)
            }
        }

        return dict.map { key, val in
            CategorySpendingItem(name: key, amount: val.amount, colorHex: val.color)
        }.sorted { $0.amount > $1.amount }
    }
}

struct CategorySpendingItem: Identifiable {
    var id: String { name }
    let name: String
    let amount: Double
    let colorHex: String
}
