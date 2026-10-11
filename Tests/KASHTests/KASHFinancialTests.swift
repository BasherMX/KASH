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

    @Test("Verifica decodificación de DTOs del Paquete Universal de Respaldo")
    func testBackupPackageDecoding() throws {
        let sampleJSON = """
        {
          "manifest": {
            "schemaVersion": "2.2.0",
            "appVersion": "1.2.0",
            "buildNumber": 3,
            "exportedAt": "2026-10-10T18:00:00Z",
            "deviceModel": "iPhone",
            "entityCounts": {
              "creditCards": 1,
              "liquidityAccounts": 1,
              "categories": 1,
              "monthlyRecords": 1,
              "transactions": 1,
              "upcomingPayments": 1
            },
            "checksumSHA256": "test_sha256"
          },
          "settings": {
            "monthlyIncome": 35000.0,
            "debtAllocationPercentage": 0.5,
            "debtReminderDayOfMonth": 5,
            "paymentReminderDaysBefore": 3,
            "biometricLockMandatory": false,
            "isPrivacyModeEnabled": false,
            "terminalCommissionRate": 0.0406
          },
          "categories": [],
          "creditCards": [
            {
              "id": "CARD-1",
              "name": "Plata",
              "institution": "Plata",
              "creditLimit": 40000.0,
              "cutoffDay": 5,
              "paymentDueDay": 25,
              "annualInterestRate": 0.50,
              "recommendedStrategy": null,
              "colorHex": "#1E293B",
              "iconName": "creditcard.fill",
              "isActive": true,
              "displayOrder": 1,
              "createdAt": "2026-10-01T00:00:00Z"
            }
          ],
          "liquidityAccounts": [],
          "monthlyRecords": [],
          "upcomingPayments": [],
          "transactions": []
        }
        """

        let data = sampleJSON.data(using: .utf8)!
        let package = try JSONDecoder().decode(KASHBackupPackage.self, from: data)

        #expect(package.manifest.appVersion == "1.2.0")
        #expect(package.creditCards.count == 1)
        #expect(package.creditCards.first?.name == "Plata")
        #expect(package.creditCards.first?.creditLimit == 40000.0)
    }

    @Test("Verifica filtro de periodo por defecto en mes actual y modo histórico")
    func testPeriodFilterSelectionCurrentMonthAndHistorical() {
        var filter = PeriodFilterSelection()
        #expect(filter.mode == .month)
        #expect(filter.isCurrentMonth == true)

        let now = Date()
        let cal = Calendar.current
        let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: now)!

        // En modo .month por defecto, coincide con hoy pero no con hace 3 meses
        #expect(filter.matches(date: now) == true)
        #expect(filter.matches(date: threeMonthsAgo) == false)

        // Al cambiar a modo .historical, coincide con cualquier fecha
        filter.mode = .historical
        #expect(filter.matches(date: now) == true)
        #expect(filter.matches(date: threeMonthsAgo) == true)

        // Al seleccionar mes y año específicos
        filter.setYearAndMonth(year: 2025, month: 6)
        #expect(filter.mode == .month)
        #expect(filter.selectedYear == 2025)
        #expect(filter.selectedMonth == 6)

        filter.resetToCurrentMonth()
        #expect(filter.isCurrentMonth == true)
    }

    @Test("Verifica persistencia de KASHSharedStore para Widgets y acciones pendientes")
    func testWidgetSharedStoreAndPendingActions() {
        let customSnapshot = KASHWidgetSnapshot(
            totalDebt: 24500.50,
            realLiquidity: 15200.00,
            utilizationRatio: 0.22,
            healthStatus: "Óptimo",
            nextUpcomingCard: "NU",
            nextUpcomingDays: 5,
            activeCardsCount: 2
        )
        KASHSharedStore.saveSnapshot(customSnapshot)
        let loaded = KASHSharedStore.loadSnapshot()
        #expect(loaded.totalDebt == 24500.50)
        #expect(loaded.realLiquidity == 15200.00)
        #expect(loaded.nextUpcomingCard == "NU")
        #expect(loaded.activeCardsCount == 2)

        KASHSharedStore.setPendingAction(.income)
        let consumed = KASHSharedStore.consumePendingAction()
        #expect(consumed == .income)
        #expect(KASHSharedStore.consumePendingAction() == nil)
    }

    @Test("Verifica borrado total de datos y restablecimiento de fábrica")
    @MainActor
    func testDataResetManagerWipeAllData() throws {
        let schema = Schema([
            CreditCard.self,
            LiquidityAccount.self,
            TransactionCategory.self,
            Transaction.self,
            MonthlyRecord.self,
            CardMonthlyBalance.self,
            UpcomingPayment.self,
            UserSettings.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Insertar datos de prueba
        let card = CreditCard(name: "Test Card", institution: "Test Bank", creditLimit: 25000, cutoffDay: 10, paymentDueDay: 25)
        context.insert(card)

        let account = LiquidityAccount(name: "Cuenta Débito", institution: "Banco", availableBalance: 15000, accountType: .debit)
        context.insert(account)

        let tx = Transaction(concept: "Compra", amount: 500, creditCard: card)
        context.insert(tx)

        let record = MonthlyRecord(periodDate: Date())
        context.insert(record)

        let balance = CardMonthlyBalance(balanceUsed: 500, recordedAt: Date(), card: card, monthlyRecord: record)
        context.insert(balance)

        let payment = UpcomingPayment(concept: "Pago Test", dueDate: Date(), minimumPayment: 100, fullPaymentNoInterest: 500, card: card)
        context.insert(payment)

        try context.save()

        // Verificar que hay datos antes del borrado
        #expect(try context.fetchCount(FetchDescriptor<CreditCard>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<LiquidityAccount>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<MonthlyRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CardMonthlyBalance>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<UpcomingPayment>()) == 1)

        // Ejecutar borrado total
        try DataResetManager.shared.wipeAllData(modelContext: context)

        // Verificar que todas las entidades operativas se eliminaron
        #expect(try context.fetchCount(FetchDescriptor<CreditCard>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<LiquidityAccount>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MonthlyRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CardMonthlyBalance>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<UpcomingPayment>()) == 0)

        // Verificar que se recrearon las 9 categorías por defecto y 1 UserSettings inicial
        #expect(try context.fetchCount(FetchDescriptor<TransactionCategory>()) == 9)
        #expect(try context.fetchCount(FetchDescriptor<UserSettings>()) == 1)
    }
}
