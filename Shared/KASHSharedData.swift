import Foundation

// MARK: - KASHWidgetAction
public enum KASHWidgetAction: String, Codable, Sendable {
    case expense = "expense"
    case income = "income"
    case pay = "pay"
    case dashboard = "dashboard"
}

// MARK: - KASHWidgetSnapshot
/// Estructura de datos compartida entre KASH y KASHWidgets
public struct KASHWidgetSnapshot: Codable, Sendable {
    public var totalDebt: Decimal
    public var realLiquidity: Decimal
    public var utilizationRatio: Double
    public var healthStatus: String
    public var nextUpcomingCard: String?
    public var nextUpcomingDays: Int?
    public var activeCardsCount: Int
    public var lastUpdated: Date

    public init(
        totalDebt: Decimal,
        realLiquidity: Decimal = 0,
        utilizationRatio: Double,
        healthStatus: String,
        nextUpcomingCard: String? = nil,
        nextUpcomingDays: Int? = nil,
        activeCardsCount: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.totalDebt = totalDebt
        self.realLiquidity = realLiquidity
        self.utilizationRatio = utilizationRatio
        self.healthStatus = healthStatus
        self.nextUpcomingCard = nextUpcomingCard
        self.nextUpcomingDays = nextUpcomingDays
        self.activeCardsCount = activeCardsCount
        self.lastUpdated = lastUpdated
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalDebt = try container.decodeIfPresent(Decimal.self, forKey: .totalDebt) ?? 0
        self.realLiquidity = try container.decodeIfPresent(Decimal.self, forKey: .realLiquidity) ?? 0
        self.utilizationRatio = try container.decodeIfPresent(Double.self, forKey: .utilizationRatio) ?? 0
        self.healthStatus = try container.decodeIfPresent(String.self, forKey: .healthStatus) ?? "Óptimo"
        self.nextUpcomingCard = try container.decodeIfPresent(String.self, forKey: .nextUpcomingCard)
        self.nextUpcomingDays = try container.decodeIfPresent(Int.self, forKey: .nextUpcomingDays)
        self.activeCardsCount = try container.decodeIfPresent(Int.self, forKey: .activeCardsCount) ?? 0
        self.lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }

    public static let sample = KASHWidgetSnapshot(
        totalDebt: 39375.71,
        realLiquidity: 18450.00,
        utilizationRatio: 0.274,
        healthStatus: "Óptimo",
        nextUpcomingCard: "HEY BANCO",
        nextUpcomingDays: 3,
        activeCardsCount: 3,
        lastUpdated: Date()
    )
}

// MARK: - KASHSharedStore
/// Administrador del almacenamiento compartido para Widgets (App Group con fallback seguro a standard)
public enum KASHSharedStore {
    public static let appGroupId = "group.com.kash.app"
    public static let mainWidgetKind = "KASHWidget"
    public static let upcomingWidgetKind = "KASHUpcomingPaymentsWidget"
    public static let lockScreenWidgetKind = "KASHLockScreenWidget"

    private static let key = "kash_widget_snapshot_data"
    private static let pendingActionKey = "kash_widget_pending_action"

    private static var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }

    public static func saveSnapshot(_ snapshot: KASHWidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            userDefaults.set(data, forKey: key)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    public static func loadSnapshot() -> KASHWidgetSnapshot {
        if let data = userDefaults.data(forKey: key) ?? UserDefaults.standard.data(forKey: key),
           let snapshot = try? JSONDecoder().decode(KASHWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .sample
    }

    public static func setPendingAction(_ action: KASHWidgetAction) {
        userDefaults.set(action.rawValue, forKey: pendingActionKey)
        UserDefaults.standard.set(action.rawValue, forKey: pendingActionKey)
        NotificationCenter.default.post(name: Notification.Name("KASHWidgetActionTriggered"), object: action.rawValue)
    }

    public static func consumePendingAction() -> KASHWidgetAction? {
        let raw = userDefaults.string(forKey: pendingActionKey) ?? UserDefaults.standard.string(forKey: pendingActionKey)
        guard let rawValue = raw, let action = KASHWidgetAction(rawValue: rawValue) else {
            return nil
        }
        userDefaults.removeObject(forKey: pendingActionKey)
        UserDefaults.standard.removeObject(forKey: pendingActionKey)
        return action
    }
}
