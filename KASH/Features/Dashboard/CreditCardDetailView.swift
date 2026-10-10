import SwiftUI
import SwiftData
import Charts

// MARK: - CreditCardDetailView
/// Vista de detalle e historial financiero individual por tarjeta de crédito.
/// Incluye gráfica de avance de deuda a lo largo de los cortes, histórico de saldos y transacciones.
struct CreditCardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: CreditCard

    @State private var isEditSheetPresented = false
    @State private var isBatchLogSheetPresented = false

    private var historicalBalancesChronological: [CardMonthlyBalance] {
        card.sortedBalances.reversed()
    }

    private var cardTransactions: [Transaction] {
        (card.transactions ?? []).sorted { $0.transactionDate > $1.transactionDate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 1. Tarjeta Visual Estilizada
                CardVisualHero(card: card)

                // 2. Métricas Clave y Buró
                CardMetricsGrid(card: card)

                // 3. Gráfica Histórica de Deuda de la Tarjeta
                CardDebtHistoryChart(balances: historicalBalancesChronological, colorHex: card.colorHex)

                // 4. Histórico de Cortes de Esta Tarjeta
                CardHistoricalCutsSection(card: card)

                // 5. Movimientos Recientes con Esta Tarjeta
                CardRecentTransactionsSection(transactions: cardTransactions)
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
    }
}

// MARK: - CardVisualHero
private struct CardVisualHero: View {
    let card: CreditCard

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.institution.uppercased())
                        .font(.kashMicro)
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(1.0)
                    Text(card.name)
                        .font(.kashTitleMedium)
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: card.iconName.isEmpty ? "creditcard.fill" : card.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer().frame(height: 8)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saldo Deudor Actual")
                        .font(.kashMicro)
                        .foregroundStyle(.white.opacity(0.75))
                    PrivacyAwareText(
                        amount: card.currentBalance,
                        font: .kashAmountLarge,
                        foregroundColor: .white
                    )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Límite Total")
                        .font(.kashMicro)
                        .foregroundStyle(.white.opacity(0.75))
                    PrivacyAwareText(
                        amount: card.creditLimit,
                        font: .kashCaptionBold,
                        foregroundColor: .white.opacity(0.9)
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: card.colorHex), Color(hex: card.colorHex).opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: Color(hex: card.colorHex).opacity(0.3), radius: 10, y: 5)
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
                    value: "$\(card.availableCredit)",
                    subtitle: "Disponible para uso",
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

// MARK: - CardHistoricalCutsSection
private struct CardHistoricalCutsSection: View {
    let card: CreditCard

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
                VStack(spacing: 8) {
                    ForEach(Array(card.sortedBalances.enumerated()), id: \.element.id) { idx, balance in
                        let previousBalance = idx + 1 < card.sortedBalances.count ? card.sortedBalances[idx + 1] : nil
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
                        .padding(.vertical, 4)

                        if idx < card.sortedBalances.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - CardRecentTransactionsSection
private struct CardRecentTransactionsSection: View {
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Movimientos Recientes")
                    .font(.kashBodyBold)
                Spacer()
                Text("\(transactions.count)")
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
            }

            if transactions.isEmpty {
                Text("No hay compras ni abonos registrados con esta tarjeta.")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions.prefix(5)) { tx in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tx.concept)
                                    .font(.kashCaptionBold)
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
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
