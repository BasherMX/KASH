import SwiftUI
import SwiftData

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettingsList: [UserSettings]
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled: Bool = false

    @State private var monthlyIncomeString: String = ""
    @State private var debtAllocationPercentage: Double = 0.60
    @State private var debtReminderDay: Int = 5
    @State private var paymentReminderDays: Int = 3
    @State private var biometricLockMandatory: Bool = true
    @State private var terminalCommissionRate: Double = 4.06
    @State private var defaultCashbackRate: Double = 10.0
    @State private var isShowingExportSheet: Bool = false
    @State private var isShowingImportPicker: Bool = false

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
                    Picker("Día del mes para corte de deuda", selection: $debtReminderDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("Día \(day)").tag(day)
                        }
                    }
                    .onChange(of: debtReminderDay) { _, newValue in
                        currentSettings.debtReminderDayOfMonth = newValue
                        try? modelContext.save()
                    }

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

                    HStack {
                        Text("Cashback Promedio (%)")
                        Spacer()
                        Text("\(defaultCashbackRate, specifier: "%.1f")%")
                    }
                } header: {
                    Label("Parámetros y Capacidad de Pago", systemImage: "chart.line.uptrend.xyaxis")
                }

                // SECCIÓN 5: COPIAS DE SEGURIDAD Y PORTABILIDAD
                Section {
                    Button {
                        isShowingExportSheet = true
                    } label: {
                        HStack {
                            Label("Exportar Respaldo Universal (ZIP Modular)", systemImage: "archivebox.fill")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        isShowingImportPicker = true
                    } label: {
                        HStack {
                            Label("Importar Respaldo (ZIP / JSON / CSV)", systemImage: "square.and.arrow.down.fill")
                            Spacer()
                        }
                    }
                } header: {
                    Label("Copias de Seguridad y Portabilidad", systemImage: "arrow.triangle.2.circlepath")
                } footer: {
                    Text("Los respaldos son 100% compatibles con hojas de cálculo y bases de datos relacionales sin bloqueo de proveedor.")
                }

                // SECCIÓN 6: PIE DE PÁGINA DEL SISTEMA (FOOTER OBLIGATORIO)
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(Color(hex: "#10B981"))
                            Text("Almacenamiento Local SwiftData Encriptado")
                                .font(.kashCaptionBold)
                                .foregroundStyle(.secondary)
                        }

                        Text("Control TDC • KASH v1.0.0 (Build 1)")
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
            .navigationTitle("Ajustes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
            .onAppear {
                loadInitialSettings()
            }
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
        debtReminderDay = s.debtReminderDayOfMonth
        paymentReminderDays = s.paymentReminderDaysBefore
        biometricLockMandatory = s.biometricLockMandatory
        terminalCommissionRate = s.terminalCommissionRate * 100
        defaultCashbackRate = s.defaultCashbackRate * 100
    }
}
