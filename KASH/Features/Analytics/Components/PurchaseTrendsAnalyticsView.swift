import SwiftUI
import Charts
import SwiftData

// MARK: - PurchaseTrendsAnalyticsView
/// Componente de análisis de hábitos de consumo, tendencias de compra y predicción probabilística de gastos
struct PurchaseTrendsAnalyticsView: View {
    let transactions: [Transaction]
    let creditCards: [CreditCard]
    let liquidityAccounts: [LiquidityAccount]
    var periodTitle: String = "Este Mes"

    @State private var selectedAccountScope: AccountScope = .all
    @State private var selectedDate: Date? = nil

    enum AccountScope: Hashable {
        case all
        case card(UUID, String)
        case account(UUID, String)

        var title: String {
            switch self {
            case .all: return "Todas las Cuentas"
            case .card(_, let name): return name
            case .account(_, let name): return name
            }
        }
    }

    private var scopedExpenses: [Transaction] {
        transactions.filter { tx in
            guard tx.type == .expense else { return false }
            switch selectedAccountScope {
            case .all:
                return true
            case .card(let id, _):
                return tx.creditCard?.id == id
            case .account(let id, _):
                return tx.liquidityAccount?.id == id
            }
        }
        .sorted { $0.transactionDate < $1.transactionDate }
    }

    // MARK: - Agrupación diaria para la gráfica
    private struct DailySpending: Identifiable {
        let id: String
        let date: Date
        let totalAmount: Double
        let count: Int
    }

    private var dailySpendings: [DailySpending] {
        let cal = Calendar.current
        var grouped: [Date: (amount: Double, count: Int)] = [:]
        for tx in scopedExpenses {
            let dayStart = cal.startOfDay(for: tx.transactionDate)
            let prev = grouped[dayStart] ?? (0.0, 0)
            grouped[dayStart] = (prev.amount + NSDecimalNumber(decimal: tx.amount).doubleValue, prev.count + 1)
        }

        return grouped.map { (date, val) in
            DailySpending(
                id: date.ISO8601Format(),
                date: date,
                totalAmount: val.amount,
                count: val.count
            )
        }
        .sorted { $0.date < $1.date }
    }

    private var selectedDailyItem: DailySpending? {
        guard let selectedDate = selectedDate else { return nil }
        return dailySpendings.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    // MARK: - Métricas de Hábitos de Consumo
    private var totalExpenseAmount: Decimal {
        scopedExpenses.reduce(0 as Decimal) { $0 + $1.amount }
    }

    private var purchaseCount: Int {
        scopedExpenses.count
    }

    /// Ticket promedio por compra
    private var averageTicket: Decimal {
        guard purchaseCount > 0 else { return 0 }
        return totalExpenseAmount / Decimal(purchaseCount)
    }

    /// Frecuencia promedio en días entre compras
    private var daysBetweenPurchases: Double {
        guard scopedExpenses.count >= 2,
              let firstDate = scopedExpenses.first?.transactionDate,
              let lastDate = scopedExpenses.last?.transactionDate else {
            return 0
        }
        let daysSpan = max(1, Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1)
        return Double(daysSpan) / Double(scopedExpenses.count - 1)
    }

    /// Gasto diario promedio en el periodo
    private var averageDailyExpense: Decimal {
        guard !scopedExpenses.isEmpty,
              let firstDate = scopedExpenses.first?.transactionDate,
              let lastDate = scopedExpenses.last?.transactionDate else {
            return totalExpenseAmount
        }
        let days = max(1, Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1)
        return totalExpenseAmount / Decimal(days)
    }

    /// Día de la semana con mayor volumen de compras
    private var peakDayOfWeekTitle: String {
        guard !scopedExpenses.isEmpty else { return "Sin datos" }
        let cal = Calendar.current
        var countsByWeekday: [Int: Double] = [:] // 1 = Domingo, 7 = Sábado
        for tx in scopedExpenses {
            let weekday = cal.component(.weekday, from: tx.transactionDate)
            countsByWeekday[weekday, default: 0] += NSDecimalNumber(decimal: tx.amount).doubleValue
        }

        guard let topWeekday = countsByWeekday.max(by: { $0.value < $1.value })?.key else {
            return "Sin datos"
        }

        switch topWeekday {
        case 1: return "Domingos"
        case 2: return "Lunes"
        case 3: return "Martes"
        case 4: return "Miércoles"
        case 5: return "Jueves"
        case 6: return "Viernes"
        case 7: return "Sábados"
        default: return "Variado"
        }
    }

    /// Predicción probabilística del próximo gasto (Fecha estimada, Categoría más frecuente y Concepto)
    private var nextPurchasePrediction: (date: Date, category: String, concept: String, estimatedAmount: Decimal)? {
        guard let lastTx = scopedExpenses.last else { return nil }
        let freq = max(1.0, daysBetweenPurchases > 0 ? daysBetweenPurchases : 2.0)
        let estDate = Calendar.current.date(byAdding: .day, value: Int(ceil(freq)), to: lastTx.transactionDate) ?? Date()

        // Categoría más recurrente
        var catCounts: [String: (count: Int, total: Decimal, sampleConcept: String)] = [:]
        for tx in scopedExpenses {
            let catName = tx.category?.name ?? "General"
            let prev = catCounts[catName] ?? (0, 0, tx.concept)
            catCounts[catName] = (prev.count + 1, prev.total + tx.amount, tx.concept)
        }

        if let top = catCounts.max(by: { $0.value.count < $1.value.count }) {
            let avgForCat = top.value.total / Decimal(max(1, top.value.count))
            return (estDate, top.key, top.value.sampleConcept, avgForCat)
        }

        return (estDate, lastTx.category?.name ?? "General", lastTx.concept, averageTicket)
    }

    /// Concentración en Días de Quincena (Días 1-5 y 15-20)
    private var paydayConcentrationPercentage: Double {
        guard totalExpenseAmount > 0 else { return 0 }
        let cal = Calendar.current
        let paydayExpenses = scopedExpenses.filter { tx in
            let day = cal.component(.day, from: tx.transactionDate)
            return (day >= 1 && day <= 5) || (day >= 15 && day <= 20)
        }
        .reduce(0 as Decimal) { $0 + $1.amount }

        return NSDecimalNumber(decimal: paydayExpenses / totalExpenseAmount).doubleValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header del Componente
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tendencias de Compra & Hábitos")
                        .font(.kashBodyBold)
                    Text("Patrones y predicciones basados en tus movimientos")
                        .font(.kashCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(periodTitle)
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }

            // Selector Horizontal de Alcance de Cuenta
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    accountScopeButton(.all)

                    ForEach(creditCards.filter { $0.isActive }) { card in
                        accountScopeButton(.card(card.id, card.name))
                    }

                    ForEach(liquidityAccounts.filter { $0.isActive && $0.accountType != .loan }) { acc in
                        accountScopeButton(.account(acc.id, acc.name))
                    }
                }
                .padding(.vertical, 2)
            }

            // Gráfica de Tendencia Diaria / Movimientos
            VStack(alignment: .leading, spacing: 8) {
                // Header de Inspección Fijo (evita desacomodar la gráfica al tocarla)
                HStack {
                    if let sel = selectedDailyItem {
                        HStack(spacing: 6) {
                            Text(sel.date.spanishShortDate)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "#2563EB"))
                            Text("•")
                                .foregroundStyle(.secondary)
                            PrivacyAwareText(
                                amount: Decimal(sel.totalAmount),
                                font: .kashCaptionBold,
                                foregroundColor: Color(hex: "#2563EB")
                            )
                            Text("(\(sel.count) \(sel.count == 1 ? "compra" : "compras"))")
                                .font(.kashMicro)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(scopedExpenses.isEmpty ? "Sin compras en este periodo" : "Toca o arrastra para ver compras del día")
                            .font(.kashMicro)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if selectedDailyItem != nil {
                        Button {
                            selectedDate = nil
                        } label: {
                            Text("Limpiar")
                                .font(.kashMicro)
                                .foregroundStyle(Color(hex: "#2563EB"))
                        }
                    }
                }
                .frame(height: 24, alignment: .leading)

                if dailySpendings.isEmpty {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.08))
                        .frame(height: 150)
                        .overlay {
                            Text("No hay compras registradas para este filtro.")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                        }
                } else {
                    Chart {
                        ForEach(dailySpendings) { item in
                            BarMark(
                                x: .value("Fecha", item.date, unit: .day),
                                y: .value("Gasto", item.totalAmount)
                            )
                            .foregroundStyle(Color(hex: "#2563EB").gradient)
                            .cornerRadius(4)
                        }

                        if let sel = selectedDailyItem {
                            RuleMark(x: .value("Selección", sel.date, unit: .day))
                                .foregroundStyle(Color(hex: "#2563EB").opacity(0.8))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .annotation(position: .top, overflowResolution: .init(x: .fit(to: .plot), y: .disabled)) {
                                    VStack(spacing: 1) {
                                        Text(sel.date.spanishShortDate)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text(Decimal(sel.totalAmount).formatted(.currency(code: "MXN")))
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "#1E293B"), in: RoundedRectangle(cornerRadius: 6))
                                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                                }
                        }
                    }
                    .chartXSelection(value: $selectedDate)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let val = value.as(Double.self) {
                                    Text("$\(Int(val))")
                                        .font(.system(size: 9))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let dateVal = value.as(Date.self) {
                                    Text(dateVal.spanishShortDate)
                                        .font(.system(size: 9))
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                }
            }

            Divider()

            // Tarjetas de Métricas de Hábitos Clave
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    HabitMetricBox(
                        title: "Frecuencia de Compra",
                        value: daysBetweenPurchases > 0 ? "Cada \(String(format: "%.1f", daysBetweenPurchases)) días" : "\(purchaseCount) compras",
                        caption: "\(purchaseCount) compras registradas",
                        icon: "clock.arrow.circlepath",
                        tintColor: Color(hex: "#2563EB")
                    )

                    HabitMetricBox(
                        title: "Ticket Promedio",
                        value: averageTicket.formatted(.currency(code: "MXN")),
                        caption: "Gasto medio por compra",
                        icon: "receipt.fill",
                        tintColor: Color(hex: "#10B981")
                    )
                }

                HStack(spacing: 10) {
                    HabitMetricBox(
                        title: "Gasto Diario Promedio",
                        value: averageDailyExpense.formatted(.currency(code: "MXN")),
                        caption: "Ritmo de salida al día",
                        icon: "calendar.badge.clock",
                        tintColor: Color(hex: "#F59E0B")
                    )

                    HabitMetricBox(
                        title: "Día con Más Compras",
                        value: peakDayOfWeekTitle,
                        caption: "Pico de consumo semanal",
                        icon: "flame.fill",
                        tintColor: Color(hex: "#EC4899")
                    )
                }
            }

            // Bloque de Predicción Inteligente de Próximo Gasto
            if let pred = nextPurchasePrediction, purchaseCount >= 2 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "#8B5CF6"))
                        Text("Predicción de Próximo Gasto")
                            .font(.kashCaptionBold)
                            .foregroundStyle(Color(hex: "#8B5CF6"))
                    }

                    Text("Según tu cadencia habitual de compra (\(String(format: "%.1f", daysBetweenPurchases)) días), es probable que realices tu próxima compra alrededor del **\(pred.date.spanishShortDate)**, frecuentemente en la categoría **\(pred.category)** (ej. *\(pred.concept)*) con un importe estimado de **\(pred.estimatedAmount.formatted(.currency(code: "MXN")))**.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#8B5CF6").opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }

            // Indicador de Concentración en Quincenas
            if totalExpenseAmount > 0 {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Impacto en Días de Quincena (1-5 y 15-20)")
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(Int(paydayConcentrationPercentage * 100))% de tus egresos ocurren durante las fechas de pago")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Int(paydayConcentrationPercentage * 100))%")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(paydayConcentrationPercentage > 0.60 ? Color(hex: "#EF4444") : Color(hex: "#10B981"))
                }
                .padding(10)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func accountScopeButton(_ scope: AccountScope) -> some View {
        let isSelected = selectedAccountScope == scope
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedAccountScope = scope
            }
        } label: {
            Text(scope.title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isSelected ? Color(hex: "#2563EB") : Color.secondary.opacity(0.12),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - HabitMetricBox
private struct HabitMetricBox: View {
    let title: String
    let value: String
    let caption: String
    let icon: String
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tintColor)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(caption)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}