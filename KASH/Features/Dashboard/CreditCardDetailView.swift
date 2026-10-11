import SwiftUI
import SwiftData
import Charts

// MARK: - CreditCardDetailView
/// Vista de detalle e historial financiero individual por tarjeta de crédito.
/// Incluye gráfica de avance de deuda a lo largo de los cortes, histórico de saldos y movimientos agrupados por año.
struct CreditCardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: CreditCard
    @Query(sort: \Transaction.transactionDate, order: .reverse) private var allTransactions: [Transaction]

    @State private var isEditSheetPresented = false
    @State private var isBatchLogSheetPresented = false
    @State private var transactionToEdit: Transaction? = nil

    private var historicalBalancesChronological: [CardMonthlyBalance] {
        card.sortedBalances.reversed()
    }

    private var cardTransactions: [Transaction] {
        allTransactions.filter { tx in
            tx.creditCard?.id == card.id || tx.destinationCard?.id == card.id
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 1. Tarjeta Visual Estilizada con Chip EMV y proporción ISO/IEC 7810 ID-1
                CardVisualHero(card: card)

                // 2. Métricas Clave y Buró
                CardMetricsGrid(card: card)

                // 3. Gráfica Histórica de Deuda de la Tarjeta
                CardDebtHistoryChart(balances: historicalBalancesChronological, colorHex: card.colorHex)

                // 4. Histórico de Cortes de Esta Tarjeta (Agrupado por año y colapsable, año actual descolapsado por defecto)
                CardHistoricalCutsSection(card: card)

                // 5. Movimientos con Esta Tarjeta (Agrupado por año y colapsable, año actual descolapsado por defecto)
                CardRecentTransactionsSection(
                    transactions: cardTransactions,
                    onSelectTransaction: { tx in
                        transactionToEdit = tx
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                PrivacyToggleButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditSheetPresented = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "#2563EB"))
                }
            }
        }
        .sheet(isPresented: $isEditSheetPresented) {
            CreditCardEditSheet(cardToEdit: card)
        }
        .sheet(isPresented: $isBatchLogSheetPresented) {
            BatchLogSheet()
        }
        .sheet(item: $transactionToEdit) { tx in
            QuickTransactionSheet(editingTransaction: tx)
        }
    }
}

// MARK: - CardVisualHero (Proporción Física Real ISO/IEC 7810 ID-1 1.586:1)
private struct CardVisualHero: View {
    let card: CreditCard

    private var lastFourDigitsSim: String {
        String(format: "%02d%02d", max(1, min(31, card.cutoffDay)), max(1, min(31, card.paymentDueDay)))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: card.colorHex),
                            Color(hex: card.colorHex).opacity(0.85),
                            Color.black.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Reflejos geométricos sutiles tipo tarjeta metálica
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 210, height: 210)
                    .offset(x: geo.size.width - 95, y: -60)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 170, height: 170)
                    .offset(x: geo.size.width - 55, y: geo.size.height - 85)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.institution.isEmpty ? "CRÉDITO" : card.institution.uppercased())
                            .font(.kashMicro)
                            .foregroundStyle(.white.opacity(0.8))
                            .tracking(1.2)
                        Text(card.name)
                            .font(.kashTitleMedium)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Text("\(Int(card.utilizationPercentage * 100))% uso")
                        .font(.kashMicro)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.18), in: Capsule())
                }

                Spacer(minLength: 10)

                // Chip EMV + Contactless + Numeración en Relieve
                HStack(spacing: 12) {
                    EMVCardChipView(width: 44, height: 32)

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    Text("••••  ••••  ••••  \(lastFourDigitsSim)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.92))
                        .tracking(1.1)
                }

                Spacer(minLength: 10)

                // Barra de progreso de uso de línea integrada
                GeometryReader { barGeo in
                    let ratio = min(1.0, max(0.0, card.utilizationPercentage))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)
                        Capsule()
                            .fill(
                                ratio < 0.30 ? Color(hex: "#6EE7B7") :
                                (ratio <= 0.50 ? Color(hex: "#FDE68A") : Color(hex: "#FCA5A5"))
                            )
                            .frame(width: max(6, barGeo.size.width * ratio), height: 4)
                    }
                }
                .frame(height: 5)
                .padding(.bottom, 8)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SALDO DEUDOR ACTUAL")
                            .font(.kashMicro)
                            .foregroundStyle(.white.opacity(0.75))
                        PrivacyAwareText(
                            amount: card.currentBalance,
                            font: .kashAmountLarge,
                            foregroundColor: .white
                        )
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Límite Total")
                                .font(.kashMicro)
                                .foregroundStyle(.white.opacity(0.75))
                            PrivacyAwareText(
                                amount: card.creditLimit,
                                font: .kashCaptionBold,
                                foregroundColor: .white.opacity(0.92)
                            )
                        }

                        // Emblema de red de pagos
                        HStack(spacing: -7) {
                            Circle()
                                .fill(Color.white.opacity(0.45))
                                .frame(width: 20, height: 20)
                            Circle()
                                .fill(Color.white.opacity(0.75))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            .padding(20)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.38), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .aspectRatio(1.586, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .shadow(color: Color(hex: card.colorHex).opacity(0.32), radius: 10, y: 5)
    }
}

// MARK: - CardMetricsGrid
private struct CardMetricsGrid: View {
    let card: CreditCard

    private var utilizationRatio: Double {
        card.utilizationPercentage
    }

    private var statusColor: Color {
        if utilizationRatio < 0.30 {
            return Color(hex: "#10B981")
        } else if utilizationRatio <= 0.50 {
            return Color(hex: "#F59E0B")
        } else {
            return Color(hex: "#EF4444")
        }
    }

    private var statusTitle: String {
        if utilizationRatio < 0.30 {
            return "Óptimo (< 30%)"
        } else if utilizationRatio <= 0.50 {
            return "Alerta (30%-50%)"
        } else {
            return "Crítico (> 50%)"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetricTile(
                    title: "Uso de Línea",
                    value: "\(Int(utilizationRatio * 100))%",
                    subtitle: statusTitle,
                    tintColor: statusColor
                )

                MetricTile(
                    title: "Línea Libre",
                    value: card.availableCredit.formatted(.currency(code: "MXN")),
                    subtitle: "Capacidad restante",
                    tintColor: Color(hex: "#2563EB")
                )
            }

            HStack(spacing: 12) {
                MetricTile(
                    title: "Día de Corte",
                    value: "\(card.cutoffDay) de cada mes",
                    subtitle: "Cierre de periodo",
                    tintColor: .secondary
                )

                MetricTile(
                    title: "Día Límite de Pago",
                    value: "\(card.paymentDueDay) de cada mes",
                    subtitle: "Evitar recargos",
                    tintColor: .secondary
                )
            }
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.kashMicro)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.kashBodyBold)
                .foregroundStyle(tintColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.kashMicro)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - CardDebtHistoryChart
private struct CardDebtHistoryChart: View {
    let balances: [CardMonthlyBalance]
    let colorHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Historial de Avance de Deuda")
                        .font(.kashBodyBold)
                    Text("Evolución saldo deudor en cada corte mensual")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if balances.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("Sin cortes registrados para esta tarjeta")
                        .font(.kashCaption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            } else if balances.count == 1 {
                VStack(spacing: 6) {
                    Text("Solo un corte registrado")
                        .font(.kashCaptionBold)
                    Text("Registra el próximo corte mensual para visualizar la línea de amortización.")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    PrivacyAwareText(
                        amount: balances.first?.balanceUsed ?? 0,
                        font: .kashAmountMedium,
                        foregroundColor: Color(hex: colorHex)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                Chart {
                    ForEach(balances) { b in
                        let date = b.monthlyRecord?.periodDate ?? b.recordedAt

                        AreaMark(
                            x: .value("Fecha", date),
                            y: .value("Saldo", b.balanceUsed)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: colorHex).opacity(0.35), Color(hex: colorHex).opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)

                        LineMark(
                            x: .value("Fecha", date),
                            y: .value("Saldo", b.balanceUsed)
                        )
                        .foregroundStyle(Color(hex: colorHex))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.monotone)

                        PointMark(
                            x: .value("Fecha", date),
                            y: .value("Saldo", b.balanceUsed)
                        )
                        .foregroundStyle(Color(hex: colorHex))
                        .symbolSize(36)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - CardHistoricalCutsSection (Agrupado por año y colapsable, año actual descolapsado por defecto)
private struct CardHistoricalCutsSection: View {
    let card: CreditCard

    @State private var expandedYears: Set<Int> = [Calendar.current.component(.year, from: Date())]

    private var balancesGroupedByYear: [(year: Int, balances: [CardMonthlyBalance])] {
        let allSorted = card.sortedBalances
        let grouped = Dictionary(grouping: allSorted) { b in
            let date = b.monthlyRecord?.periodDate ?? b.recordedAt
            return Calendar.current.component(.year, from: date)
        }
        return grouped.keys.sorted(by: >).map { year in
            let items = (grouped[year] ?? []).sorted {
                let d0 = $0.monthlyRecord?.periodDate ?? $0.recordedAt
                let d1 = $1.monthlyRecord?.periodDate ?? $1.recordedAt
                return d0 > d1
            }
            return (year: year, balances: items)
        }
    }

    private func chronologicalPreviousBalance(for balance: CardMonthlyBalance) -> CardMonthlyBalance? {
        let all = card.sortedBalances
        guard let idx = all.firstIndex(where: { $0.id == balance.id }) else { return nil }
        return idx + 1 < all.count ? all[idx + 1] : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Desglose Histórico de Cortes")
                    .font(.kashBodyBold)
                Spacer()
                Text("\(card.sortedBalances.count) registrados")
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
            }

            if card.sortedBalances.isEmpty {
                Text("Aún no has registrado cortes para esta tarjeta.")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(balancesGroupedByYear, id: \.year) { group in
                        let isYearExpanded = expandedYears.contains(group.year)
                        VStack(spacing: 8) {
                            // Cabecera colapsable por año
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                    if isYearExpanded {
                                        expandedYears.remove(group.year)
                                    } else {
                                        expandedYears.insert(group.year)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isYearExpanded ? "folder.fill" : "folder")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#2563EB"))

                                    Text("Año \(String(group.year))")
                                        .font(.kashCaptionBold)
                                        .foregroundStyle(.primary)

                                    if group.year == Calendar.current.component(.year, from: Date()) {
                                        Text("Actual")
                                            .font(.kashMicro)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(hex: "#2563EB").opacity(0.15), in: Capsule())
                                            .foregroundStyle(Color(hex: "#2563EB"))
                                    }

                                    Spacer()

                                    Text("\(group.balances.count) \(group.balances.count == 1 ? "corte" : "cortes")")
                                        .font(.kashMicro)
                                        .foregroundStyle(.secondary)

                                    Image(systemName: isYearExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)

                            if isYearExpanded {
                                VStack(spacing: 8) {
                                    ForEach(Array(group.balances.enumerated()), id: \.element.id) { idx, balance in
                                        let previousBalance = chronologicalPreviousBalance(for: balance)
                                        let date = balance.monthlyRecord?.periodDate ?? balance.recordedAt

                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(date.formatted(.dateTime.month(.wide).year()).capitalized)
                                                    .font(.kashCaptionBold)
                                                Text("Corte del mes")
                                                    .font(.kashMicro)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 2) {
                                                PrivacyAwareText(amount: balance.balanceUsed, font: .kashCaptionBold)

                                                if let prev = previousBalance {
                                                    let delta = balance.balanceUsed - prev.balanceUsed
                                                    let isDown = delta <= 0
                                                    HStack(spacing: 2) {
                                                        Image(systemName: isDown ? "arrow.down" : "arrow.up")
                                                            .font(.system(size: 10, weight: .bold))
                                                        Text(delta >= 0 ? "+\(delta.formatted(.currency(code: "MXN")))" : delta.formatted(.currency(code: "MXN")))
                                                            .font(.kashMicro)
                                                    }
                                                    .foregroundStyle(isDown ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)

                                        if idx < group.balances.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - CardRecentTransactionsSection (Agrupado por año y colapsable, año actual descolapsado por defecto)
private struct CardRecentTransactionsSection: View {
    let transactions: [Transaction]
    var onSelectTransaction: ((Transaction) -> Void)? = nil

    @State private var expandedYears: Set<Int> = [Calendar.current.component(.year, from: Date())]

    private var transactionsGroupedByYear: [(year: Int, items: [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { tx in
            Calendar.current.component(.year, from: tx.transactionDate)
        }
        return grouped.keys.sorted(by: >).map { year in
            let items = (grouped[year] ?? []).sorted { $0.transactionDate > $1.transactionDate }
            return (year: year, items: items)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Movimientos de la Tarjeta")
                    .font(.kashBodyBold)
                Spacer()
                Text("\(transactions.count) movimientos")
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
            }

            if transactions.isEmpty {
                Text("No hay compras ni abonos registrados con esta tarjeta.")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(transactionsGroupedByYear, id: \.year) { group in
                        let isYearExpanded = expandedYears.contains(group.year)
                        VStack(spacing: 8) {
                            // Cabecera colapsable por año
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                    if isYearExpanded {
                                        expandedYears.remove(group.year)
                                    } else {
                                        expandedYears.insert(group.year)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isYearExpanded ? "folder.fill" : "folder")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#2563EB"))

                                    Text("Año \(String(group.year))")
                                        .font(.kashCaptionBold)
                                        .foregroundStyle(.primary)

                                    if group.year == Calendar.current.component(.year, from: Date()) {
                                        Text("Actual")
                                            .font(.kashMicro)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(hex: "#2563EB").opacity(0.15), in: Capsule())
                                            .foregroundStyle(Color(hex: "#2563EB"))
                                    }

                                    Spacer()

                                    Text("\(group.items.count) \(group.items.count == 1 ? "movimiento" : "movimientos")")
                                        .font(.kashMicro)
                                        .foregroundStyle(.secondary)

                                    Image(systemName: isYearExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)

                            if isYearExpanded {
                                VStack(spacing: 8) {
                                    ForEach(Array(group.items.enumerated()), id: \.element.id) { idx, tx in
                                        Button {
                                            onSelectTransaction?(tx)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(tx.concept)
                                                        .font(.kashCaptionBold)
                                                        .foregroundStyle(.primary)
                                                    Text(tx.transactionDate.formatted(date: .abbreviated, time: .shortened))
                                                        .font(.kashMicro)
                                                        .foregroundStyle(.secondary)
                                                }

                                                Spacer()

                                                PrivacyAwareText(
                                                    amount: tx.amount,
                                                    font: .kashCaptionBold,
                                                    foregroundColor: tx.type == .income || tx.type == .cardPayment ? Color(hex: "#10B981") : Color(hex: "#EF4444")
                                                )

                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(.tertiary)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        if idx < group.items.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
