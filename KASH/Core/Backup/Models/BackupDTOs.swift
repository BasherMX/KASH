import Foundation

// MARK: - Manifiesto Canónico de Respaldo KASH
struct BackupManifest: Codable {
    let schemaVersion: String
    let appVersion: String
    let buildNumber: Int
    let exportedAt: String
    let deviceModel: String
    let entityCounts: EntityCounts
    let checksumSHA256: String

    struct EntityCounts: Codable {
        let creditCards: Int
        let liquidityAccounts: Int
        let categories: Int
        let monthlyRecords: Int
        let transactions: Int
        let upcomingPayments: Int
    }
}

// MARK: - Paquete Universal Completo de Respaldo KASH
struct KASHBackupPackage: Codable {
    let manifest: BackupManifest
    let settings: UserSettingsDTO?
    let creditCards: [CreditCardDTO]
    let liquidityAccounts: [LiquidityAccountDTO]
    let categories: [CategoryDTO]
    let monthlyRecords: [MonthlyRecordDTO]
    let upcomingPayments: [UpcomingPaymentDTO]
    let transactions: [TransactionDTO]
}

// MARK: - DTOs para Serialización JSON Normalizada
struct UserSettingsDTO: Codable {
    let monthlyIncome: Double
    let debtAllocationPercentage: Double
    let debtReminderDayOfMonth: Int?
    let paymentReminderDaysBefore: Int
    let biometricLockMandatory: Bool
    let isPrivacyModeEnabled: Bool
    let terminalCommissionRate: Double?
}

struct CreditCardDTO: Codable {
    let id: String
    let name: String
    let institution: String
    let creditLimit: Double
    let cutoffDay: Int
    let paymentDueDay: Int
    let annualInterestRate: Double
    let recommendedStrategy: String?
    let colorHex: String
    let iconName: String
    let isActive: Bool
    let displayOrder: Int
    let createdAt: String
}

struct LiquidityAccountDTO: Codable {
    let id: String
    let name: String
    let institution: String
    let availableBalance: Double
    let accountTypeRaw: String
    let colorHex: String
    let iconName: String
    let isActive: Bool
    let updatedAt: String
    let totalInstallments: Int?
    let paidInstallments: Int?
    let installmentAmount: Double?
    let installmentFrequencyRaw: String?
}

struct CategoryDTO: Codable {
    let id: String
    let name: String
    let iconName: String
    let colorHex: String
    let categoryTypeRaw: String
    let isDefault: Bool
}

struct MonthlyRecordDTO: Codable {
    let id: String
    let periodDate: String
    let notes: String?
    let createdAt: String
    let balances: [CardBalanceDTO]
}

struct CardBalanceDTO: Codable {
    let id: String
    let cardId: String
    let cardName: String
    let balanceUsed: Double
    let recordedAt: String
}

struct UpcomingPaymentDTO: Codable {
    let id: String
    let cardId: String?
    let concept: String
    let dueDate: String
    let minimumPayment: Double
    let fullPaymentNoInterest: Double
    let actualAmountToPay: Double
    let statusRaw: String
    let reminderDaysBefore: Int?
    let targetMonth: Int?
    let targetYear: Int?
}

struct TransactionDTO: Codable {
    let id: String
    let concept: String
    let amount: Double
    let transactionDate: String
    let typeRaw: String
    let notes: String?
    let cardId: String?
    let liquidityAccountId: String?
    let destinationCardId: String?
    let destinationLiquidityAccountId: String?
    let categoryId: String?
}
