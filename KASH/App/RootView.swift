import SwiftUI
import SwiftData

// MARK: - App Navigation Tabs
enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case transactions = "transactions"
    case batches = "batches"
    case analytics = "analytics"
    case settings = "settings"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Resumen"
        case .transactions: return "Movimientos"
        case .batches: return "Cortes"
        case .analytics: return "Análisis"
        case .settings: return "Ajustes"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .transactions: return "list.bullet.rectangle.portrait.fill"
        case .batches: return "calendar.badge.clock"
        case .analytics: return "brain.head.profile"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - AppState
@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard
    @Published var isQuickTransactionPresented: Bool = false
    @Published var isCardPaymentPresented: Bool = false
    @Published var isBatchLogPresented: Bool = false
    @Published var isOnboardingPresented: Bool = false
    @Published var isPrivacyBlurred: Bool = false
}

// MARK: - RootView
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var authManager = BiometricAuthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Query private var userSettings: [UserSettings]
    @Query private var creditCards: [CreditCard]
    @Query private var liquidityAccounts: [LiquidityAccount]

    var body: some View {
        ZStack {
            TabView(selection: $appState.selectedTab) {
                DashboardView()
                    .tabItem {
                        Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon)
                    }
                    .tag(AppTab.dashboard)

                TransactionsListView()
                    .tabItem {
                        Label(AppTab.transactions.title, systemImage: AppTab.transactions.icon)
                    }
                    .tag(AppTab.transactions)

                BatchesHistoryView()
                    .tabItem {
                        Label(AppTab.batches.title, systemImage: AppTab.batches.icon)
                    }
                    .tag(AppTab.batches)

                AnalyticsView()
                    .tabItem {
                        Label(AppTab.analytics.title, systemImage: AppTab.analytics.icon)
                    }
                    .tag(AppTab.analytics)

                SettingsView()
                    .tabItem {
                        Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                    }
                    .tag(AppTab.settings)
            }
            .tint(Color(hex: "#2563EB"))

            // Privacy Blur / Biometric Lock Shield
            let isBiometricMandatory = userSettings.first?.biometricLockMandatory ?? false
            if appState.isPrivacyBlurred || (isBiometricMandatory && !authManager.isUnlocked) {
                PrivacyShieldView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authManager.isUnlocked)
        .animation(.easeInOut(duration: 0.2), value: appState.isPrivacyBlurred)
        .sheet(isPresented: $appState.isQuickTransactionPresented) {
            QuickTransactionSheet()
        }
        .sheet(isPresented: $appState.isCardPaymentPresented) {
            CardPaymentSheet()
        }
        .sheet(isPresented: $appState.isBatchLogPresented) {
            BatchLogSheet()
        }
        .fullScreenCover(isPresented: $appState.isOnboardingPresented) {
            OnboardingView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(to: newPhase)
        }
        .onAppear {
            checkFirstLaunchOnboarding()
            triggerInitialBiometricAuth()
        }
    }

    private func handleScenePhaseChange(to newPhase: ScenePhase) {
        let isBiometricMandatory = userSettings.first?.biometricLockMandatory ?? false
        switch newPhase {
        case .active:
            appState.isPrivacyBlurred = false
            if isBiometricMandatory && !authManager.isUnlocked {
                triggerInitialBiometricAuth()
            }
        case .inactive:
            // Activar desenfoque inmediato para ocultar datos en el App Switcher
            appState.isPrivacyBlurred = true
        case .background:
            appState.isPrivacyBlurred = true
            if isBiometricMandatory {
                authManager.lockApp()
            }
        @unknown default:
            break
        }
    }

    private func triggerInitialBiometricAuth() {
        let isBiometricMandatory = userSettings.first?.biometricLockMandatory ?? false
        if isBiometricMandatory {
            Task {
                _ = await authManager.authenticate()
            }
        } else {
            authManager.isUnlocked = true
        }
    }

    private func checkFirstLaunchOnboarding() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompletedOnboarding && creditCards.isEmpty && liquidityAccounts.isEmpty {
            appState.isOnboardingPresented = true
        }
    }
}
