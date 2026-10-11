import WidgetKit
import SwiftUI

// MARK: - 1. KASHWidget (Resumen, Liquidez y Acciones Rápidas)
struct KASHWidget: Widget {
    let kind: String = KASHSharedStore.mainWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KASHWidgetTimelineProvider()) { entry in
            KASHWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("KASH Deuda y Liquidez")
        .description("Consulta tu deuda total, salud de buró y registra gastos, ingresos o pagos con un toque.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 2. KASHUpcomingPaymentsWidget (Próximos Vencimientos y Tarjetas)
struct KASHUpcomingPaymentsWidget: Widget {
    let kind: String = KASHSharedStore.upcomingWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KASHWidgetTimelineProvider()) { entry in
            KASHUpcomingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("KASH Próximos Pagos")
        .description("Monitorea tu próximo corte a vencer y tu capacidad de endeudamiento.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 3. KASHLockScreenWidget (Pantalla de Bloqueo)
struct KASHLockScreenWidget: Widget {
    let kind: String = KASHSharedStore.lockScreenWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KASHWidgetTimelineProvider()) { entry in
            KASHLockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("KASH Pantalla de Bloqueo")
        .description("Indicadores rápidos de deuda y porcentaje de uso de línea en tu pantalla de bloqueo.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - KASHWidgetEntryView
struct KASHWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: KASHWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            KASHSmallWidgetView(entry: entry)
        case .systemMedium:
            KASHMediumWidgetView(entry: entry)
        case .systemLarge:
            KASHLargeWidgetView(entry: entry)
        default:
            KASHSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - KASHUpcomingWidgetEntryView
struct KASHUpcomingWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: KASHWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium:
            KASHMediumWidgetView(entry: entry)
        default:
            KASHUpcomingSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - KASHLockScreenWidgetEntryView
struct KASHLockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: KASHWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            KASHAccessoryCircularWidgetView(entry: entry)
        case .accessoryInline:
            KASHAccessoryInlineWidgetView(entry: entry)
        default:
            KASHAccessoryRectangularWidgetView(entry: entry)
        }
    }
}

// MARK: - KASHWidgetsBundle
@main
struct KASHWidgetsBundle: WidgetBundle {
    var body: some Widget {
        KASHWidget()
        KASHUpcomingPaymentsWidget()
        KASHLockScreenWidget()
    }
}
