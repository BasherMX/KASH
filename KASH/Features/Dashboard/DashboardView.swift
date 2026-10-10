import SwiftUI
import UIKit
import SwiftData

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
                VStack(spacing: 20) {
                    // 1. Tarjeta Héroe de Liquidez Real y Regla de Oro
                    RealLiquidityHeroCard(
                        realLiquidity: realLiquidityTotal,
                        totalDebt: totalDebtCurrent,
                        netWorth: netWorth
                    )

                    // 2. Acciones Rápidas
                    QuickActionButtonsRow()

                    // 3. Semáforo Buró de Crédito & Capacidad de Endeudamiento
                    CreditUtilizationCard(
                        totalDebt: totalDebtCurrent,
                        totalLimit: totalCreditLimit,
                        utilizationRatio: overallUtilizationRatio
                    )

                    // 4. Próximos Pagos del Mes (Compromisos Críticos)
                    UpcomingPaymentsCard(payments: upcomingPayments)

                    // 5. Desglose de Tarjetas de Crédito Activas
                    CreditCardsSnapshotCard(cards: creditCards)
                }
                .padding()
            }
            .navigationTitle("KASH")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    PrivacyToggleButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.isQuickTransactionPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: "#2563EB"))
                    }
                }
            }
        }
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LIQUIDEZ REAL (DINERO PROPIO)")
                        .font(.kashMicro)
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(0.5)

                    PrivacyAwareText(
                        amount: realLiquidity,
                        font: .kashAmountHero,
                        foregroundColor: .white
                    )
                }
                Spacer()

                Image(systemName: "banknote.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Divider()
                .overlay(.white.opacity(0.2))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deuda Total a Pagar")
                        .font(.kashMicro)
                        .foregroundStyle(.white.opacity(0.7))
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
                        .foregroundStyle(.white.opacity(0.7))
                    PrivacyAwareText(
                        amount: netWorth,
                        font: .kashAmountSmall,
                        foregroundColor: netWorth >= 0 ? Color(hex: "#6EE7B7") : Color(hex: "#FCA5A5")
                    )
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: Color(hex: "#2563EB").opacity(0.3), radius: 12, y: 6)
    }
}

// MARK: - QuickActionButtonsRow
struct QuickActionButtonsRow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "+ Gasto",
                icon: "arrow.up.right",
                color: Color(hex: "#EF4444")
            ) {
                appState.isQuickTransactionPresented = true
            }

            QuickActionButton(
                title: "+ Ingreso",
                icon: "arrow.down.left",
                color: Color(hex: "#10B981")
            ) {
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
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.kashMicro)
                    .foregroundStyle(.primary)
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
            }

            if cards.isEmpty {
                Text("No tienes tarjetas registradas.")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(cards.filter { $0.isActive }) { card in
                            CreditCardMiniCard(card: card)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CreditCardMiniCard: View {
    let card: CreditCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: card.iconName.isEmpty ? "creditcard.fill" : card.iconName)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(card.utilizationPercentage * 100))%")
                    .font(.kashMicro)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.kashCaptionBold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                PrivacyAwareText(
                    amount: card.currentBalance,
                    font: .kashAmountSmall,
                    foregroundColor: .white
                )
            }
        }
        .padding(12)
        .frame(width: 140, height: 110)
        .background(Color(hex: card.colorHex), in: RoundedRectangle(cornerRadius: 14))
    }
}
