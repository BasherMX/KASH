import SwiftUI
import SwiftData

// MARK: - AnalyticsView
struct AnalyticsView: View {
    @Query private var transactions: [Transaction]
    @Query private var creditCards: [CreditCard]
    @Query private var userSettingsList: [UserSettings]

    private var currentSettings: UserSettings {
        userSettingsList.first ?? UserSettings()
    }

    private var monthlyExpenses: Decimal {
        let calendar = Calendar.current
        let now = Date()
        return transactions.filter { tx in
            tx.type == .expense && calendar.isDate(tx.transactionDate, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }

    private var monthlyPayments: Decimal {
        let calendar = Calendar.current
        let now = Date()
        return transactions.filter { tx in
            tx.type == .cardPayment && calendar.isDate(tx.transactionDate, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }

    private var totalCurrentDebt: Decimal {
        creditCards.reduce(0) { $0 + $1.currentBalance }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Donut Chart de Gastos por Categoría
                    CategoryExpensesDonutChart(transactions: transactions)

                    // 2. Velocidad de Endeudamiento (Burn Rate vs Payoff Rate)
                    BurnRateIndicatorView(
                        monthlyExpenses: monthlyExpenses,
                        monthlyPayments: monthlyPayments
                    )

                    // 3. Detector de Concentración de Deuda & Avalancha
                    DebtConcentrationView(cards: creditCards)

                    // 4. Proyección Deuda Cero ($0.00)
                    ZeroDebtEstimatorView(
                        totalDebt: totalCurrentDebt,
                        monthlyIncome: currentSettings.monthlyIncome,
                        allocationPercentage: currentSettings.debtAllocationPercentage
                    )
                }
                .padding()
            }
            .navigationTitle("Inteligencia Financiera")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
        }
    }
}
