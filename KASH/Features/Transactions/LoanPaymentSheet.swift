import SwiftUI
import SwiftData

// MARK: - LoanPaymentSheet
/// Flujo para abonar cuotas a un Préstamo Personal desde una cuenta de liquidez (Débito/Efectivo)
struct LoanPaymentSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var liquidityAccounts: [LiquidityAccount]

    var targetLoan: LiquidityAccount?

    @State private var selectedLoanId: UUID?
    @State private var selectedSourceAccountId: UUID?
    @State private var installmentsCount: Int = 1
    @State private var amountString: String = ""
    @State private var paymentDate: Date = Date()
    @State private var notes: String = ""

    private var loans: [LiquidityAccount] {
        liquidityAccounts.filter { $0.isActive && $0.accountType == .loan }
    }

    private var fundingAccounts: [LiquidityAccount] {
        liquidityAccounts.filter { $0.isActive && $0.accountType != .loan && $0.availableBalance > 0 }
    }

    private var selectedLoan: LiquidityAccount? {
        liquidityAccounts.first(where: { $0.id == selectedLoanId })
    }

    private var selectedSourceAccount: LiquidityAccount? {
        liquidityAccounts.first(where: { $0.id == selectedSourceAccountId })
    }

    private var parsedAmount: Decimal {
        CurrencyInputParser.parseDecimal(amountString)
    }

    private var isAmountExceedingBalance: Bool {
        guard let source = selectedSourceAccount else { return false }
        return parsedAmount > source.availableBalance
    }

    private var isSourceZeroBalance: Bool {
        guard let source = selectedSourceAccount else { return false }
        return source.availableBalance <= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // SECCIÓN: PRÉSTAMO A AMORTIZAR
                Section {
                    Picker("Préstamo Destino", selection: $selectedLoanId) {
                        Text("Selecciona un préstamo").tag(Optional<UUID>.none)
                        ForEach(loans) { loan in
                            HStack {
                                Text(loan.name)
                                Spacer()
                                Text("Saldo deudor: $\(loan.availableBalance)")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(Optional(loan.id))
                        }
                    }
                    .onChange(of: selectedLoanId) { _, _ in
                        updateSuggestedAmount()
                    }

                    if let loan = selectedLoan {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Avance de Cuotas:")
                                    .font(.kashCaption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(loan.paidInstallments) de \(loan.totalInstallments) cubiertas")
                                    .font(.kashCaptionBold)
                            }

                            if loan.totalInstallments > 0 {
                                ProgressView(value: Double(loan.paidInstallments), total: Double(loan.totalInstallments))
                                    .tint(Color(hex: "#10B981"))
                            }

                            HStack {
                                Text("Deuda restante:")
                                    .font(.kashCaption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                PrivacyAwareText(
                                    amount: loan.availableBalance,
                                    font: .kashCaptionBold,
                                    foregroundColor: Color(hex: "#EF4444")
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("Préstamo a Liquidar", systemImage: "doc.text.below.ecg.fill")
                }

                // SECCIÓN: CUENTA DE ORIGEN DE FONDOS
                Section {
                    Picker("Cuenta Origen", selection: $selectedSourceAccountId) {
                        Text("Selecciona cuenta con dinero").tag(Optional<UUID>.none)
                        ForEach(fundingAccounts) { acc in
                            HStack {
                                Text(acc.name)
                                Spacer()
                                Text("($\(acc.availableBalance))")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(Optional(acc.id))
                        }
                    }

                    if let acc = selectedSourceAccount {
                        HStack {
                            Text("Dinero disponible:")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            PrivacyAwareText(amount: acc.availableBalance, font: .kashCaptionBold)
                        }
                    }
                } header: {
                    Label("Origen (Tu Dinero Real)", systemImage: "banknote.fill")
                }

                // SECCIÓN: CUOTAS E IMPORTE A ABONAR
                Section {
                    Stepper("Cuotas a pagar: \(installmentsCount)", value: $installmentsCount, in: 1...120)
                        .onChange(of: installmentsCount) { _, _ in
                            updateSuggestedAmount()
                        }

                    HStack {
                        Text("$")
                            .font(.kashAmountLarge)
                            .foregroundStyle(Color(hex: "#2563EB"))
                        TextField("0.00", text: $amountString)
                            .font(.kashAmountLarge)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Fecha de Abono", selection: $paymentDate, displayedComponents: [.date])

                    TextField("Notas adicionales (opcional)", text: $notes)

                    if isSourceZeroBalance {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("La cuenta de origen no tiene fondos ($0.00).")
                        }
                        .font(.kashCaption)
                        .foregroundStyle(Color(hex: "#EF4444"))
                    } else if isAmountExceedingBalance {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("El monto del abono excede el saldo de la cuenta de origen.")
                        }
                        .font(.kashCaption)
                        .foregroundStyle(Color(hex: "#EF4444"))
                    }
                } header: {
                    Label("Monto a Abonar", systemImage: "dollarsign.circle.fill")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Abonar a Préstamo")
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
                    Button("Abonar") {
                        executeLoanPayment()
                    }
                    .disabled(
                        selectedLoanId == nil ||
                        selectedSourceAccountId == nil ||
                        amountString.isEmpty ||
                        parsedAmount <= 0 ||
                        isSourceZeroBalance ||
                        isAmountExceedingBalance
                    )
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }

    private func setupInitialValues() {
        if let target = targetLoan {
            selectedLoanId = target.id
        } else {
            selectedLoanId = loans.first?.id
        }
        selectedSourceAccountId = fundingAccounts.first(where: { $0.availableBalance > 0 })?.id
        updateSuggestedAmount()
    }

    private func updateSuggestedAmount() {
        guard let loan = selectedLoan else { return }
        if loan.installmentAmount > 0 {
            let total = loan.installmentAmount * Decimal(installmentsCount)
            amountString = "\(total)"
        } else if loan.availableBalance > 0 && amountString.isEmpty {
            amountString = "\(loan.availableBalance)"
        }
    }

    private func executeLoanPayment() {
        guard let loan = selectedLoan,
              let source = selectedSourceAccount else { return }

        let amount = CurrencyInputParser.parseDecimal(amountString)
        guard amount > 0 else { return }

        // 1. Descontar fondos de la cuenta origen
        source.availableBalance -= amount
        source.updatedAt = Date()

        // 2. Reducir saldo deudor del préstamo y avanzar cuotas
        loan.availableBalance = max(0 as Decimal, loan.availableBalance - amount)
        loan.paidInstallments = min(loan.totalInstallments > 0 ? loan.totalInstallments : Int.max, loan.paidInstallments + installmentsCount)
        loan.updatedAt = Date()

        // 3. Registrar Transacción para auditoría
        let tx = Transaction(
            concept: "Abono a \(loan.name) (\(installmentsCount) cuota\(installmentsCount > 1 ? "s" : ""))",
            amount: amount,
            transactionDate: paymentDate,
            type: .expense,
            notes: notes.isEmpty ? "Pago desde \(source.name)" : notes,
            liquidityAccount: source
        )
        modelContext.insert(tx)

        try? modelContext.save()
        KASHWidgetSyncService.sync(modelContext: modelContext)
        dismiss()
    }
}
