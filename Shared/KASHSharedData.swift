import Foundation

// MARK: - KASHWidgetSnapshot
/// Estructura de datos compartida entre KASH y KASHWidgets
public struct KASHWidgetSnapshot: Codable, Sendable {
    public var totalDebt: Decimal
    public var utilizationRatio: Double
    public var healthStatus: String
    public var nextUpcomingCard: String?
    public var nextUpcomingDays: Int?
    public var lastUpdated: Date

    public init(
        totalDebt: Decimal,
        utilizationRatio: Double,
        healthStatus: String,
        nextUpcomingCard: String? = nil,
        nextUpcomingDays: Int? = nil,
        lastUpdated: Date = Date()
    ) {
        self.totalDebt = totalDebt
        self.utilizationRatio = utilizationRatio
        self.healthStatus = healthStatus
        self.nextUpcomingCard = nextUpcomingCard
        self.nextUpcomingDays = nextUpcomingDays
        self.lastUpdated = lastUpdated
    }

    public static let sample = KASHWidgetSnapshot(
        totalDebt: 39375.71,
        utilizationRatio: 0.274,
        healthStatus: "Óptimo",
        nextUpcomingCard: "HEY BANCO",
        nextUpcomingDays: 3,
        lastUpdated: Date()
    )
}

// MARK: - KASHSharedStore
/// Administrador del almacenamiento compartido para Widgets (App Group con fallback a standard)
public enum KASHSharedStore {
    private static let appGroupId = "group.com.kash.app"
    private static let key = "kash_widget_snapshot_data"

    private static var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }

    public static func saveSnapshot(_ snapshot: KASHWidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            userDefaults.set(data, forKey: key)
        }
    }

    public static func loadSnapshot() -> KASHWidgetSnapshot {
        if let data = userDefaults.data(forKey: key),
           let snapshot = try? JSONDecoder().decode(KASHWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .sample
    }
}
