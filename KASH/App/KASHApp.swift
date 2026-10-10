import SwiftUI
import SwiftData

// MARK: - KASH App Entry Point
@main
struct KASHApp: App {
    @StateObject private var appState = AppState()

    // Configuración de almacenamiento local seguro SwiftData
    var sharedModelContainer: ModelContainer = {
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
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Garantizar que la base de datos local cuente con protección completa de hardware de iOS
            // FileProtectionType.completeFileProtectionUnlessOpen (Secure Enclave encriptado en reposo)
            let storeURL = modelConfiguration.url
            let path = storeURL.path
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.completeFileProtectionUnlessOpen],
                    ofItemAtPath: path
                )
            }
            
            return container
        } catch {
            fatalError("No se pudo inicializar ModelContainer de SwiftData: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .task {
                    // Inicializar categorías base si la base de datos está recién creada
                    initializeDefaultCategoriesIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    /// Crea las categorías estándar si es la primera vez que se ejecuta la app
    @MainActor
    private func initializeDefaultCategoriesIfNeeded() {
        let context = sharedModelContainer.mainContext
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

            // Crear UserSettings inicial por defecto si no existe
            let settingsDescriptor = FetchDescriptor<UserSettings>()
            if (try? context.fetchCount(settingsDescriptor)) == 0 {
                let initialSettings = UserSettings()
                context.insert(initialSettings)
            }

            try? context.save()
        }
    }
}
