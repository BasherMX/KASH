import SwiftUI
import UIKit
import SwiftData
import WidgetKit

// MARK: - DashboardView
/// Vista principal de KASH que aplica estrictamente la Regla de Oro:
/// "El crédito disponible en una TDC NO es dinero propio."
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Query private var creditCards: [CreditCard]
    @Query private var liquidityAccounts: [LiquidityAccount]
    @Query private var upcomingPayments: [UpcomingPayment]
    @Query private var monthlyRecords: [MonthlyRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Tarjeta Héroe de Liquidez Real y Regla de Oro
                    RealLiquidityHeroCard(
                        realLiquidity: realLiquidityTotal,
                        totalDebt: totalDebtCurrent,
                        netWorth: netWorth
                    )

                    // 2. Acciones Rápidas
                    QuickActionButtonsRow()

                    // Banner de inicio rápido si no hay cuentas configuradas aún
                    if creditCards.isEmpty && liquidityAccounts.isEmpty {
                        emptyStateGuideCard
                    }

                    // 3. Semáforo Buró de Crédito & Capacidad de Endeudamiento
                    CreditUtilizationCard(
                        totalDebt: totalDebtCurrent,
                        totalLimit: totalCreditLimit,
                        utilizationRatio: overallUtilizationRatio
                    )

                    // 4. Próximos Pagos del Mes (Compromisos Críticos)
                    UpcomingPaymentsCard(payments: upcomingPayments)

                    // 5. Desglose de Tarjetas de Crédito Activas (con diseño físico de TDC, chip y relieve)
                    CreditCardsSnapshotCard(cards: creditCards)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("KASH")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    PrivacyToggleButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.quickTransactionInitialType = .expense
                        appState.isQuickTransactionPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: "#2563EB"))
                    }
                }
            }
            .onAppear {
                syncWidgetData()
            }
            .onChange(of: totalDebtCurrent) { _, _ in
                syncWidgetData()
            }
            .onChange(of: realLiquidityTotal) { _, _ in
                syncWidgetData()
            }
        }
    }

    // MARK: - Sincronización con KASHWidgets
    private func syncWidgetData() {
        let sortedPending = upcomingPayments
            .filter { $0.status == .pending }
            .sorted { $0.dueDate < $1.dueDate }
        let nextCard = sortedPending.first?.card?.name ?? sortedPending.first?.concept
        let nextDays = sortedPending.first.map {
            max(0, Calendar.current.dateComponents([.day], from: Date(), to: $0.dueDate).day ?? 0)
        }

        let snapshot = KASHWidgetSnapshot(
            totalDebt: totalDebtCurrent,
            realLiquidity: realLiquidityTotal,
            utilizationRatio: overallUtilizationRatio,
            healthStatus: overallUtilizationRatio < 0.30 ? "Óptimo" : (overallUtilizationRatio <= 0.50 ? "Alerta" : "Crítico"),
            nextUpcomingCard: nextCard,
            nextUpcomingDays: nextDays,
            activeCardsCount: creditCards.filter { $0.isActive }.count,
            lastUpdated: Date()
        )
        KASHSharedStore.saveSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Banner de bienvenida si está vacío
    private var emptyStateGuideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "#2563EB"))
                Text("Comienza configurando tus cuentas")
                    .font(.kashBodyBold)
                    .foregroundStyle(.primary)
            }

            Text("Agrega tus tarjetas de crédito o cuentas de débito para ver tu semáforo de buró, capacidad de endeudamiento y compromisos en tiempo real.")
                .font(.kashCaption)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                appState.selectedTab = .settings
            } label: {
                HStack(spacing: 6) {
                    Text("Configurar en Ajustes > Catálogos")
                        .font(.kashCaptionBold)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color(hex: "#2563EB"))
                .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Cálculos Financieros Estrictos
    private var realLiquidityTotal: Decimal {
        liquidityAccounts.filter { $0.isActive && $0.accountType != .loan }
            .reduce(0) { $0 + $1.availableBalance }
    }

    private var totalDebtCurrent: Decimal {
        let cardDebt = creditCards.filter { $0.isActive }.reduce(0) { $0 + $1.currentBalance }
        let loanDebt = liquidityAccounts.filter { $0.isActive && $0.accountType == .loan }
            .reduce(0) { $0 + $1.availableBalance }
        return cardDebt + loanDebt
    }

    private var netWorth: Decimal {
        realLiquidityTotal - totalDebtCurrent
    }

    private var totalCreditLimit: Decimal {
        creditCards.filter { $0.isActive }.reduce(0) { $0 + $1.creditLimit }
    }

    private var overallUtilizationRatio: Double {
        guard totalCreditLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: totalDebtCurrent / totalCreditLimit).doubleValue
    }
}

// MARK: - RealLiquidityHeroCard
struct RealLiquidityHeroCard: View {
    let realLiquidity: Decimal
    let totalDebt: Decimal
    let netWorth: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LIQUIDEZ REAL (DINERO PROPIO)")
                        .font(.kashMicro)
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(0.5)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    PrivacyAwareText(
                        amount: realLiquidity,
                        font: .kashAmountHero,
                        foregroundColor: .white
                    )
                }
                Spacer()

                Image(systemName: "banknote.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Divider()
                .overlay(.white.opacity(0.2))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deuda Total a Pagar")
                        .font(.kashMicro)
                        .foregroundStyle(.white.opacity(0.75))
                    PrivacyAwareText(
                        amount: totalDebt,
                        font: .kashAmountSmall,
                        foregroundColor: Color(hex: "#FCA5A5")
                    )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Patrimonio Neto (Líquido)")
                        .font(.kashMicro)
                        .foregroundStyle(.white.opacity(0.75))
                    PrivacyAwareText(
                        amount: netWorth,
                        font: .kashAmountSmall,
                        foregroundColor: netWorth >= 0 ? Color(hex: "#6EE7B7") : Color(hex: "#FCA5A5")
                    )
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: Color(hex: "#2563EB").opacity(0.25), radius: 10, y: 5)
    }
}

// MARK: - QuickActionButtonsRow
struct QuickActionButtonsRow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 10) {
            QuickActionButton(
                title: "+ Gasto",
                icon: "arrow.up.right",
                color: Color(hex: "#EF4444")
            ) {
                appState.quickTransactionInitialType = .expense
                appState.isQuickTransactionPresented = true
            }

            QuickActionButton(
                title: "+ Ingreso",
                icon: "arrow.down.left",
                color: Color(hex: "#10B981")
            ) {
                appState.quickTransactionInitialType = .income
                appState.isQuickTransactionPresented = true
            }

            QuickActionButton(
                title: "Pagar TDC",
                icon: "creditcard.and.123",
                color: Color(hex: "#2563EB")
            ) {
                appState.isCardPaymentPresented = true
            }

            QuickActionButton(
                title: "Corte Rápido",
                icon: "calendar.badge.clock",
                color: Color(hex: "#8B5CF6")
            ) {
                appState.isBatchLogPresented = true
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.kashMicro)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - CreditUtilizationCard
struct CreditUtilizationCard: View {
    let totalDebt: Decimal
    let totalLimit: Decimal
    let utilizationRatio: Double

    private var statusColor: Color {
        if utilizationRatio < 0.30 {
            return Color(hex: "#10B981") // Óptimo
        } else if utilizationRatio <= 0.50 {
            return Color(hex: "#F59E0B") // Alerta
        } else {
            return Color(hex: "#EF4444") // Crítico
        }
    }

    private var statusTitle: String {
        if utilizationRatio < 0.30 {
            return "🟢 Óptimo (< 30% uso)"
        } else if utilizationRatio <= 0.50 {
            return "🟡 Precaución (30% - 50%)"
        } else {
            return "🔴 Crítico (> 50% uso)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Salud Buró de Crédito")
                        .font(.kashBodyBold)
                    Text("Capacidad de Endeudamiento")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                Text(statusTitle)
                    .font(.kashMicro)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }

            // Barra de progreso de utilización
            ProgressView(value: min(1.0, utilizationRatio), total: 1.0)
                .tint(statusColor)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uso Total de Línea")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                    Text("\(Int(utilizationRatio * 100))%")
                        .font(.kashBodyBold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Línea Total Concedida")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                    PrivacyAwareText(amount: totalLimit, font: .kashCaptionBold)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - UpcomingPaymentsCard
struct UpcomingPaymentsCard: View {
    let payments: [UpcomingPayment]

    private var pendingPayments: [UpcomingPayment] {
        payments.filter { $0.status == .pending }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compromisos y Próximos Pagos")
                    .font(.kashBodyBold)
                Spacer()
                Text("\(pendingPayments.count) pendientes")
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
            }

            if pendingPayments.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("¡Al día! No tienes pagos de tarjetas pendientes para este mes.")
                        .font(.kashCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(pendingPayments.prefix(3)) { payment in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(payment.card?.name ?? payment.concept)
                                    .font(.kashCaptionBold)
                                Text("Vence: \(payment.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.kashMicro)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                PrivacyAwareText(
                                    amount: payment.fullPaymentNoInterest,
                                    font: .kashCaptionBold,
                                    foregroundColor: Color(hex: "#EF4444")
                                )
                                Text("No generar intereses")
                                    .font(.kashMicro)
                                    .foregroundStyle(.secondary)
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

// MARK: - CreditCardsSnapshotCard
struct CreditCardsSnapshotCard: View {
    let cards: [CreditCard]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tus Tarjetas de Crédito")
                    .font(.kashBodyBold)
                Spacer()
                if !cards.isEmpty {
                    Text("\(cards.filter { $0.isActive }.count) activas")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                }
            }

            if cards.isEmpty {
                Text("No tienes tarjetas registradas.")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(cards.filter { $0.isActive }) { card in
                            NavigationLink {
                                CreditCardDetailView(card: card)
                            } label: {
                                CreditCardMiniCard(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - EMVCardChipView (Chip Metálico Realista de Tarjeta de Crédito)
struct EMVCardChipView: View {
    var width: CGFloat = 34
    var height: CGFloat = 25

    var body: some View {
        ZStack {
            // Base metálica dorada/champagne
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FDE68A"),
                            Color(hex: "#D97706"),
                            Color(hex: "#F59E0B"),
                            Color(hex: "#FEF3C7")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Líneas de contactos del chip EMV
            VStack(spacing: height * 0.18) {
                Rectangle()
                    .fill(Color.black.opacity(0.28))
                    .frame(height: 1)
                Rectangle()
                    .fill(Color.black.opacity(0.28))
                    .frame(height: 1)
            }

            HStack(spacing: width * 0.24) {
                Rectangle()
                    .fill(Color.black.opacity(0.28))
                    .frame(width: 1)
                Rectangle()
                    .fill(Color.black.opacity(0.28))
                    .frame(width: 1)
            }

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(Color.black.opacity(0.25), lineWidth: 0.8)
                .frame(width: width * 0.38, height: height * 0.48)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 0.8)
        }
        .frame(width: width, height: height)
    }
}

// MARK: - CreditCardMiniCard (Forma y Proporción Real de Tarjeta de Crédito ISO ID-1)
struct CreditCardMiniCard: View {
    let card: CreditCard

    private var lastFourDigitsSim: String {
        String(format: "%02d%02d", max(1, min(31, card.cutoffDay)), max(1, min(31, card.paymentDueDay)))
    }

    var body: some View {
        ZStack {
            // 1. Fondo con gradiente profundo y reflejos de tarjeta física
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: card.colorHex),
                            Color(hex: card.colorHex).opacity(0.82),
                            Color.black.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Textura geométrica sutil tipo tarjeta bancaria
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 65, y: -45)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 120, height: 120)
                    .offset(x: geo.size.width - 35, y: geo.size.height - 60)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // 2. Contenido de la Tarjeta de Crédito
            VStack(alignment: .leading, spacing: 0) {
                // Fila Superior: Banco + Nombre + Uso %
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(card.institution.isEmpty ? "CRÉDITO" : card.institution.uppercased())
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .tracking(1.1)

                        Text(card.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("\(Int(card.utilizationPercentage * 100))% uso")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.18), in: Capsule())
                }

                Spacer(minLength: 6)

                // Fila Central: Chip EMV Metálico + Contactless NFC + Numeración en Relieve
                HStack(spacing: 10) {
                    EMVCardChipView(width: 34, height: 24)

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    Text("•••• \(lastFourDigitsSim)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(1.0)
                }

                Spacer(minLength: 8)

                // Fila Inferior: Saldo Deudor + Fechas Corte/Pago + Emblema de Red
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("SALDO DEUDOR")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .tracking(0.5)

                        PrivacyAwareText(
                            amount: card.currentBalance,
                            font: .kashAmountSmall,
                            foregroundColor: .white
                        )
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Corte \(card.cutoffDay) • Pago \(card.paymentDueDay)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))

                        // Emblema estilo red de pagos (dos círculos entrelazados)
                        HStack(spacing: -6) {
                            Circle()
                                .fill(Color.white.opacity(0.45))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color.white.opacity(0.75))
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .padding(14)

            // Borde especular metálico de 1pt
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.38), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        // Proporción estándar ISO/IEC 7810 ID-1 (~1.586 : 1)
        .frame(width: 238, height: 150)
        .shadow(color: Color(hex: card.colorHex).opacity(0.32), radius: 8, y: 4)
    }
}
