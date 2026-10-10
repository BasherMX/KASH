import WidgetKit
import SwiftUI

// MARK: - KASHWidget
struct KASHWidget: Widget {
    let kind: String = "KASHWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KASHWidgetTimelineProvider()) { entry in
            KASHWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("KASH Deuda y Liquidez")
        .description("Consulta tu deuda total, porcentaje de utilización y ejecuta acciones rápidas.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
        default:
            KASHSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - KASHWidgetsBundle
@main
struct KASHWidgetsBundle: WidgetBundle {
    var body: some Widget {
        KASHWidget()
    }
}
