import SwiftUI
import SwiftData

// MARK: - TransferSheet
/// Flujo para transferir dinero entre cuentas de liquidez (ej. Débito a Efectivo, o Débito a Rendimientos/Ahorro)
struct TransferSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var liquidityAccounts: [LiquidityAccount]

    var preselectedSourceAccount: LiquidityAccount?

    @State private var sourceAccountId: UUID?
    @State private var destinationAccountId: UUID?
    @State private var amountString: String = ""
    @State private var transferDate: Date = Date()
    @State private var notes: String = ""

    private var availableSourceAccounts: [LiquidityAccount] {
        liquidityAccounts.filter { $0.isActive && $0.accountType != .loan }
    }

    private var availableDestinationAccounts: [LiquidityAccount] {
        liquidityAccounts.filter { $0.isActive && $0.id != sourceAccountId }
    }

    private var selectedSourceAccount: LiquidityAccount? {
        liquidityAccounts.first(where: { $0.id == sourceAccountId })
    }

    private var selectedDestinationAccount: LiquidityAccount? {
        liquidityAccounts.first(where: { $0.id == destinationAccountId })
    }

    var body: some View {
        NavigationStack {
            Form {
                // SECCIÓN CUENTA ORIGEN
                Section {
                    Picker("Cuenta Origen", selection: $sourceAccountId) {
                        Text("Selecciona origen").tag(Optional<UUID>.none)
                        ForEach(availableSourceAccounts) { acc in
                            HStack {
                                Text(acc.name)
                                Spacer()
                                Text("($\(acc.availableBalance))")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(Optional(acc.id))
                        }
                    }

                    if let source = selectedSourceAccount {
                        HStack {
                            Text("Saldo disponible:")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            PrivacyAwareText(amount: source.availableBalance, font: .kashCaptionBold)
                        }
                    }
                } header: {
                    Label("Cuenta Origen", systemImage: "arrow.up.right.circle.fill")
                }

                // SECCIÓN CUENTA DESTINO
                Section {
                    Picker("Cuenta Destino", selection: $destinationAccountId) {
                        Text("Selecciona destino").tag(Optional<UUID>.none)
                        ForEach(availableDestinationAccounts) { acc in
                            HStack {
                                Text(acc.name)
                                Spacer()
                                Text("($\(acc.availableBalance))")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(Optional(acc.id))
                        }
                    }

                    if let dest = selectedDestinationAccount {
                        HStack {
                            Text("Saldo actual:")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            PrivacyAwareText(amount: dest.availableBalance, font: .kashCaptionBold)
                        }
                    }
                } header: {
                    Label("Cuenta Destino", systemImage: "arrow.down.left.circle.fill")
                }

                // SECCIÓN MONTO Y FECHA
                Section {
                    HStack {
                        Text("$")
                            .font(.kashAmountLarge)
                            .foregroundStyle(Color(hex: "#2563EB"))
                        TextField("0.00", text: $amountString)
                            .font(.kashAmountLarge)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Fecha", selection: $transferDate, displayedComponents: [.date])

                    TextField("Concepto o notas (opcional)", text: $notes)
                } header: {
                    Label("Monto a Traspasar", systemImage: "dollarsign.circle.fill")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Traspaso de Dinero")
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
                    Button("Transferir") {
                        executeTransfer()
                    }
                    .disabled(sourceAccountId == nil || destinationAccountId == nil || amountString.isEmpty)
                }
            }
            .onAppear {
                setupInitialSelections()
            }
        }
    }

    private func setupInitialSelections() {
        if let pre = preselectedSourceAccount {
            sourceAccountId = pre.id
        } else {
            sourceAccountId = availableSourceAccounts.first(where: { $0.availableBalance > 0 })?.id
        }
        destinationAccountId = availableDestinationAccounts.first?.id
    }

    private func executeTransfer() {
        guard let source = selectedSourceAccount,
              let dest = selectedDestinationAccount else { return }

        let amount = CurrencyInputParser.parseDecimal(amountString)
        guard amount > 0 else { return }

        // 1. Debitar de origen y acreditar en destino
        source.availableBalance -= amount
        source.updatedAt = Date()

        dest.availableBalance += amount
        dest.updatedAt = Date()

        // 2. Registrar movimiento de auditoría
        let conceptText = notes.isEmpty ? "Traspaso de \(source.name) a \(dest.name)" : notes
        let tx = Transaction(
            concept: conceptText,
            amount: amount,
            transactionDate: transferDate,
            type: .transfer,
            notes: "Transferencia entre cuentas propias",
            liquidityAccount: source,
            destinationLiquidityAccount: dest
        )
        modelContext.insert(tx)

        try? modelContext.save()
        KASHWidgetSyncService.sync(modelContext: modelContext)
        dismiss()
    }
}
