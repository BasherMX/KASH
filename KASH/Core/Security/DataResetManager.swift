import Foundation
import SwiftData
import LocalAuthentication
import WidgetKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - DataResetManager
/// Administrador del restablecimiento de fábrica y borrado seguro de datos.
/// Ejecuta la doble confirmación (modal + autenticación biométrica/código)
/// y elimina todas las entidades locales de SwiftData, restaurando el estado limpio original.
@MainActor
public final class DataResetManager {
    public static let shared = DataResetManager()

    private init() {}

    /// Borra todas las entidades de datos del usuario, reinicia categorías y ajustes por defecto,
    /// limpia la caché compartida de widgets y restablece el estado de bienvenida (Onboarding).
    public func wipeAllData(modelContext: ModelContext) throws {
        // 1. Eliminar todas las transacciones
        let transactions = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        for tx in transactions {
            modelContext.delete(tx)
        }

        // 2. Eliminar balances mensuales de tarjetas
        let balances = (try? modelContext.fetch(FetchDescriptor<CardMonthlyBalance>())) ?? []
        for balance in balances {
            modelContext.delete(balance)
        }

        // 3. Eliminar cortes mensuales
        let records = (try? modelContext.fetch(FetchDescriptor<MonthlyRecord>())) ?? []
        for record in records {
            modelContext.delete(record)
        }

        // 4. Eliminar pagos futuros
        let payments = (try? modelContext.fetch(FetchDescriptor<UpcomingPayment>())) ?? []
        for payment in payments {
            modelContext.delete(payment)
        }

        // 5. Eliminar tarjetas de crédito
        let cards = (try? modelContext.fetch(FetchDescriptor<CreditCard>())) ?? []
        for card in cards {
            modelContext.delete(card)
        }

        // 6. Eliminar cuentas de liquidez
        let accounts = (try? modelContext.fetch(FetchDescriptor<LiquidityAccount>())) ?? []
        for account in accounts {
            modelContext.delete(account)
        }

        // 7. Eliminar categorías existentes
        let categories = (try? modelContext.fetch(FetchDescriptor<TransactionCategory>())) ?? []
        for cat in categories {
            modelContext.delete(cat)
        }

        // 8. Eliminar configuraciones de usuario existentes
        let settings = (try? modelContext.fetch(FetchDescriptor<UserSettings>())) ?? []
        for s in settings {
            modelContext.delete(s)
        }

        // 9. Reinsertar categorías estándar por defecto
        let defaultCategories: [(String, String, String, TransactionType)] = [
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

        for item in defaultCategories {
            let cat = TransactionCategory(
                name: item.0,
                iconName: item.1,
                colorHex: item.2,
                categoryType: item.3,
                isDefault: true
            )
            modelContext.insert(cat)
        }

        // 10. Reinsertar UserSettings por defecto
        let initialSettings = UserSettings()
        modelContext.insert(initialSettings)

        // 11. Guardar cambios atómicamente en SwiftData
        try modelContext.save()

        // 12. Restablecer UserDefaults (Onboarding y Modo Privacidad)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(false, forKey: "isPrivacyModeEnabled")

        // 13. Restablecer Snapshot de Widgets a valores iniciales y recargar timelines
        KASHSharedStore.saveSnapshot(.sample)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Autentica al usuario mediante código de iPhone o biometría y procede al borrado total de la app.
    public func authenticateAndWipe(
        modelContext: ModelContext,
        onSuccess: @escaping () -> Void,
        onFailure: ((Error?) -> Void)? = nil
    ) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"
        let reason = "Ingresa el código de tu iPhone o Face ID para autorizar el borrado total de KASH"

        Task {
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                if success {
                    try self.wipeAllData(modelContext: modelContext)
                    #if canImport(UIKit)
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    #endif
                    onSuccess()
                } else {
                    onFailure?(nil)
                }
            } catch {
                #if targetEnvironment(simulator)
                // Permitir prueba fluida en simuladores donde no se haya enrolado passcode o biometría
                do {
                    try self.wipeAllData(modelContext: modelContext)
                    #if canImport(UIKit)
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    #endif
                    onSuccess()
                } catch let wipeErr {
                    onFailure?(wipeErr)
                }
                #else
                onFailure?(error)
                #endif
            }
        }
    }
}
