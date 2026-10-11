import AppIntents
import WidgetKit
import Foundation

// MARK: - QuickExpenseIntent
/// Intención de AppIntents compartida entre App y Widget para registrar rápidamente un gasto
public struct QuickExpenseIntent: AppIntent {
    public static var title: LocalizedStringResource = "Registrar Gasto Rápido"
    public static var description = IntentDescription("Abre KASH directamente en la captura de un nuevo gasto")
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        KASHSharedStore.setPendingAction(.expense)
        return .result()
    }
}

// MARK: - QuickIncomeIntent
/// Intención compartida entre App y Widget para capturar un ingreso
public struct QuickIncomeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Registrar Ingreso Rápido"
    public static var description = IntentDescription("Abre KASH directamente en la captura de un nuevo ingreso")
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        KASHSharedStore.setPendingAction(.income)
        return .result()
    }
}

// MARK: - PayCardIntent
/// Intención compartida entre App y Widget para abrir el flujo de Pago a Tarjeta
public struct PayCardIntent: AppIntent {
    public static var title: LocalizedStringResource = "Pagar Tarjeta de Crédito"
    public static var description = IntentDescription("Abre KASH directamente en el formulario de transferencia Débito a TDC")
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        KASHSharedStore.setPendingAction(.pay)
        return .result()
    }
}
