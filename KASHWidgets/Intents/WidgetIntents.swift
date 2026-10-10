import AppIntents
import WidgetKit

// MARK: - QuickExpenseIntent
/// Intención de AppIntents para registrar rápidamente un gasto desde el Widget interactivo
struct QuickExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar Gasto Rápido"
    static var description = IntentDescription("Abre KASH directamente en la captura de un nuevo gasto")
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult {
        // En iOS 17+, abrir la app e invocar la vista de captura
        return .result()
    }
}

// MARK: - QuickIncomeIntent
/// Intención para capturar un ingreso desde el Widget interactivo
struct QuickIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar Ingreso Rápido"
    static var description = IntentDescription("Abre KASH directamente en la captura de un nuevo ingreso")
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - PayCardIntent
/// Intención para abrir directamente el flujo de Pago a Tarjeta desde el Widget
struct PayCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Pagar Tarjeta de Crédito"
    static var description = IntentDescription("Abre KASH directamente en el formulario de transferencia Débito a TDC")
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
