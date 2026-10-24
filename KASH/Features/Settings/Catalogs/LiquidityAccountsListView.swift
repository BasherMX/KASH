import SwiftUI
import SwiftData

// MARK: - LiquidityAccountsListView
struct LiquidityAccountsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LiquidityAccount.name) private var accounts: [LiquidityAccount]
    @State private var isAddAccountPresented = false
    @State private var selectedAccountForEdit: LiquidityAccount?
    @State private var accountToDelete: LiquidityAccount?
    @State private var isShowingDeleteAccountAlert = false

    var body: some View {
        NavigationStack {
            List {
                if accounts.isEmpty {
                    ContentUnavailableView(
                        "Sin Cuentas de Dinero Real",
                        systemImage: "banknote",
                        description: Text("Registra tus cuentas de débito, billeteras de efectivo y fondos de ahorro. Solo este saldo compone tu Liquidez Real.")
                    )
                } else {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        let filtered = accounts.filter { $0.accountType == type }
                        if !filtered.isEmpty {
                            Section(type.title) {
                                ForEach(filtered) { account in
                                    Button {
                                        selectedAccountForEdit = account
                                    } label: {
                                        LiquidityAccountRow(account: account)
                                    }
                                    .tint(.primary)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            accountToDelete = account
                                            isShowingDeleteAccountAlert = true
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cuentas de Liquidez")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddAccountPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $isAddAccountPresented) {
                LiquidityAccountEditSheet(accountToEdit: nil)
            }
            .sheet(item: $selectedAccountForEdit) { account in
                LiquidityAccountEditSheet(accountToEdit: account)
            }
            .alert("¿Eliminar Cuenta?", isPresented: $isShowingDeleteAccountAlert) {
                Button("Cancelar", role: .cancel) {
                    accountToDelete = nil
                }
                Button("Eliminar", role: .destructive) {
                    if let acc = accountToDelete {
                        modelContext.delete(acc)
                        try? modelContext.save()
                        KASHWidgetSyncService.sync(modelContext: modelContext)
                        accountToDelete = nil
                    }
                }
            } message: {
                if let acc = accountToDelete {
                    Text("Se eliminará '\(acc.name)' y su saldo registrado. Esta acción no se puede deshacer.")
                } else {
                    Text("Esta acción eliminará la cuenta seleccionada.")
                }
            }
        }
    }
}

// MARK: - LiquidityAccountRow
struct LiquidityAccountRow: View {
    let account: LiquidityAccount

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: account.colorHex))
                    .frame(width: 44, height: 44)

                Image(systemName: account.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.kashBodyBold)

                Text(account.institution)
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Disponible")
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)

                PrivacyAwareText(
                    amount: account.availableBalance,
                    font: .kashCaptionBold,
                    foregroundColor: account.availableBalance < 0 ? Color(hex: "#EF4444") : Color(hex: "#10B981")
                )
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - LiquidityAccountEditSheet
struct LiquidityAccountEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let accountToEdit: LiquidityAccount?

    @State private var name: String = ""
    @State private var institution: String = ""
    @State private var balanceString: String = ""
    @State private var selectedType: AccountType = .debit
    @State private var selectedColorHex: String = "#2563EB"
    @State private var selectedIcon: String = "banknote.fill"

    // Parámetros de Préstamo
    @State private var totalInstallments: Int = 12
    @State private var paidInstallments: Int = 0
    @State private var installmentAmountString: String = ""
    @State private var installmentFrequency: InstallmentFrequency = .monthly

    @State private var isShowingDeleteConfirmation = false

    private let quickInstallmentPresets = [6, 12, 18, 24, 36, 48, 60]

    private let availableColors = [
        "#2563EB", "#10B981", "#F59E0B", "#8B5CF6", "#06B6D4", "#EC4899", "#1E293B", "#64748B"
    ]

    private let availableIcons = [
        "banknote.fill", "creditcard.fill", "sparkles.rectangle.stack.fill", "building.columns.fill",
        "wallet.pass.fill", "safe.fill", "dollarsign.circle.fill", "chart.line.uptrend.xyaxis"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos de la Cuenta") {
                    TextField("Nombre de cuenta (ej. BBVA Nómina)", text: $name)
                    TextField("Institución emisora (ej. BBVA, Efectivo)", text: $institution)
                    TextField("Saldo Actual ($)", text: $balanceString)
                        .keyboardType(.decimalPad)

                    Picker("Tipo de Cuenta", selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                }

                if selectedType == .loan {
                    Section("Plan de Cuotas del Préstamo") {
                        Picker("Frecuencia de Cuota", selection: $installmentFrequency) {
                            ForEach(InstallmentFrequency.allCases, id: \.self) { freq in
                                Text(freq.title).tag(freq)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plazo Total de Cuotas")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(quickInstallmentPresets, id: \.self) { preset in
                                        Button {
                                            totalInstallments = preset
                                        } label: {
                                            Text("\(preset) cuotas")
                                                .font(.system(size: 11, weight: totalInstallments == preset ? .bold : .medium))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(
                                                    totalInstallments == preset ? Color(hex: "#2563EB") : Color.secondary.opacity(0.12),
                                                    in: Capsule()
                                                )
                                                .foregroundStyle(totalInstallments == preset ? .white : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }

                            HStack {
                                Text("O ingresa total de cuotas:")
                                    .font(.kashCaption)
                                Spacer()
                                TextField("Cuotas", value: $totalInstallments, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        HStack {
                            Text("Cuotas ya cubiertas / pagadas:")
                                .font(.kashCaption)
                            Spacer()
                            TextField("Pagadas", value: $paidInstallments, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Text("Monto por cuota ($)")
                            Spacer()
                            TextField("0.00", text: $installmentAmountString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 100)
                        }
                    }
                }

                Section("Color e Ícono") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paleta de Color")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableColors, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            if selectedColorHex.uppercased() == hex.uppercased() {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .onTapGesture {
                                            selectedColorHex = hex
                                        }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        HStack {
                            Text("Color personalizado:")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            ColorPicker("", selection: Binding(
                                get: { Color(hex: selectedColorHex) },
                                set: { newCol in
                                    if let h = newCol.toHex() {
                                        selectedColorHex = h
                                    }
                                }
                            ))
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color(hex: selectedColorHex) : Color.secondary.opacity(0.15))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                }
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if accountToEdit != nil {
                    Section {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Eliminar Cuenta", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(accountToEdit == nil ? "Nueva Cuenta" : "Editar Cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.endEditing()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveAccount()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("¿Eliminar Cuenta?", isPresented: $isShowingDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    if let acc = accountToEdit {
                        modelContext.delete(acc)
                        try? modelContext.save()
                        KASHWidgetSyncService.sync(modelContext: modelContext)
                        dismiss()
                    }
                }
            } message: {
                Text("Esta acción eliminará la cuenta permanentemente.")
            }
            .onAppear {
                if let acc = accountToEdit {
                    name = acc.name
                    institution = acc.institution
                    balanceString = "\(acc.availableBalance)"
                    selectedType = acc.accountType
                    selectedColorHex = acc.colorHex
                    selectedIcon = acc.iconName
                    totalInstallments = acc.totalInstallments > 0 ? acc.totalInstallments : 12
                    paidInstallments = acc.paidInstallments
                    installmentAmountString = "\(acc.installmentAmount)"
                    installmentFrequency = acc.installmentFrequency
                }
            }
        }
    }

    private func saveAccount() {
        let cleanBalance = CurrencyInputParser.parseDecimal(balanceString)
        let cleanInstallment = CurrencyInputParser.parseDecimal(installmentAmountString)

        if let acc = accountToEdit {
            acc.name = name
            acc.institution = institution
            acc.availableBalance = cleanBalance
            acc.accountType = selectedType
            acc.colorHex = selectedColorHex
            acc.iconName = selectedIcon
            acc.totalInstallments = totalInstallments
            acc.paidInstallments = paidInstallments
            acc.installmentAmount = cleanInstallment
            acc.installmentFrequency = installmentFrequency
            acc.updatedAt = Date()
        } else {
            let newAcc = LiquidityAccount(
                name: name,
                institution: institution,
                availableBalance: cleanBalance,
                accountType: selectedType,
                colorHex: selectedColorHex,
                iconName: selectedIcon,
                isActive: true,
                totalInstallments: totalInstallments,
                paidInstallments: paidInstallments,
                installmentAmount: cleanInstallment,
                installmentFrequency: installmentFrequency
            )
            modelContext.insert(newAcc)
        }

        try? modelContext.save()
        KASHWidgetSyncService.sync(modelContext: modelContext)
        dismiss()
    }
}
