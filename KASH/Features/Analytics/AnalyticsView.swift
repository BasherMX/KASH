import SwiftUI
import SwiftData

// MARK: - AnalyticsView
struct AnalyticsView: View {
    @Query private var transactions: [Transaction]
    @Query private var creditCards: [CreditCard]
    @Query private var monthlyRecords: [MonthlyRecord]
    @Query private var userSettingsList: [UserSettings]

    @State private var periodFilter = PeriodFilterSelection()

    private var currentSettings: UserSettings {
        userSettingsList.first ?? UserSettings()
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { tx in
            periodFilter.matches(date: tx.transactionDate)
        }
    }

    private var periodExpenses: Decimal {
        filteredTransactions.filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var periodPayments: Decimal {
        filteredTransactions.filter { $0.type == .cardPayment }
            .reduce(0) { $0 + $1.amount }
    }

    private var periodOrCurrentDebt: Decimal {
        if periodFilter.mode == .month,
           let recordForMonth = monthlyRecords.first(where: { periodFilter.matches(date: $0.periodDate) }) {
            return recordForMonth.totalDebt
        }
        return creditCards.filter { $0.isActive }.reduce(0) { $0 + $1.currentBalance }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selector de Mes / Histórico arriba en la pestaña (por defecto Mes Actual)
                PeriodFilterHeaderView(selection: $periodFilter)

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Donut Chart de Gastos por Categoría (filtrado por mes o histórico)
                        CategoryExpensesDonutChart(
                            transactions: filteredTransactions,
                            periodTitle: periodFilter.periodTitle
                        )

                        // 2. Velocidad de Endeudamiento (Burn Rate vs Payoff Rate del periodo seleccionado)
                        BurnRateIndicatorView(
                            monthlyExpenses: periodExpenses,
                            monthlyPayments: periodPayments,
                            periodTitle: periodFilter.periodTitle
                        )

                        // 3. Detector de Concentración de Deuda & Avalancha
                        DebtConcentrationView(cards: creditCards)

                        // 4. Proyección Deuda Cero ($0.00)
                        ZeroDebtEstimatorView(
                            totalDebt: periodOrCurrentDebt,
                            monthlyIncome: currentSettings.monthlyIncome,
                            allocationPercentage: currentSettings.debtAllocationPercentage
                        )
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Inteligencia Financiera")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
        }
    }
}
