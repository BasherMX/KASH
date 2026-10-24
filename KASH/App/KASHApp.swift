import SwiftUI
import SwiftData
import Foundation
import WidgetKit
import AppIntents

// MARK: - KASHWidgetSyncService
/// Servicio centralizado que sincroniza el estado financiero real de SwiftData con los Widgets de iOS
@MainActor
enum KASHWidgetSyncService {
    static func sync(modelContext: ModelContext) {
        let cards = (try? modelContext.fetch(FetchDescriptor<CreditCard>())) ?? []
        let accounts = (try? modelContext.fetch(FetchDescriptor<LiquidityAccount>())) ?? []
        let payments = (try? modelContext.fetch(FetchDescriptor<UpcomingPayment>())) ?? []

        let activeCards = cards.filter { $0.isActive }
        let cardDebt = activeCards.reduce(Decimal(0)) { $0 + $1.currentBalance }
        let loanDebt = accounts.filter { $0.isActive && $0.accountType == .loan }
            .reduce(Decimal(0)) { $0 + $1.availableBalance }
        let totalDebt = cardDebt + loanDebt

        let realLiquidity = accounts.filter { $0.isActive && $0.accountType != .loan }
            .reduce(Decimal(0)) { $0 + $1.availableBalance }

        let totalLimit = activeCards.reduce(Decimal(0)) { $0 + $1.creditLimit }
        let ratio = totalLimit > 0 ? NSDecimalNumber(decimal: totalDebt / totalLimit).doubleValue : 0.0

        let sortedPending = payments
            .filter { $0.status == .pending }
            .sorted { $0.dueDate < $1.dueDate }
        let nextCard = sortedPending.first?.card?.name ?? sortedPending.first?.concept
        let nextDays = sortedPending.first.map {
            max(0, Calendar.current.dateComponents([.day], from: Date(), to: $0.dueDate).day ?? 0)
        }

        let snapshot = KASHWidgetSnapshot(
            totalDebt: totalDebt,
            realLiquidity: realLiquidity,
            utilizationRatio: ratio,
            healthStatus: ratio < 0.30 ? "Óptimo" : (ratio <= 0.50 ? "Alerta" : "Crítico"),
            nextUpcomingCard: nextCard,
            nextUpcomingDays: nextDays,
            activeCardsCount: activeCards.count,
            lastUpdated: Date()
        )
        KASHSharedStore.saveSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - KASHShortcutsProvider (App Intents Registration for Siri, Spotlight & Shortcuts)
struct KASHShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickExpenseIntent(),
            phrases: [
                "Registrar gasto en \(.applicationName)",
                "Nuevo gasto en \(.applicationName)"
            ],
            shortTitle: "Registrar Gasto",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: QuickIncomeIntent(),
            phrases: [
                "Registrar ingreso en \(.applicationName)",
                "Nuevo ingreso en \(.applicationName)"
            ],
            shortTitle: "Registrar Ingreso",
            systemImageName: "arrow.down.left.circle.fill"
        )
        AppShortcut(
            intent: PayCardIntent(),
            phrases: [
                "Pagar tarjeta en \(.applicationName)",
                "Abonar a tarjeta en \(.applicationName)"
            ],
            shortTitle: "Pagar Tarjeta",
            systemImageName: "creditcard.and.123"
        )
    }
}

// MARK: - KASH App Entry Point
@main
struct KASHApp: App {
    @StateObject private var appState = AppState()
    let sharedModelContainer: ModelContainer

    init() {
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

        let modelConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Garantizar que la base de datos local cuente con protección completa de hardware de iOS
            // FileProtectionType.completeUnlessOpen (Secure Enclave encriptado en reposo)
            let storeURL = modelConfiguration.url
            let path = storeURL.path
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.completeUnlessOpen],
                    ofItemAtPath: path
                )
            }

            self.sharedModelContainer = container

            // Inicializar categorías estándar, delegado de notificaciones y UserSettings canónico de forma síncrona
            let context = container.mainContext
            Self.initializeDatabaseDefaults(in: context)
            _ = NotificationManager.shared
            KASHWidgetSyncService.sync(modelContext: context)
        } catch {
            fatalError("No se pudo inicializar ModelContainer de SwiftData: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }

    /// Crea las categorías estándar y asegura que exista exactamente un registro `UserSettings`
    @MainActor
    private static func initializeDatabaseDefaults(in context: ModelContext) {
        let descriptor = FetchDescriptor<TransactionCategory>()
        if let count = try? context.fetchCount(descriptor), count == 0 {
            let defaults: [(String, String, String, TransactionType)] = [
                ("Supermercado", "cart.fill", "#10B981", .expense),
                ("Servicios & Hogar", "house.fill", "#3B82F6", .expense),
                ("Restaurantes & Cafés", "fork.knife", "#F59E0B", .expense),
                ("Transporte & Gasolina", "fuelpump.fill", "#EC4899", .expense),
                ("Compras & Personal", "bag.fill", "#8B5CF6", .expense),
                ("Salud & Farmacia", "cross.case.fill", "#EF4444", .expense),
                ("Entretenimiento", "tv.fill", "#06B6D4", .expense),
                ("Nómina / Sueldo", "banknote.fill", "#10B981", .income),
                ("Otros Ingresos", "plus.circle.fill", "#3B82F6", .income)
            ]

            for item in defaults {
                let cat = TransactionCategory(
                    name: item.0,
                    iconName: item.1,
                    colorHex: item.2,
                    categoryType: item.3,
                    isDefault: true
                )
                context.insert(cat)
            }
        }

        // Asegurar siempre instancia única de UserSettings incluso si las categorías ya existían
        _ = UserSettings.shared(in: context)
        try? context.save()
    }
}
