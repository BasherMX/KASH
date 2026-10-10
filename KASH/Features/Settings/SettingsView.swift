import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettingsList: [UserSettings]
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled: Bool = false

    @State private var monthlyIncomeString: String = ""
    @State private var debtAllocationPercentage: Double = 0.60
    @State private var paymentReminderDays: Int = 3
    @State private var biometricLockMandatory: Bool = false
    @State private var terminalCommissionRate: Double = 4.06

    // Backup & Export States
    @State private var exportURL: URL? = nil
    @State private var isShowingExportActivity: Bool = false
    @State private var isShowingImportPicker: Bool = false
    @State private var alertMessage: String = ""
    @State private var isShowingAlert: Bool = false

    private var currentSettings: UserSettings {
        userSettingsList.first ?? UserSettings()
    }

    var body: some View {
        NavigationStack {
            Form {
                // SECCIÓN 1: SEGURIDAD & PRIVACIDAD
                Section {
                    Toggle("Face ID / Touch ID Obligatorio", isOn: $biometricLockMandatory)
                        .onChange(of: biometricLockMandatory) { _, newValue in
                            currentSettings.biometricLockMandatory = newValue
                            try? modelContext.save()
                        }

                    Toggle("Ocultar Saldos por Defecto (Modo 👁️)", isOn: $isPrivacyModeEnabled)
                        .onChange(of: isPrivacyModeEnabled) { _, newValue in
                            currentSettings.isPrivacyModeEnabled = newValue
                            try? modelContext.save()
                        }
                } header: {
                    Label("Seguridad & Privacidad", systemImage: "shield.lefthalf.filled")
                } footer: {
                    Text("Por defecto, la autenticación biométrica está desactivada y solo se solicitará si decides activarla aquí.")
                }

                // SECCIÓN 2: CATÁLOGOS DE CUENTAS Y PASIVOS
                Section {
                    NavigationLink {
                        CreditCardsListView()
                    } label: {
                        Label("Tarjetas de Crédito", systemImage: "creditcard.fill")
                    }

                    NavigationLink {
                        LiquidityAccountsListView()
                    } label: {
                        Label("Cuentas de Débito, Efectivo y Préstamos", systemImage: "banknote.fill")
                    }

                    NavigationLink {
                        CategoriesListView()
                    } label: {
                        Label("Categorías de Movimientos", systemImage: "tag.fill")
                    }
                } header: {
                    Label("Catálogos y Cuentas", systemImage: "tray.full.fill")
                }

                // SECCIÓN 3: NOTIFICACIONES Y RECORDATORIOS
                Section {
                    Picker("Avisar vencimiento de pago con", selection: $paymentReminderDays) {
                        Text("1 día de anticipación").tag(1)
                        Text("2 días de anticipación").tag(2)
                        Text("3 días de anticipación").tag(3)
                        Text("5 días de anticipación").tag(5)
                    }
                    .onChange(of: paymentReminderDays) { _, newValue in
                        currentSettings.paymentReminderDaysBefore = newValue
                        try? modelContext.save()
                    }
                } header: {
                    Label("Notificaciones y Recordatorios", systemImage: "bell.badge.fill")
                } footer: {
                    Text("Los días de corte se configuran de forma específica en cada tarjeta.")
                }

                // SECCIÓN 4: PARÁMETROS DE SIMULADORES Y FINANZAS
                Section {
                    HStack {
                        Text("Ingreso Mensual Neto")
                        Spacer()
                        TextField("$0.00", text: $monthlyIncomeString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                let income = Decimal(string: monthlyIncomeString.replacingOccurrences(of: ",", with: "")) ?? 0
                                currentSettings.monthlyIncome = income
                                try? modelContext.save()
                            }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("% Sueldo para amortización:")
                            Spacer()
                            Text("\(Int(debtAllocationPercentage * 100))%")
                                .font(.kashBodyBold)
                                .foregroundStyle(Color(hex: "#2563EB"))
                        }
                        Slider(value: $debtAllocationPercentage, in: 0.1...1.0, step: 0.05)
                            .onChange(of: debtAllocationPercentage) { _, newValue in
                                currentSettings.debtAllocationPercentage = newValue
                                try? modelContext.save()
                            }
                    }

                    HStack {
                        Text("Comisión Terminal (%)")
                        Spacer()
                        Text("\(terminalCommissionRate, specifier: "%.2f")%")
                    }
                } header: {
                    Label("Parámetros y Capacidad de Pago", systemImage: "chart.line.uptrend.xyaxis")
                }

                // SECCIÓN 5: COPIAS DE SEGURIDAD Y PORTABILIDAD
                Section {
                    Button {
                        exportBackup()
                    } label: {
                        HStack {
                            Label("Exportar Respaldo Universal (JSON)", systemImage: "square.and.arrow.up.fill")
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
                    Label("Copias de Seguridad y Portabilidad", systemImage: "arrow.triangle.2.circlepath")
                } footer: {
                    Text("Los respaldos son 100% compatibles con JSON universal sin bloqueo de proveedor. Puedes guardar en Archivos, compartir vía AirDrop o restaurar en cualquier momento.")
                }

                // SECCIÓN 6: PIE DE PÁGINA DEL SISTEMA
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(Color(hex: "#10B981"))
                            Text("Almacenamiento Local SwiftData Encriptado")
                                .font(.kashCaptionBold)
                                .foregroundStyle(.secondary)
                        }

                        Text("Control TDC • KASH v1.2.0 (Build 3)")
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
                        UIApplication.endEditing()
                    }
                }
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
            .onAppear {
                loadInitialSettings()
            }
        }
    }

    private func exportBackup() {
        do {
            let url = try BackupManager.shared.generateUnifiedBackupJSON(modelContext: modelContext)
            self.exportURL = url

            // Presentar nativamente en el view controller superior para garantizar apertura
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
        if userSettingsList.isEmpty {
            let initial = UserSettings()
            modelContext.insert(initial)
            try? modelContext.save()
        }

        let s = currentSettings
        monthlyIncomeString = s.monthlyIncome > 0 ? "\(s.monthlyIncome)" : ""
        debtAllocationPercentage = s.debtAllocationPercentage
        paymentReminderDays = s.paymentReminderDaysBefore
        biometricLockMandatory = s.biometricLockMandatory
        terminalCommissionRate = s.terminalCommissionRate * 100
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
