import SwiftUI
import Charts
import SwiftData

// MARK: - CategoryExpensesDonutChart
/// Donut Chart con `SectorMark` para visualizar el desglose de gastos por categoría
struct CategoryExpensesDonutChart: View {
    let transactions: [Transaction]
    var periodTitle: String = "Este Mes"

    @State private var selectedSector: String? = nil

    private var totalExpenses: Double {
        categoryBreakdown.reduce(0.0) { $0 + $1.amount }
    }

    private var selectedItem: CategorySpendingItem? {
        guard let name = selectedSector else { return nil }
        return categoryBreakdown.first(where: { $0.name == name })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Gastos por Categoría")
                    .font(.kashBodyBold)
                Spacer()
                Text(periodTitle)
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }

            if categoryBreakdown.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 180)
                    .overlay {
                        Text("Sin gastos registrados en \(periodTitle)")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
                    }
            } else {
                HStack(spacing: 16) {
                    ZStack {
                        Chart(categoryBreakdown) { item in
                            SectorMark(
                                angle: .value("Monto", item.amount),
                                innerRadius: .ratio(selectedSector == item.name ? 0.54 : 0.62),
                                outerRadius: .ratio(selectedSector == item.name ? 1.06 : 1.0),
                                angularInset: 1.5
                            )
                            .foregroundStyle(Color(hex: item.colorHex))
                            .opacity(selectedSector == nil || selectedSector == item.name ? 1.0 : 0.45)
                        }
                        .chartAngleSelection(value: $selectedSector)
                        .frame(width: 140, height: 140)

                        if let sel = selectedItem, totalExpenses > 0 {
                            VStack(spacing: 1) {
                                Text("\(Int((sel.amount / totalExpenses) * 100))%")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text(sel.name)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 60)
                            }
                        }
                    }

                    // Ranking Top 5
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categoryBreakdown.prefix(5)) { item in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedSector == item.name {
                                        selectedSector = nil
                                    } else {
                                        selectedSector = item.name
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: item.colorHex))
                                        .frame(width: 8, height: 8)

                                    Text(item.name)
                                        .font(.kashCaption)
                                        .foregroundStyle(selectedSector == item.name ? Color(hex: "#2563EB") : .primary)
                                        .lineLimit(1)

                                    Spacer()

                                    PrivacyAwareText(
                                        amount: Decimal(item.amount),
                                        font: .kashCaptionBold
                                    )
                                }
                            }
                            .buttonStyle(.plain)
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
