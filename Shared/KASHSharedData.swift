import Foundation

// MARK: - CurrencyInputParser
/// Analizador seguro de montos monetarios ingresados por el usuario (soporta coma decimal, punto decimal y separadores de miles)
public enum CurrencyInputParser {
    public static func parseDecimal(_ raw: String) -> Decimal {
        let trimmed = raw
            .filter { "0123456789.,-".contains($0) }
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return 0 }

        let hasComma = trimmed.contains(",")
        let hasDot = trimmed.contains(".")

        let normalized: String
        if hasComma && hasDot {
            let lastComma = trimmed.lastIndex(of: ",")!
            let lastDot = trimmed.lastIndex(of: ".")!
            if lastComma > lastDot {
                // Formato europeo: "25.000,50" -> "25000.50"
                normalized = trimmed
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
            } else {
                // Formato MX/US: "25,000.50" -> "25000.50"
                normalized = trimmed.replacingOccurrences(of: ",", with: "")
            }
        } else if hasComma {
            let parts = trimmed.split(separator: ",", omittingEmptySubsequences: false)
            if parts.count == 2 {
                let fractionalCount = parts[1].count
                // Si tiene 1 o 2 dígitos tras una única coma (ej. "25000,50" o "25000,5"), es separador decimal
                if fractionalCount == 1 || fractionalCount == 2 || parts[0].isEmpty {
                    normalized = trimmed.replacingOccurrences(of: ",", with: ".")
                } else {
                    // Ej. "25,000" -> separador de miles
                    normalized = trimmed.replacingOccurrences(of: ",", with: "")
                }
            } else {
                // Múltiples comas: "1,250,000" -> separador de miles
                normalized = trimmed.replacingOccurrences(of: ",", with: "")
            }
        } else {
            normalized = trimmed
        }

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}

// MARK: - KASHWidgetAction
public enum KASHWidgetAction: String, Codable, Sendable {
    case expense = "expense"
    case income = "income"
    case pay = "pay"
    case dashboard = "dashboard"
}

// MARK: - KASHWidgetSnapshot
/// Estructura de datos compartida entre KASH y KASHWidgets
public struct KASHWidgetSnapshot: Codable, Sendable, Equatable {
    public var currentMonthName: String
    public var currentMonthExpenses: Decimal
    public var currentMonthIncome: Decimal
    public var totalDebt: Decimal
    public var realLiquidity: Decimal
    public var utilizationRatio: Double
    public var healthStatus: String
    public var nextUpcomingCard: String?
    public var nextUpcomingDays: Int?
    public var activeCardsCount: Int
    public var lastUpdated: Date

    public init(
        currentMonthName: String = "",
        currentMonthExpenses: Decimal = 0,
        currentMonthIncome: Decimal = 0,
        totalDebt: Decimal = 0,
        realLiquidity: Decimal = 0,
        utilizationRatio: Double = 0,
        healthStatus: String = "Al día",
        nextUpcomingCard: String? = nil,
        nextUpcomingDays: Int? = nil,
        activeCardsCount: Int = 0,
        lastUpdated: Date = Date()
    ) {
        if currentMonthName.isEmpty {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_MX")
            formatter.dateFormat = "LLLL"
            self.currentMonthName = formatter.string(from: lastUpdated).uppercased()
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
        self.lastUpdated = lastUpdated
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lastUpdatedDate = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
        self.lastUpdated = lastUpdatedDate

        if let month = try container.decodeIfPresent(String.self, forKey: .currentMonthName), !month.isEmpty {
            self.currentMonthName = month
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_MX")
            formatter.dateFormat = "LLLL"
            self.currentMonthName = formatter.string(from: lastUpdatedDate).uppercased()
        }

        self.currentMonthExpenses = try container.decodeIfPresent(Decimal.self, forKey: .currentMonthExpenses) ?? 0
        self.currentMonthIncome = try container.decodeIfPresent(Decimal.self, forKey: .currentMonthIncome) ?? 0
        self.totalDebt = try container.decodeIfPresent(Decimal.self, forKey: .totalDebt) ?? 0
        self.realLiquidity = try container.decodeIfPresent(Decimal.self, forKey: .realLiquidity) ?? 0
        self.utilizationRatio = try container.decodeIfPresent(Double.self, forKey: .utilizationRatio) ?? 0
        self.healthStatus = try container.decodeIfPresent(String.self, forKey: .healthStatus) ?? "Al día"
        self.nextUpcomingCard = try container.decodeIfPresent(String.self, forKey: .nextUpcomingCard)
        self.nextUpcomingDays = try container.decodeIfPresent(Int.self, forKey: .nextUpcomingDays)
        self.activeCardsCount = try container.decodeIfPresent(Int.self, forKey: .activeCardsCount) ?? 0
    }

    public static var empty: KASHWidgetSnapshot {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "LLLL"
        let monthName = formatter.string(from: now).uppercased()

        return KASHWidgetSnapshot(
            currentMonthName: monthName,
            currentMonthExpenses: 0,
            currentMonthIncome: 0,
            totalDebt: 0,
            realLiquidity: 0,
            utilizationRatio: 0,
            healthStatus: "Al día",
            nextUpcomingCard: nil,
            nextUpcomingDays: nil,
            activeCardsCount: 0,
            lastUpdated: now
        )
    }

    public static let sample = empty
}

// MARK: - KASHSharedStore
/// Administrador del almacenamiento compartido para Widgets (App Group dinámico + Archivo en Contenedor + UserDefaults)
public enum KASHSharedStore {
    public static let appGroupId = "group.com.kash.app"
    public static let monthlyFlowWidgetKind = "KASHMonthlyFlowWidget"
    public static let mainWidgetKind = "KASHWidget"
    public static let upcomingWidgetKind = "KASHUpcomingPaymentsWidget"
    public static let lockScreenWidgetKind = "KASHLockScreenWidget"

    private static let key = "kash_widget_snapshot_data"
    private static let pendingActionKey = "kash_widget_pending_action"
    private static let snapshotFileName = "kash_widget_snapshot.json"
    private static let pendingActionFileName = "kash_widget_pending_action.txt"

    /// Verifica si el bundle `PlugIns/KASHWidgets.appex` está presente dentro de la app instalada
    public static var isWidgetExtensionEmbedded: Bool {
        guard let plugInsURL = Bundle.main.builtInPlugInsURL else { return false }
        let widgetURL = plugInsURL.appendingPathComponent("KASHWidgets.appex")
        return FileManager.default.fileExists(atPath: widgetURL.path)
    }

    /// Descubre todos los App Groups candidatos (incluyendo sufijos dinámicos de Sideloadly / AltStore / embedded.mobileprovision)
    public static var candidateAppGroupIds: [String] {
        var groups: [String] = []

        // 1. Extraer de embedded.mobileprovision si existe (en el bundle actual o en la app contenedora)
        for group in provisionedAppGroups() where !groups.contains(group) {
            groups.append(group)
        }

        // 2. Derivar del CFBundleIdentifier en tiempo de ejecución (ej. com.kash.app.TEAMID.widgets -> group.com.kash.app.TEAMID)
        if let bundleId = Bundle.main.bundleIdentifier {
            let hostBundleId: String
            if bundleId.hasSuffix(".widgets") {
                hostBundleId = String(bundleId.dropLast(".widgets".count))
            } else {
                hostBundleId = bundleId
            }
            let derivedGroup = "group.\(hostBundleId)"
            if !groups.contains(derivedGroup) {
                groups.append(derivedGroup)
            }
        }

        // 3. App Group canónico por defecto
        if !groups.contains(appGroupId) {
            groups.append(appGroupId)
        }

        return groups
    }

    private static func provisionedAppGroups() -> [String] {
        var candidateURLs: [URL] = []
        if let mainProvision = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision") {
            candidateURLs.append(mainProvision)
        }
        // Si estamos dentro de PlugIns/KASHWidgets.appex, revisar también ../../embedded.mobileprovision
        let parentAppURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        let parentProvision = parentAppURL.appendingPathComponent("embedded.mobileprovision")
        if FileManager.default.fileExists(atPath: parentProvision.path) {
            candidateURLs.append(parentProvision)
        }

        var result: [String] = []
        for url in candidateURLs {
            guard let data = try? Data(contentsOf: url),
                  let content = String(data: data, encoding: .isoLatin1),
                  let plistStart = content.range(of: "<?xml"),
                  let plistEnd = content.range(of: "</plist>") else {
                continue
            }
            let xmlString = String(content[plistStart.lowerBound..<plistEnd.upperBound])
            guard let xmlData = xmlString.data(using: .utf8),
                  let plist = try? PropertyListSerialization.propertyList(from: xmlData, options: [], format: nil) as? [String: Any],
                  let entitlements = plist["Entitlements"] as? [String: Any],
                  let groups = entitlements["com.apple.security.application-groups"] as? [String] else {
                continue
            }
            for g in groups where !result.contains(g) {
                result.append(g)
            }
        }
        return result
    }

    private static var sharedContainerURLs: [URL] {
        var urls: [URL] = []
        for groupId in candidateAppGroupIds {
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId),
               !urls.contains(url) {
                urls.append(url)
            }
        }
        return urls
    }

    public static func saveSnapshot(_ snapshot: KASHWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        // 1. Guardar en archivo dentro de cualquier contenedor de App Group válido
        for containerURL in sharedContainerURLs {
            let fileURL = containerURL.appendingPathComponent(snapshotFileName)
            try? data.write(to: fileURL, options: .atomic)
        }

        // 2. Guardar en UserDefaults de todos los App Groups candidatos + standard
        for groupId in candidateAppGroupIds {
            UserDefaults(suiteName: groupId)?.set(data, forKey: key)
        }
        UserDefaults.standard.set(data, forKey: key)
    }

    public static func loadSnapshot() -> KASHWidgetSnapshot {
        let decoder = JSONDecoder()

        // 1. Intentar leer desde contenedor de archivos compartido del App Group
        for containerURL in sharedContainerURLs {
            let fileURL = containerURL.appendingPathComponent(snapshotFileName)
            if let data = try? Data(contentsOf: fileURL),
               let snapshot = try? decoder.decode(KASHWidgetSnapshot.self, from: data) {
                return snapshot
            }
        }

        // 2. Intentar leer desde UserDefaults de App Groups candidatos o standard
        for groupId in candidateAppGroupIds {
            if let data = UserDefaults(suiteName: groupId)?.data(forKey: key),
               let snapshot = try? decoder.decode(KASHWidgetSnapshot.self, from: data) {
                return snapshot
            }
        }

        if let data = UserDefaults.standard.data(forKey: key),
           let snapshot = try? decoder.decode(KASHWidgetSnapshot.self, from: data) {
            return snapshot
        }

        return .empty
    }

    public static func setPendingAction(_ action: KASHWidgetAction) {
        let raw = action.rawValue
        for containerURL in sharedContainerURLs {
            let fileURL = containerURL.appendingPathComponent(pendingActionFileName)
            try? raw.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        }
        for groupId in candidateAppGroupIds {
            UserDefaults(suiteName: groupId)?.set(raw, forKey: pendingActionKey)
        }
        UserDefaults.standard.set(raw, forKey: pendingActionKey)
        NotificationCenter.default.post(name: Notification.Name("KASHWidgetActionTriggered"), object: raw)
    }

    public static func consumePendingAction() -> KASHWidgetAction? {
        var foundRaw: String? = nil

        for containerURL in sharedContainerURLs {
            let fileURL = containerURL.appendingPathComponent(pendingActionFileName)
            if let data = try? Data(contentsOf: fileURL),
               let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !str.isEmpty {
                foundRaw = str
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        for groupId in candidateAppGroupIds {
            if let str = UserDefaults(suiteName: groupId)?.string(forKey: pendingActionKey)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                if foundRaw == nil { foundRaw = str }
                UserDefaults(suiteName: groupId)?.removeObject(forKey: pendingActionKey)
            }
        }

        if let str = UserDefaults.standard.string(forKey: pendingActionKey)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
            if foundRaw == nil { foundRaw = str }
            UserDefaults.standard.removeObject(forKey: pendingActionKey)
        }

        guard let rawValue = foundRaw, let action = KASHWidgetAction(rawValue: rawValue) else {
            return nil
        }
        return action
    }
}
