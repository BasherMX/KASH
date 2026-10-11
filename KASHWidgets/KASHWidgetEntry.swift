import WidgetKit
import Foundation

// MARK: - KASHWidgetEntry
struct KASHWidgetEntry: TimelineEntry {
    let date: Date
    let totalDebt: Decimal
    let realLiquidity: Decimal
    let utilizationRatio: Double
    let healthStatus: String
    let nextUpcomingCard: String?
    let nextUpcomingDays: Int?
    let activeCardsCount: Int

    init(
        date: Date = Date(),
        totalDebt: Decimal,
        realLiquidity: Decimal = 0,
        utilizationRatio: Double,
        healthStatus: String,
        nextUpcomingCard: String? = nil,
        nextUpcomingDays: Int? = nil,
        activeCardsCount: Int = 0
    ) {
        self.date = date
        self.totalDebt = totalDebt
        self.realLiquidity = realLiquidity
        self.utilizationRatio = utilizationRatio
        self.healthStatus = healthStatus
        self.nextUpcomingCard = nextUpcomingCard
        self.nextUpcomingDays = nextUpcomingDays
        self.activeCardsCount = activeCardsCount
    }
}

// MARK: - KASHWidgetTimelineProvider
struct KASHWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> KASHWidgetEntry {
        let sample = KASHWidgetSnapshot.sample
        return KASHWidgetEntry(
            date: Date(),
            totalDebt: sample.totalDebt,
            realLiquidity: sample.realLiquidity,
            utilizationRatio: sample.utilizationRatio,
            healthStatus: sample.healthStatus,
            nextUpcomingCard: sample.nextUpcomingCard,
            nextUpcomingDays: sample.nextUpcomingDays,
            activeCardsCount: sample.activeCardsCount
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (KASHWidgetEntry) -> Void) {
        let snapshot = context.isPreview ? KASHWidgetSnapshot.sample : KASHSharedStore.loadSnapshot()
        let entry = KASHWidgetEntry(
            date: Date(),
            totalDebt: snapshot.totalDebt,
            realLiquidity: snapshot.realLiquidity,
            utilizationRatio: snapshot.utilizationRatio,
            healthStatus: snapshot.healthStatus,
            nextUpcomingCard: snapshot.nextUpcomingCard,
            nextUpcomingDays: snapshot.nextUpcomingDays,
            activeCardsCount: snapshot.activeCardsCount
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KASHWidgetEntry>) -> Void) {
        let snapshot = KASHSharedStore.loadSnapshot()
        let now = Date()
        let entry = KASHWidgetEntry(
            date: now,
            totalDebt: snapshot.totalDebt,
            realLiquidity: snapshot.realLiquidity,
            utilizationRatio: snapshot.utilizationRatio,
            healthStatus: snapshot.healthStatus,
            nextUpcomingCard: snapshot.nextUpcomingCard,
            nextUpcomingDays: snapshot.nextUpcomingDays,
            activeCardsCount: snapshot.activeCardsCount
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
