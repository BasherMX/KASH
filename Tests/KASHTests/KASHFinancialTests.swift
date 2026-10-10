import Testing
import Foundation
import SwiftData
@testable import KASH

// MARK: - Suite de Pruebas Unitarias para KASH (Swift Testing)
@Suite("KASH Financial Logic & Golden Rule Tests")
struct KASHFinancialTests {

    @Test("Verifica la Regla de Oro: El crédito disponible NO es dinero propio")
    func testGoldenRuleCreditIsNotRealLiquidity() {
        let card = CreditCard(
            name: "Plata Card",
            institution: "Plata",
            creditLimit: 45000,
            cutoffDay: 5,
            paymentDueDay: 25
        )

        let debitAccount = LiquidityAccount(
            name: "BBVA Nómina",
            institution: "BBVA",
            availableBalance: 12500,
            accountType: .debit
        )

        // El crédito disponible de la tarjeta es 45,000, pero NO suma a la liquidez real
        #expect(card.availableCredit == 45000)
        #expect(card.currentBalance == 0)

        // La liquidez real solo debe ser el saldo propio
        let realLiquidity = debitAccount.availableBalance
        #expect(realLiquidity == 12500)
    }

    @Test("Cálculo de Utilización de Tarjeta de Crédito")
    func testCardUtilizationCalculation() {
        let card = CreditCard(
            name: "Nu",
            institution: "Nu",
            creditLimit: 20000,
            cutoffDay: 1,
            paymentDueDay: 20
        )

        let balance = CardMonthlyBalance(
            balanceUsed: 5000,
            recordedAt: Date(),
            card: card
        )
        card.balances = [balance]

        #expect(card.currentBalance == 5000)
        #expect(card.availableCredit == 15000)
        #expect(card.utilizationPercentage == 0.25) // 25% de uso (Óptimo < 30%)
    }

    @Test("Ejecución atómica de Pago de Tarjeta")
    func testAtomicCardPaymentExecution() {
        let debitAccount = LiquidityAccount(
            name: "BBVA Nómina",
            institution: "BBVA",
            availableBalance: 10000,
            accountType: .debit
        )

        let card = CreditCard(
            name: "Hey Banco",
            institution: "Banregio",
            creditLimit: 30000,
            cutoffDay: 10,
            paymentDueDay: 30
        )

        let balance = CardMonthlyBalance(
            balanceUsed: 4000,
            recordedAt: Date(),
            card: card
        )
        card.balances = [balance]

        let paymentAmount: Decimal = 4000

        // Simular pago
        debitAccount.availableBalance -= paymentAmount
        balance.balanceUsed -= paymentAmount

        #expect(debitAccount.availableBalance == 6000)
        #expect(balance.balanceUsed == 0)
        #expect(card.currentBalance == 0)
        #expect(card.availableCredit == 30000)
    }

    @Test("Cálculo de Amortización y Estimación de Deuda Cero")
    func testZeroDebtProjection() {
        let totalDebt: Decimal = 60000
        let monthlyIncome: Decimal = 50000
        let allocationPercentage: Double = 0.40 // 40% = 20,000 / mes

        let monthlyCapacity = monthlyIncome * Decimal(allocationPercentage)
        #expect(monthlyCapacity == 20000)

        let months = NSDecimalNumber(decimal: totalDebt / monthlyCapacity).doubleValue
        #expect(months == 3.0)
    }

    @Test("Verifica que las tarjetas toman el corte cronológico más reciente, sin importar orden de inserción")
    func testChronologicalCutsOrdering() {
        let card = CreditCard(
            name: "Plata Card",
            institution: "Plata",
            creditLimit: 50000,
            cutoffDay: 15,
            paymentDueDay: 5
        )

        let calendar = Calendar.current
        var compsOct = DateComponents()
        compsOct.year = 2026
        compsOct.month = 10
        compsOct.day = 15
        let octDate = calendar.date(from: compsOct)!

        var compsFeb = DateComponents()
        compsFeb.year = 2026
        compsFeb.month = 2
        compsFeb.day = 15
        let febDate = calendar.date(from: compsFeb)!

        let recordOct = MonthlyRecord(periodDate: octDate)
        let balanceOct = CardMonthlyBalance(balanceUsed: 18500, recordedAt: Date(), card: card, monthlyRecord: recordOct)

        let recordFeb = MonthlyRecord(periodDate: febDate)
        // Se crea el corte de febrero DESPUÉS en tiempo de ejecución (recordedAt posterior)
        let balanceFeb = CardMonthlyBalance(balanceUsed: 4200, recordedAt: Date().addingTimeInterval(100), card: card, monthlyRecord: recordFeb)

        // Se asignan ambos balances
        card.balances = [balanceFeb, balanceOct]

        // El saldo actual DEBE ser el de octubre 2026 (18,500) porque es cronológicamente más reciente que febrero 2026 (4,200)
        #expect(card.currentBalance == 18500)
    }

    @Test("Verifica que Face ID está desactivado por defecto")
    func testBiometricDefaultDisabled() {
        let settings = UserSettings()
        #expect(settings.biometricLockMandatory == false)
    }
}
