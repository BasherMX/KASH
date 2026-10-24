import SwiftUI
import SwiftData

// MARK: - QuickTransactionSheet
/// Captura y edición rápida de transacciones: Compras y Gastos (en tarjeta o débito) e Ingresos
/// Incorpora selección inteligente por frecuencia de uso, autocompletado predictivo de conceptos y
/// deducción/actualización inmediata del saldo deudor en tarjetas de crédito.
struct QuickTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingTransaction: Transaction? = nil
    var initialType: TransactionType = .expense

    @Query private var creditCards: [CreditCard]
    @Query private var liquidityAccounts: [LiquidityAccount]
    @Query private var categories: [TransactionCategory]
    @Query(sort: \Transaction.transactionDate, order: .reverse) private var pastTransactions: [Transaction]

    @State private var concept: String = ""
    @State private var amountString: String = ""
    @State private var transactionDate: Date = Date()
    @State private var transactionType: TransactionType = .expense
    @State private var selectedPaymentMethod: PaymentMethod = .creditCard
    @State private var selectedCardId: UUID?
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var notes: String = ""

    enum PaymentMethod: String, CaseIterable {
        case creditCard = "Tarjeta de Crédito"
        case liquidity = "Cuenta / Efectivo"
    }

    private var isEditing: Bool {
        editingTransaction != nil
    }

    // MARK: - Inteligencia de Frecuencia de Uso
    private var cardUsageFrequencies: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for tx in pastTransactions {
            if let cid = tx.creditCard?.id {
                counts[cid, default: 0] += 1
            }
        }
        return counts
    }

    private var accountUsageFrequencies: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for tx in pastTransactions {
            if let aid = tx.liquidityAccount?.id {
                counts[aid, default: 0] += 1
            }
        }
        return counts
    }

    private var categoryUsageFrequencies: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for tx in pastTransactions {
            if let catId = tx.category?.id {
                counts[catId, default: 0] += 1
            }
        }
        return counts
    }

    private var sortedCreditCards: [CreditCard] {
        creditCards.filter { $0.isActive }.sorted {
            (cardUsageFrequencies[$0.id] ?? 0) > (cardUsageFrequencies[$1.id] ?? 0)
        }
    }

    private var sortedLiquidityAccounts: [LiquidityAccount] {
        liquidityAccounts.filter { $0.isActive && $0.accountType != .loan }.sorted {
            (accountUsageFrequencies[$0.id] ?? 0) > (accountUsageFrequencies[$1.id] ?? 0)
        }
    }

    private var sortedCategories: [TransactionCategory] {
        let filtered = categories.filter { $0.categoryType == transactionType }
        return filtered.sorted {
            (categoryUsageFrequencies[$0.id] ?? 0) > (categoryUsageFrequencies[$1.id] ?? 0)
        }
    }

    // MARK: - Autocompletado Predictivo de Conceptos
    private var conceptSuggestions: [String] {
        let trimmed = concept.trimmingCharacters(in: .whitespaces)
        let uniqueConcepts: [String] = {
            var seen = Set<String>()
            var ordered: [String] = []
            for tx in pastTransactions {
                let name = tx.concept.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty, !seen.contains(name.lowercased()) else { continue }
                seen.insert(name.lowercased())
                ordered.append(name)
            }
            return ordered
        }()

        if trimmed.isEmpty {
            return Array(uniqueConcepts.prefix(5))
        } else {
            return uniqueConcepts.filter {
                $0.localizedCaseInsensitiveContains(trimmed) && $0.lowercased() != trimmed.lowercased()
            }
        }
    }

    private func applyConceptSuggestion(_ text: String) {
        concept = text
        // Encontrar la categoría más frecuente para este concepto
        if let matchingTx = pastTransactions.first(where: { $0.concept.localizedCaseInsensitiveCompare(text) == .orderedSame }) {
            if let cat = matchingTx.category, cat.categoryType == transactionType {
                selectedCategoryId = cat.id
            }
            if transactionType == .expense {
                if let card = matchingTx.creditCard {
                    selectedPaymentMethod = .creditCard
                    selectedCardId = card.id
                } else if let acc = matchingTx.liquidityAccount {
                    selectedPaymentMethod = .liquidity
                    selectedAccountId = acc.id
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // TIPO DE MOVIMIENTO
                Section {
                    Picker("Tipo", selection: $transactionType) {
                        Text("Gasto / Compra").tag(TransactionType.expense)
                        Text("Ingreso").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: transactionType) { _, newType in
                        if let firstCat = sortedCategories.first {
                            selectedCategoryId = firstCat.id
                        }
                    }
                }

                // IMPORTE Y CONCEPTO CON AUTOCOMPLETADO
                Section("Datos del Movimiento") {
                    HStack {
                        Text("$")
                            .font(.kashAmountLarge)
                            .foregroundStyle(transactionType == .expense ? Color(hex: "#EF4444") : Color(hex: "#10B981"))
                        TextField("0.00", text: $amountString)
                            .font(.kashAmountLarge)
                            .keyboardType(.decimalPad)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Concepto (ej. Despensa, Gasolina)", text: $concept)

                        // Chips de sugerencia predictiva
                        if !conceptSuggestions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(conceptSuggestions.prefix(6), id: \.self) { sug in
                                        Button {
                                            applyConceptSuggestion(sug)
                                        } label: {
                                            HStack(spacing: 3) {
                                                Image(systemName: "sparkles")
                                                    .font(.system(size: 9))
                                                Text(sug)
                                                    .font(.system(size: 11, weight: .medium))
                                            }
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 4)
                                            .background(Color(hex: "#2563EB").opacity(0.12), in: Capsule())
                                            .foregroundStyle(Color(hex: "#2563EB"))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    DatePicker("Fecha", selection: $transactionDate, displayedComponents: [.date, .hourAndMinute])
                }

                // ORIGEN O DESTINO INTELIGENTE
                if transactionType == .expense {
                    Section("Método de Pago") {
                        Picker("Medio", selection: $selectedPaymentMethod) {
                            ForEach(PaymentMethod.allCases, id: \.self) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                        .pickerStyle(.segmented)

                        if selectedPaymentMethod == .creditCard {
                            Picker("Tarjeta de Crédito", selection: $selectedCardId) {
                                Text("Seleccionar Tarjeta").tag(Optional<UUID>.none)
                                ForEach(sortedCreditCards) { card in
                                    HStack {
                                        Text(card.name)
                                        Spacer()
                                        if let count = cardUsageFrequencies[card.id], count > 0 {
                                            Text("(\(count) usos)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .tag(Optional(card.id))
                                }
                            }
                        } else {
                            Picker("Cuenta de Débito / Efectivo", selection: $selectedAccountId) {
                                Text("Seleccionar Cuenta").tag(Optional<UUID>.none)
                                ForEach(sortedLiquidityAccounts) { acc in
                                    HStack {
                                        Text("\(acc.name) ($\(acc.availableBalance))")
                                        Spacer()
                                        if let count = accountUsageFrequencies[acc.id], count > 0 {
                                            Text("(\(count) usos)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .tag(Optional(acc.id))
                                }
                            }
                        }
                    }
                } else {
                    // Ingreso
                    Section("Cuenta Destino del Ingreso") {
                        Picker("Cuenta a Recibir", selection: $selectedAccountId) {
                            Text("Seleccionar Cuenta").tag(Optional<UUID>.none)
                            ForEach(sortedLiquidityAccounts) { acc in
                                HStack {
                                    Text("\(acc.name) ($\(acc.availableBalance))")
                                    Spacer()
                                    if let count = accountUsageFrequencies[acc.id], count > 0 {
                                        Text("(\(count) usos)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(Optional(acc.id))
                            }
                        }
                    }
                }

                // CATEGORÍA INTELIGENTE
                Section("Clasificación") {
                    Picker("Categoría", selection: $selectedCategoryId) {
                        Text("Sin Categoría").tag(Optional<UUID>.none)
                        ForEach(sortedCategories) { cat in
                            HStack {
                                Image(systemName: cat.iconName)
                                Text(cat.name)
                                Spacer()
                                if let count = categoryUsageFrequencies[cat.id], count > 0 {
                                    Text("(\(count) usos)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(Optional(cat.id))
                        }
                    }

                    TextField("Notas adicionales (opcional)", text: $notes)
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Editar Movimiento" : (transactionType == .expense ? "Nuevo Gasto" : "Nuevo Ingreso"))
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
                        saveTransaction()
                    }
                    .disabled(concept.trimmingCharacters(in: .whitespaces).isEmpty || amountString.isEmpty)
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }

    private func setupInitialValues() {
        if let tx = editingTransaction {
            concept = tx.concept
            amountString = "\(tx.amount)"
            transactionDate = tx.transactionDate
            transactionType = tx.type
            if tx.creditCard != nil {
                selectedPaymentMethod = .creditCard
                selectedCardId = tx.creditCard?.id
            } else if tx.liquidityAccount != nil {
                selectedPaymentMethod = .liquidity
                selectedAccountId = tx.liquidityAccount?.id
            }
            selectedCategoryId = tx.category?.id
            notes = tx.notes ?? ""
        } else {
            transactionType = initialType
            if selectedCardId == nil {
                selectedCardId = sortedCreditCards.first?.id
            }
            if selectedAccountId == nil {
                selectedAccountId = sortedLiquidityAccounts.first?.id
            }
            if selectedCategoryId == nil {
                selectedCategoryId = sortedCategories.first?.id
            }
        }
    }

    private func saveTransaction() {
        let amount = CurrencyInputParser.parseDecimal(amountString)
        let card = creditCards.first(where: { $0.id == selectedCardId })
        let account = liquidityAccounts.first(where: { $0.id == selectedAccountId })
        let category = categories.first(where: { $0.id == selectedCategoryId })

        if let tx = editingTransaction {
            // 1. Revertir impacto previo en liquidez
            if tx.type == .expense, let oldAcc = tx.liquidityAccount {
                oldAcc.availableBalance += tx.amount
            } else if tx.type == .income, let oldAcc = tx.liquidityAccount {
                oldAcc.availableBalance -= tx.amount
            }

            // 2. Revertir impacto previo en saldo deudor de TDC si correspondía
            if tx.type == .expense, let oldCard = tx.creditCard, let latest = oldCard.sortedBalances.first {
                latest.balanceUsed = max(0 as Decimal, latest.balanceUsed - tx.amount)
            }

            // Actualizar campos
            tx.concept = concept.trimmingCharacters(in: .whitespaces)
            tx.amount = amount
            tx.transactionDate = transactionDate
            tx.type = transactionType
            tx.notes = notes.isEmpty ? nil : notes
            tx.creditCard = (transactionType == .expense && selectedPaymentMethod == .creditCard) ? card : nil
            tx.liquidityAccount = (transactionType == .income || (transactionType == .expense && selectedPaymentMethod == .liquidity)) ? account : nil
            tx.category = category

            // 3. Aplicar nuevo impacto en liquidez
            if transactionType == .expense && selectedPaymentMethod == .liquidity, let acc = account {
                acc.availableBalance -= amount
                acc.updatedAt = Date()
            } else if transactionType == .income, let acc = account {
                acc.availableBalance += amount
                acc.updatedAt = Date()
            }

            // 4. Aplicar nuevo impacto en tarjeta de crédito (aumentar deuda)
            if transactionType == .expense && selectedPaymentMethod == .creditCard, let card = card {
                if let latest = card.sortedBalances.first {
                    latest.balanceUsed += amount
                }
            }
        } else {
            let tx = Transaction(
                concept: concept.trimmingCharacters(in: .whitespaces),
                amount: amount,
                transactionDate: transactionDate,
                type: transactionType,
                notes: notes.isEmpty ? nil : notes,
                creditCard: (transactionType == .expense && selectedPaymentMethod == .creditCard) ? card : nil,
                liquidityAccount: (transactionType == .income || (transactionType == .expense && selectedPaymentMethod == .liquidity)) ? account : nil,
                category: category
            )
            modelContext.insert(tx)

            // Impacto atómico en saldos si fue con cuenta de liquidez
            if transactionType == .expense && selectedPaymentMethod == .liquidity, let acc = account {
                acc.availableBalance -= amount
                acc.updatedAt = Date()
            } else if transactionType == .income, let acc = account {
                acc.availableBalance += amount
                acc.updatedAt = Date()
            }

            // Impacto atómico en TDC: incrementar deuda y descontar crédito disponible
            if transactionType == .expense && selectedPaymentMethod == .creditCard, let card = card {
                if let latest = card.sortedBalances.first {
                    latest.balanceUsed += amount
                }
            }
        }

        try? modelContext.save()
        KASHWidgetSyncService.sync(modelContext: modelContext)
        dismiss()
    }
}
