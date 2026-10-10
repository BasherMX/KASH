import SwiftUI
import SwiftData

// MARK: - QuickTransactionSheet
/// Captura y edición rápida de transacciones: Compras y Gastos (en tarjeta o débito) e Ingresos
struct QuickTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingTransaction: Transaction? = nil

    @Query private var creditCards: [CreditCard]
    @Query private var liquidityAccounts: [LiquidityAccount]
    @Query private var categories: [TransactionCategory]

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
                }

                // IMPORTE Y CONCEPTO
                Section("Datos del Movimiento") {
                    HStack {
                        Text("$")
                            .font(.kashAmountLarge)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountString)
                            .font(.kashAmountLarge)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Concepto (ej. Despensa, Gasolina)", text: $concept)

                    DatePicker("Fecha", selection: $transactionDate, displayedComponents: [.date, .hourAndMinute])
                }

                // ORIGEN O DESTINO
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
                                ForEach(creditCards.filter { $0.isActive }) { card in
                                    Text(card.name).tag(Optional(card.id))
                                }
                            }
                        } else {
                            Picker("Cuenta de Débito / Efectivo", selection: $selectedAccountId) {
                                Text("Seleccionar Cuenta").tag(Optional<UUID>.none)
                                ForEach(liquidityAccounts.filter { $0.isActive }) { acc in
                                    Text("\(acc.name) ($\(acc.availableBalance))").tag(Optional(acc.id))
                                }
                            }
                        }
                    }
                } else {
                    // Ingreso
                    Section("Cuenta Destino del Ingreso") {
                        Picker("Cuenta a Recibir", selection: $selectedAccountId) {
                            Text("Seleccionar Cuenta").tag(Optional<UUID>.none)
                            ForEach(liquidityAccounts.filter { $0.isActive }) { acc in
                                Text("\(acc.name) ($\(acc.availableBalance))").tag(Optional(acc.id))
                            }
                        }
                    }
                }

                // CATEGORÍA
                Section("Clasificación") {
                    let filteredCats = categories.filter { $0.categoryType == transactionType }
                    Picker("Categoría", selection: $selectedCategoryId) {
                        Text("Sin Categoría").tag(Optional<UUID>.none)
                        ForEach(filteredCats) { cat in
                            HStack {
                                Image(systemName: cat.iconName)
                                Text(cat.name)
                            }
                            .tag(Optional(cat.id))
                        }
                    }

                    TextField("Notas adicionales (opcional)", text: $notes)
                }
            }
            .scrollDismissesKeyboard(.interactively)
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
            if selectedCardId == nil {
                selectedCardId = creditCards.first?.id
            }
            if selectedAccountId == nil {
                selectedAccountId = liquidityAccounts.first?.id
            }
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first(where: { $0.categoryType == transactionType })?.id
            }
        }
    }

    private func saveTransaction() {
        let amount = Decimal(string: amountString.replacingOccurrences(of: ",", with: "")) ?? 0
        let card = creditCards.first(where: { $0.id == selectedCardId })
        let account = liquidityAccounts.first(where: { $0.id == selectedAccountId })
        let category = categories.first(where: { $0.id == selectedCategoryId })

        if let tx = editingTransaction {
            // Revertir balance anterior si involucraba cuenta de liquidez
            if tx.type == .expense, let oldAcc = tx.liquidityAccount {
                oldAcc.availableBalance += tx.amount
            } else if tx.type == .income, let oldAcc = tx.liquidityAccount {
                oldAcc.availableBalance -= tx.amount
            }

            // Actualizar campos
            tx.concept = concept
            tx.amount = amount
            tx.transactionDate = transactionDate
            tx.type = transactionType
            tx.notes = notes.isEmpty ? nil : notes
            tx.creditCard = (transactionType == .expense && selectedPaymentMethod == .creditCard) ? card : nil
            tx.liquidityAccount = (transactionType == .income || (transactionType == .expense && selectedPaymentMethod == .liquidity)) ? account : nil
            tx.category = category

            // Aplicar nuevo impacto en liquidez
            if transactionType == .expense && selectedPaymentMethod == .liquidity, let acc = account {
                acc.availableBalance -= amount
                acc.updatedAt = Date()
            } else if transactionType == .income, let acc = account {
                acc.availableBalance += amount
                acc.updatedAt = Date()
            }
        } else {
            let tx = Transaction(
                concept: concept,
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
        }

        try? modelContext.save()
        dismiss()
    }
}
