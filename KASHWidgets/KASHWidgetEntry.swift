import WidgetKit
import Foundation

// MARK: - KASHWidgetEntry
struct KASHWidgetEntry: TimelineEntry {
    let date: Date
    let currentMonthName: String
    let currentMonthExpenses: Decimal
    let currentMonthIncome: Decimal
    let totalDebt: Decimal
    let realLiquidity: Decimal
    let utilizationRatio: Double
    let healthStatus: String
    let nextUpcomingCard: String?
    let nextUpcomingDays: Int?
    let activeCardsCount: Int

    init(
        date: Date = Date(),
        currentMonthName: String = "",
        currentMonthExpenses: Decimal = 0,
        currentMonthIncome: Decimal = 0,
        totalDebt: Decimal = 0,
        realLiquidity: Decimal = 0,
        utilizationRatio: Double = 0,
        healthStatus: String = "Al día",
        nextUpcomingCard: String? = nil,
        nextUpcomingDays: Int? = nil,
        activeCardsCount: Int = 0
    ) {
        self.date = date
        if currentMonthName.isEmpty {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_MX")
            formatter.dateFormat = "LLLL"
            self.currentMonthName = formatter.string(from: date).uppercased()
        } else {
            self.currentMonthName = currentMonthName
        }
        self.currentMonthExpenses = currentMonthExpenses
        self.currentMonthIncome = currentMonthIncome
        self.totalDebt = totalDebt
        self.realLiquidity = realLiquidity
        self.utilizationRatio = utilizationRatio
        self.healthStatus = healthStatus
        self.nextUpcomingCard = nextUpcomingCard
        self.nextUpcomingDays = nextUpcomingDays
        self.activeCardsCount = activeCardsCount
    }

    init(date: Date = Date(), snapshot: KASHWidgetSnapshot) {
        self.date = date
        self.currentMonthName = snapshot.currentMonthName
        self.currentMonthExpenses = snapshot.currentMonthExpenses
        self.currentMonthIncome = snapshot.currentMonthIncome
        self.totalDebt = snapshot.totalDebt
        self.realLiquidity = snapshot.realLiquidity
        self.utilizationRatio = snapshot.utilizationRatio
        self.healthStatus = snapshot.healthStatus
        self.nextUpcomingCard = snapshot.nextUpcomingCard
        self.nextUpcomingDays = snapshot.nextUpcomingDays
        self.activeCardsCount = snapshot.activeCardsCount
    }
}

// MARK: - KASHWidgetTimelineProvider
struct KASHWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> KASHWidgetEntry {
        let snapshot = KASHSharedStore.loadSnapshot()
        return KASHWidgetEntry(date: Date(), snapshot: snapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (KASHWidgetEntry) -> Void) {
        let snapshot = KASHSharedStore.loadSnapshot()
        completion(KASHWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KASHWidgetEntry>) -> Void) {
        let snapshot = KASHSharedStore.loadSnapshot()
        let now = Date()
        let entry = KASHWidgetEntry(date: now, snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
