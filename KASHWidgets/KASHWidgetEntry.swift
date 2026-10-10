import WidgetKit
import Foundation

// MARK: - KASHWidgetEntry
struct KASHWidgetEntry: TimelineEntry {
    let date: Date
    let totalDebt: Decimal
    let utilizationRatio: Double
    let healthStatus: String
    let nextUpcomingCard: String?
    let nextUpcomingDays: Int?
}

// MARK: - KASHWidgetTimelineProvider
struct KASHWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> KASHWidgetEntry {
        KASHWidgetEntry(
            date: Date(),
            totalDebt: 39375.71,
            utilizationRatio: 0.274,
            healthStatus: "Óptimo",
            nextUpcomingCard: "HEY BANCO",
            nextUpcomingDays: 3
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (KASHWidgetEntry) -> Void) {
        let entry = KASHWidgetEntry(
            date: Date(),
            totalDebt: 39375.71,
            utilizationRatio: 0.274,
            healthStatus: "Óptimo",
            nextUpcomingCard: "HEY BANCO",
            nextUpcomingDays: 3
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KASHWidgetEntry>) -> Void) {
        // En una implementación con App Group, se lee la snapshot compartida
        let entry = KASHWidgetEntry(
            date: Date(),
            totalDebt: 39375.71,
            utilizationRatio: 0.274,
            healthStatus: "Óptimo",
            nextUpcomingCard: "HEY BANCO",
            nextUpcomingDays: 3
        )
        // Actualizar después de 1 hora
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
