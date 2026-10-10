import SwiftUI
import SwiftData

// MARK: - LiquidityAccountsListView
struct LiquidityAccountsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LiquidityAccount.name) private var accounts: [LiquidityAccount]
    @State private var isAddAccountPresented = false
    @State private var selectedAccountForEdit: LiquidityAccount?

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
                                }
                                .onDelete { indexSet in
                                    deleteAccounts(offsets: indexSet, from: filtered)
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
        }
    }

    private func deleteAccounts(offsets: IndexSet, from list: [LiquidityAccount]) {
        for index in offsets {
            let item = list[index]
            modelContext.delete(item)
        }
        try? modelContext.save()
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

                Section("Color e Ícono") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if selectedColorHex == hex {
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
            }
            .scrollDismissesKeyboard(.interactively)
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
            .onAppear {
                if let acc = accountToEdit {
                    name = acc.name
                    institution = acc.institution
                    balanceString = "\(acc.availableBalance)"
                    selectedType = acc.accountType
                    selectedColorHex = acc.colorHex
                    selectedIcon = acc.iconName
                }
            }
        }
    }

    private func saveAccount() {
        let cleanBalance = Decimal(string: balanceString.replacingOccurrences(of: ",", with: "")) ?? 0

        if let acc = accountToEdit {
            acc.name = name
            acc.institution = institution
            acc.availableBalance = cleanBalance
            acc.accountType = selectedType
            acc.colorHex = selectedColorHex
            acc.iconName = selectedIcon
            acc.updatedAt = Date()
        } else {
            let newAcc = LiquidityAccount(
                name: name,
                institution: institution,
                availableBalance: cleanBalance,
                accountType: selectedType,
                colorHex: selectedColorHex,
                iconName: selectedIcon
            )
            modelContext.insert(newAcc)
        }

        try? modelContext.save()
        dismiss()
    }
}
