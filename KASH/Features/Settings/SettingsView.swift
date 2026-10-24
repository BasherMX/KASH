import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettingsList: [UserSettings]
    @Query private var creditCards: [CreditCard]
    @Query private var liquidityAccounts: [LiquidityAccount]
    @Query private var upcomingPayments: [UpcomingPayment]
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled: Bool = false

    @FocusState private var isMonthlyIncomeFocused: Bool
    @State private var monthlyIncomeString: String = ""
    @State private var debtAllocationPercentage: Double = 0.60
    @State private var paymentReminderDays: Int = 3
    @State private var biometricLockMandatory: Bool = false

    // Widgets Gallery & Diagnostic Sheet
    @State private var isShowingWidgetsSheet: Bool = false

    // Backup & Export States
    @State private var exportURL: URL? = nil
    @State private var isShowingExportActivity: Bool = false
    @State private var isShowingImportPicker: Bool = false
    @State private var alertMessage: String = ""
    @State private var isShowingAlert: Bool = false
    @State private var isShowingDeleteConfirmationAlert: Bool = false

    @State private var isTestingNotification: Bool = false
    @State private var notificationFeedbackMessage: String? = nil
    @State private var isShowingNotificationAlert: Bool = false

    @State private var showIncomeSavedFeedback: Bool = false

    private func testNotifications() {
        isTestingNotification = true
        Task {
            let success = await NotificationManager.shared.sendTestNotification()
            await MainActor.run {
                isTestingNotification = false
                if success {
                    notificationFeedbackMessage = "¡Notificación de prueba enviada exitosamente! Recibirás la alerta en tu pantalla en un par de segundos."
                } else {
                    notificationFeedbackMessage = "No se pudieron activar las notificaciones. Por favor revisa en Ajustes de iOS > Notificaciones > KASH y asegúrate de permitir las alertas y sonidos."
                }
                isShowingNotificationAlert = true
            }
        }
    }

    @discardableResult
    private func ensureSettings() -> UserSettings {
        UserSettings.shared(in: modelContext)
    }

    private func saveMonthlyIncome(showFeedback: Bool = false) {
        let income = CurrencyInputParser.parseDecimal(monthlyIncomeString)
        UserSettings.updateMonthlyIncome(income, in: modelContext)
        if showFeedback {
            withAnimation(.easeInOut(duration: 0.2)) {
                showIncomeSavedFeedback = true
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // SECCIÓN 1: FINANZAS PERSONALES & CAPACIDAD DE PAGO
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ingreso Mensual Neto")
                            if showIncomeSavedFeedback {
                                HStack(spacing: 3) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Guardado")
                                }
                                .font(.kashMicro)
                                .foregroundStyle(Color(hex: "#10B981"))
                            }
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $monthlyIncomeString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($isMonthlyIncomeFocused)
                                .frame(minWidth: 100)
                                .onChange(of: isMonthlyIncomeFocused) { wasFocused, isFocused in
                                    if wasFocused && !isFocused {
                                        saveMonthlyIncome(showFeedback: true)
                                    } else {
                                        saveMonthlyIncome(showFeedback: false)
                                    }
                                }
                                .onChange(of: monthlyIncomeString) { _, _ in
                                    if isMonthlyIncomeFocused {
                                        saveMonthlyIncome(showFeedback: true)
                                    }
                                }
                                .onSubmit {
                                    saveMonthlyIncome(showFeedback: true)
                                }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Capacidad de pago de deuda:")
                            Spacer()
                            Text("\(Int(debtAllocationPercentage * 100))%")
                                .font(.kashBodyBold)
                                .foregroundStyle(Color(hex: "#2563EB"))
                        }
                        Slider(value: $debtAllocationPercentage, in: 0.1...1.0, step: 0.05)
                            .onChange(of: debtAllocationPercentage) { _, newValue in
                                let s = ensureSettings()
                                s.debtAllocationPercentage = newValue
                                try? modelContext.save()
                            }
                    }
                } header: {
                    Label("Finanzas Personales", systemImage: "banknote.fill")
                }

                // SECCIÓN 2: CATÁLOGOS DE CUENTAS
                Section {
                    NavigationLink {
                        CreditCardsListView()
                    } label: {
                        Label("Tarjetas de Crédito", systemImage: "creditcard.fill")
                    }

                    NavigationLink {
                        LiquidityAccountsListView()
                    } label: {
                        Label("Cuentas de Débito, Efectivo y Préstamos", systemImage: "wallet.pass.fill")
                    }

                    NavigationLink {
                        CategoriesListView()
                    } label: {
                        Label("Categorías de Movimientos", systemImage: "tag.fill")
                    }
                } header: {
                    Label("Catálogos y Cuentas", systemImage: "tray.full.fill")
                }

                // SECCIÓN 3: SEGURIDAD
                Section {
                    Toggle("Face ID / Touch ID Obligatorio", isOn: $biometricLockMandatory)
                        .onChange(of: biometricLockMandatory) { _, newValue in
                            let s = ensureSettings()
                            s.biometricLockMandatory = newValue
                            try? modelContext.save()
                        }
                } header: {
                    Label("Seguridad", systemImage: "shield.lefthalf.filled")
                }

                // SECCIÓN 4: NOTIFICACIONES & WIDGETS
                Section {
                    Picker("Avisar vencimiento de pago con", selection: $paymentReminderDays) {
                        Text("1 día de anticipación").tag(1)
                        Text("2 días de anticipación").tag(2)
                        Text("3 días de anticipación").tag(3)
                        Text("5 días de anticipación").tag(5)
                    }
                    .onChange(of: paymentReminderDays) { _, newValue in
                        let s = ensureSettings()
                        s.paymentReminderDaysBefore = newValue
                        try? modelContext.save()
                    }

                    Button {
                        testNotifications()
                    } label: {
                        HStack {
                            Label("Probar Notificaciones", systemImage: "bell.badge")
                            Spacer()
                            if isTestingNotification {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                HStack(spacing: 4) {
                                    Text("Enviar prueba")
                                        .font(.kashCaption)
                                        .foregroundStyle(Color(hex: "#2563EB"))
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: "#2563EB"))
                                }
                            }
                        }
                    }
                    .disabled(isTestingNotification)

                    Button {
                        syncAndReloadWidgets()
                        isShowingWidgetsSheet = true
                    } label: {
                        HStack {
                            Label("Sincronizar Widgets", systemImage: "rectangle.grid.2x2.fill")
                            Spacer()
                            Text(isWidgetExtensionEmbedded ? "Activos" : "Verificar")
                                .font(.kashMicro)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    (isWidgetExtensionEmbedded ? Color(hex: "#10B981") : Color(hex: "#F59E0B")).opacity(0.15),
                                    in: Capsule()
                                )
                                .foregroundStyle(isWidgetExtensionEmbedded ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Notificaciones & Widgets", systemImage: "bell.badge.fill")
                }

                // SECCIÓN 5: COPIAS DE SEGURIDAD Y PORTABILIDAD
                Section {
                    Button {
                        exportBackup()
                    } label: {
                        HStack {
                            Label("Exportar Respaldo (JSON)", systemImage: "square.and.arrow.up.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        isShowingImportPicker = true
                    } label: {
                        HStack {
                            Label("Importar Respaldo (JSON)", systemImage: "square.and.arrow.down.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Copias de Seguridad", systemImage: "arrow.triangle.2.circlepath")
                }

                // SECCIÓN 6: ZONA DE PELIGRO
                Section {
                    Button(role: .destructive) {
                        isShowingDeleteConfirmationAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Borrar todos los datos", systemImage: "trash.fill")
                                .font(.kashBodyBold)
                                .foregroundStyle(Color.red)
                            Spacer()
                        }
                    }
                } header: {
                    Label("Zona de Peligro", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.red)
                } footer: {
                    Text("⚠️ Esta acción es irreversible. Se eliminarán permanentemente todos tus datos de KASH.")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                // SECCIÓN 8: PIE DE PÁGINA DEL SISTEMA
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(Color(hex: "#10B981"))
                            Text("Almacenamiento Local SwiftData Encriptado")
                                .font(.kashCaptionBold)
                                .foregroundStyle(.secondary)
                        }

                        Text("Control TDC • KASH v1.6.0 (Build 8)")
                            .font(.kashMicro)
                            .foregroundStyle(.tertiary)

                        Text("0 KB en la nube • 100% Offline y Seguro")
                            .font(.kashMicro)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Ajustes")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        saveMonthlyIncome()
                        isMonthlyIncomeFocused = false
                        UIApplication.endEditing()
                    }
                }
            }
            .sheet(isPresented: $isShowingWidgetsSheet) {
                WidgetsGalleryPreviewSheet(
                    isExtensionEmbedded: isWidgetExtensionEmbedded,
                    onReloadRequested: {
                        syncAndReloadWidgets()
                    }
                )
            }
            .sheet(isPresented: $isShowingExportActivity) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $isShowingImportPicker,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .alert("Copia de Seguridad KASH", isPresented: $isShowingAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("Notificaciones KASH", isPresented: $isShowingNotificationAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(notificationFeedbackMessage ?? "")
            }
            .alert(
                "⚠️ ¿Eliminar todos los datos de KASH?",
                isPresented: $isShowingDeleteConfirmationAlert
            ) {
                Button("Cancelar", role: .cancel) {}
                Button("Continuar y verificar identidad", role: .destructive) {
                    confirmAndExecuteWipe()
                }
            } message: {
                Text("Esta acción es irreversible. Se eliminarán permanentemente todas tus tarjetas, cuentas, movimientos, cortes históricos y configuraciones. No se podrán recuperar.")
            }
            .onAppear {
                loadInitialSettings()
            }
            .onDisappear {
                saveMonthlyIncome()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                saveMonthlyIncome(showFeedback: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                saveMonthlyIncome()
            }
        }
    }

    private var isWidgetExtensionEmbedded: Bool {
        KASHSharedStore.isWidgetExtensionEmbedded
    }

    private func syncAndReloadWidgets() {
        KASHWidgetSyncService.sync(modelContext: modelContext)
    }

    private func exportBackup() {
        do {
            saveMonthlyIncome()
            let url = try BackupManager.shared.generateUnifiedBackupJSON(modelContext: modelContext)
            self.exportURL = url

            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
               var topVC = keyWindow.rootViewController {
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                topVC.present(activityVC, animated: true)
            } else {
                self.isShowingExportActivity = true
            }
        } catch {
            alertMessage = "Error al exportar respaldo: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            do {
                let summary = try BackupManager.shared.importBackup(from: selectedURL, modelContext: modelContext)
                alertMessage = summary
                isShowingAlert = true
                loadInitialSettings()
                syncAndReloadWidgets()
            } catch {
                alertMessage = "Error al importar el archivo: \(error.localizedDescription)"
                isShowingAlert = true
            }
        case .failure(let error):
            alertMessage = "No se pudo seleccionar el archivo: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }

    private func loadInitialSettings() {
        let s = ensureSettings()
        if !isMonthlyIncomeFocused {
            monthlyIncomeString = s.monthlyIncome > 0 ? "\(s.monthlyIncome)" : ""
        }
        debtAllocationPercentage = s.debtAllocationPercentage
        paymentReminderDays = s.paymentReminderDaysBefore
        biometricLockMandatory = s.biometricLockMandatory
    }

    private func confirmAndExecuteWipe() {
        DataResetManager.shared.authenticateAndWipe(
            modelContext: modelContext,
            onSuccess: {
                loadInitialSettings()
                appState.selectedTab = .dashboard
                appState.isOnboardingPresented = true
            },
            onFailure: { error in
                if let error = error {
                    alertMessage = "Autenticación no completada: \(error.localizedDescription)"
                    isShowingAlert = true
                }
            }
        )
    }
}

// MARK: - WidgetsGalleryPreviewSheet
struct WidgetsGalleryPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let isExtensionEmbedded: Bool
    let onReloadRequested: () -> Void

    @State private var reloadFeedbackShown = false
    private var snapshot: KASHWidgetSnapshot {
        KASHSharedStore.loadSnapshot()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Diagnóstico del estado del plugin KASHWidgets.appex
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: isExtensionEmbedded ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(isExtensionEmbedded ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(isExtensionEmbedded ? "Extensión KASHWidgets Instalada" : "Extensión Removida al Instalar (Sideloadly)")
                                    .font(.kashBodyBold)
                                Text(
                                    isExtensionEmbedded
                                        ? "El binario KASHWidgets.appex está activo dentro de la app."
                                        : "Tu herramienta de instalación (Sideloadly) eliminó la carpeta PlugIns al firmar con cuenta gratuita."
                                )
                                .font(.kashMicro)
                                .foregroundStyle(.secondary)
                            }
                        }

                        if !isExtensionEmbedded {
                            Divider()
                            VStack(alignment: .leading, spacing: 6) {
                                Text("¿Cómo hacer que aparezcan en la pantalla de inicio desde Sideloadly?")
                                    .font(.kashCaptionBold)
                                    .foregroundStyle(Color(hex: "#F59E0B"))
                                Text("1. En Sideloadly (Windows), haz clic en 'Advanced Options'.\n2. Desmarca la casilla 'Remove App Extensions (PlugIns)'.\n3. Reinstala KASH.ipa y reinicia tu iPhone para que iOS indexe los 3 widgets en la galería.")
                                    .font(.kashMicro)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Divider()
                            Text("Si acabas de instalar KASH y aún no aparece al buscar 'KASH' en la galería de widgets de iOS, pulsa el botón inferior y reinicia tu iPhone una vez para actualizar el caché de SpringBoard.")
                                .font(.kashMicro)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            onReloadRequested()
                            withAnimation {
                                reloadFeedbackShown = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: reloadFeedbackShown ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                                Text(reloadFeedbackShown ? "¡Widgets Sincronizados con WidgetCenter!" : "Sincronizar y Registrar Widgets Ahora")
                            }
                            .font(.kashCaptionBold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#2563EB"), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.white)
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                    // Vista previa en vivo de los Widgets
                    Text("Vista Previa en Vivo de tus Widgets")
                        .font(.kashTitleMedium)

                    // Preview Small
                    VStack(alignment: .leading, spacing: 6) {
                        Text("1. Widget Pequeño (2x2) — Resumen de Deuda")
                            .font(.kashCaptionBold)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundStyle(Color(hex: "#3B82F6"))
                                Text("DEUDA TOTAL")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            Text(snapshot.totalDebt.formatted(.currency(code: "MXN")))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Spacer()
                            Text("🟢 \(snapshot.healthStatus) (\(Int(snapshot.utilizationRatio * 100))% uso)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "#10B981"))
                        }
                        .padding(16)
                        .frame(width: 170, height: 155, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
                    }

                    // Preview Medium Interactivo
                    VStack(alignment: .leading, spacing: 6) {
                        Text("2. Widget Mediano Interactivo (4x2) — Acciones Rápidas")
                            .font(.kashCaptionBold)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("💳 DEUDA TOTAL")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Text(snapshot.totalDebt.formatted(.currency(code: "MXN")))
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                }
                                Spacer()
                                VStack(alignment: .center, spacing: 2) {
                                    Text("% USO")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Text("\(Int(snapshot.utilizationRatio * 100))%")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("SALUD BURÓ")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Text("🟢 \(snapshot.healthStatus)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: "#10B981"))
                                }
                            }
                            Divider()
                            HStack(spacing: 8) {
                                Label("Gasto", systemImage: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(Color(hex: "#EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(Color(hex: "#EF4444"))

                                Label("Ingreso", systemImage: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(Color(hex: "#10B981").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(Color(hex: "#10B981"))

                                Label("Pagar", systemImage: "creditcard")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(Color(hex: "#2563EB"))
                            }
                        }
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Widgets KASH")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - UIActivityViewController Wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
