import SwiftUI
import SwiftData

// MARK: - CardPaymentSheet
/// Flujo directo de Pago a Tarjeta de Crédito desde una Cuenta de Débito/Efectivo
/// Ejecución atómica:
/// 1. LiquidityAccount.availableBalance -= monto
/// 2. CardMonthlyBalance.balanceUsed -= monto (si existe)
/// 3. UpcomingPayment.status -> .paid o .partial
/// 4. Transaction de tipo .cardPayment creada para auditoría
struct CardPaymentSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var liquidityAccounts: [LiquidityAccount]
    @Query private var creditCards: [CreditCard]
    @Query private var upcomingPayments: [UpcomingPayment]

    @State private var selectedSourceAccountId: UUID?
    @State private var selectedDestinationCardId: UUID?
    @State private var amountString: String = ""
    @State private var paymentDate: Date = Date()
    @State private var notes: String = ""

    private var selectedSourceAccount: LiquidityAccount? {
        liquidityAccounts.first(where: { $0.id == selectedSourceAccountId })
    }

    private var selectedDestinationCard: CreditCard? {
        creditCards.first(where: { $0.id == selectedDestinationCardId })
    }

    var body: some View {
        NavigationStack {
            Form {
                // SECCIÓN ORIGEN (CUENTA DE DÉBITO)
                Section {
                    Picker("Cuenta Origen", selection: $selectedSourceAccountId) {
                        Text("Selecciona cuenta con fondos").tag(Optional<UUID>.none)
                        ForEach(liquidityAccounts.filter { $0.isActive && $0.accountType != .loan }) { acc in
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
                            Text("Saldo disponible en cuenta:")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            PrivacyAwareText(amount: acc.availableBalance, font: .kashCaptionBold)
                        }
                    }
                } header: {
                    Label("Origen (Tu Dinero Real)", systemImage: "banknote.fill")
                }

                // SECCIÓN DESTINO (TARJETA A PAGAR)
                Section {
                    Picker("Tarjeta Destino", selection: $selectedDestinationCardId) {
                        Text("Selecciona tarjeta a liquidar").tag(Optional<UUID>.none)
                        ForEach(creditCards.filter { $0.isActive }) { card in
                            HStack {
                                Text(card.name)
                                Spacer()
                                Text("Deuda: $\(card.currentBalance)")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(Optional(card.id))
                        }
                    }

                    if let card = selectedDestinationCard {
                        HStack {
                            Text("Saldo deudor actual:")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            PrivacyAwareText(
                                amount: card.currentBalance,
                                font: .kashCaptionBold,
                                foregroundColor: Color(hex: "#EF4444")
                            )
                        }
                    }
                } header: {
                    Label("Destino (Tarjeta de Crédito)", systemImage: "creditcard.fill")
                }

                // SECCIÓN MONTO A PAGAR
                Section {
                    HStack {
                        Text("$")
                            .font(.kashAmountLarge)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountString)
                            .font(.kashAmountLarge)
                            .keyboardType(.decimalPad)
                    }

                    if let card = selectedDestinationCard, card.currentBalance > 0 {
                        Button {
                            amountString = "\(card.currentBalance)"
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Pagar Deuda Total del Mes ($\(card.currentBalance))")
                            }
                            .font(.kashCaptionBold)
                            .foregroundStyle(Color(hex: "#2563EB"))
                        }
                    }

                    DatePicker("Fecha del Pago", selection: $paymentDate, displayedComponents: [.date])

                    TextField("Notas del abono (opcional)", text: $notes)
                } header: {
                    Label("Monto del Abono", systemImage: "dollarsign.circle.fill")
                }
            }
            .navigationTitle("Pagar Tarjeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar Pago") {
                        executeAtomicPayment()
                    }
                    .disabled(
                        selectedSourceAccountId == nil ||
                        selectedDestinationCardId == nil ||
                        amountString.isEmpty
                    )
                }
            }
            .onAppear {
                setupInitialSelections()
            }
        }
    }

    private func setupInitialSelections() {
        if selectedSourceAccountId == nil {
            selectedSourceAccountId = liquidityAccounts.first(where: { $0.availableBalance > 0 })?.id
        }
        if selectedDestinationCardId == nil {
            selectedDestinationCardId = creditCards.first(where: { $0.currentBalance > 0 })?.id
        }
        if let card = selectedDestinationCard, card.currentBalance > 0 {
            amountString = "\(card.currentBalance)"
        }
    }

    private func executeAtomicPayment() {
        guard let sourceAcc = selectedSourceAccount,
              let destCard = selectedDestinationCard else { return }

        let amount = Decimal(string: amountString.replacingOccurrences(of: ",", with: "")) ?? 0
        guard amount > 0 else { return }

        // 1. Descontar liquidez real de la cuenta de débito
        sourceAcc.availableBalance -= amount
        sourceAcc.updatedAt = Date()

        // 2. Descontar saldo deudor en el balance más reciente de la tarjeta
        if let balances = destCard.balances, !balances.isEmpty {
            let sorted = balances.sorted { $0.recordedAt > $1.recordedAt }
            if let latest = sorted.first {
                latest.balanceUsed = max(0, latest.balanceUsed - amount)
            }
        }

        // 3. Actualizar estado en UpcomingPayment si hay compromiso pendiente
        if let upcoming = destCard.upcomingPayments?.first(where: { $0.status == .pending }) {
            if amount >= upcoming.fullPaymentNoInterest {
                upcoming.status = .paid
                upcoming.paymentDate = paymentDate
            } else {
                upcoming.status = .partial
                upcoming.actualAmountToPay = max(0, upcoming.actualAmountToPay - amount)
            }
        }

        // 4. Registrar Transacción de tipo .cardPayment para auditoría
        let tx = Transaction(
            concept: "Abono a \(destCard.name)",
            amount: amount,
            transactionDate: paymentDate,
            type: .cardPayment,
            notes: notes.isEmpty ? "Pago desde \(sourceAcc.name)" : notes,
            liquidityAccount: sourceAcc,
            destinationCard: destCard
        )
        modelContext.insert(tx)

        try? modelContext.save()
        dismiss()
    }
}
