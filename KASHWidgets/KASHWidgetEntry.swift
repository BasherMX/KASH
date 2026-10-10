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
        let sample = KASHWidgetSnapshot.sample
        return KASHWidgetEntry(
            date: Date(),
            totalDebt: sample.totalDebt,
            utilizationRatio: sample.utilizationRatio,
            healthStatus: sample.healthStatus,
            nextUpcomingCard: sample.nextUpcomingCard,
            nextUpcomingDays: sample.nextUpcomingDays
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (KASHWidgetEntry) -> Void) {
        let snapshot = KASHSharedStore.loadSnapshot()
        let entry = KASHWidgetEntry(
            date: Date(),
            totalDebt: snapshot.totalDebt,
            utilizationRatio: snapshot.utilizationRatio,
            healthStatus: snapshot.healthStatus,
            nextUpcomingCard: snapshot.nextUpcomingCard,
            nextUpcomingDays: snapshot.nextUpcomingDays
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KASHWidgetEntry>) -> Void) {
        let snapshot = KASHSharedStore.loadSnapshot()
        let entry = KASHWidgetEntry(
            date: Date(),
            totalDebt: snapshot.totalDebt,
            utilizationRatio: snapshot.utilizationRatio,
            healthStatus: snapshot.healthStatus,
            nextUpcomingCard: snapshot.nextUpcomingCard,
            nextUpcomingDays: snapshot.nextUpcomingDays
        )
        // Actualizar automáticamente cada 30 minutos o por push/reloads
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
