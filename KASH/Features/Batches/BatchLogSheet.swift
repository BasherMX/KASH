import SwiftUI
import SwiftData

// MARK: - BatchLogSheet
/// Formulario vertical ultra-rápido para registrar en ~15 segundos todos los saldos deudores
/// de las tarjetas de crédito al día del corte mensual.
struct BatchLogSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CreditCard.displayOrder) private var creditCards: [CreditCard]
    @Query(sort: \MonthlyRecord.periodDate, order: .reverse) private var existingRecords: [MonthlyRecord]

    @State private var selectedPeriodDate: Date = {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comps) ?? Date()
    }()

    @State private var balancesDict: [UUID: String] = [:]
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Periodo del Mes",
                        selection: $selectedPeriodDate,
                        displayedComponents: [.date]
                    )

                    TextField("Notas del corte (opcional)", text: $notes)
                } header: {
                    Label("Periodo de Corte", systemImage: "calendar")
                } footer: {
                    Text("Introduce el saldo deudor registrado en tu estado de cuenta para cada tarjeta.")
                }

                Section {
                    if creditCards.isEmpty {
                        Text("No tienes tarjetas registradas. Añade tarjetas en Ajustes.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(creditCards.filter { $0.isActive }) { card in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: card.colorHex))
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.name)
                                        .font(.kashBodyBold)
                                    Text("Límite: $\(card.creditLimit)")
                                        .font(.kashMicro)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                TextField("$ 0.00", text: binding(for: card.id))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 120)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Label("Saldos Deudores por Tarjeta", systemImage: "creditcard.fill")
                }
            }
            .navigationTitle("Corte Mensual Rápido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar Corte") {
                        saveBatch()
                    }
                    .disabled(creditCards.isEmpty)
                }
            }
            .onAppear {
                prefillBalances()
            }
        }
    }

    private func binding(for cardId: UUID) -> Binding<String> {
        Binding(
            get: { balancesDict[cardId] ?? "" },
            set: { balancesDict[cardId] = $0 }
        )
    }

    private func prefillBalances() {
        for card in creditCards {
            if card.currentBalance > 0 {
                balancesDict[card.id] = "\(card.currentBalance)"
            }
        }
    }

    private func saveBatch() {
        // Buscar si ya existe un corte para el mismo año y mes
        let calendar = Calendar.current
        let targetComps = calendar.dateComponents([.year, .month], from: selectedPeriodDate)

        let existingRecord = existingRecords.first { rec in
            let c = calendar.dateComponents([.year, .month], from: rec.periodDate)
            return c.year == targetComps.year && c.month == targetComps.month
        }

        let record = existingRecord ?? MonthlyRecord(periodDate: selectedPeriodDate, notes: notes)
        if existingRecord == nil {
            modelContext.insert(record)
        } else {
            record.notes = notes
        }

        for card in creditCards where card.isActive {
            let amountString = balancesDict[card.id] ?? "0"
            let amount = Decimal(string: amountString.replacingOccurrences(of: ",", with: "")) ?? 0

            // Actualizar o crear CardMonthlyBalance
            if let existingBalance = record.balances?.first(where: { $0.card?.id == card.id }) {
                existingBalance.balanceUsed = amount
                existingBalance.recordedAt = Date()
            } else {
                let newBalance = CardMonthlyBalance(
                    balanceUsed: amount,
                    recordedAt: Date(),
                    card: card,
                    monthlyRecord: record
                )
                modelContext.insert(newBalance)
            }

            // Generar o actualizar compromiso en UpcomingPayment si hay saldo
            if amount > 0 {
                updateOrCreateUpcomingPayment(for: card, amountToPay: amount)
            }
        }

        try? modelContext.save()
        dismiss()
    }

    private func updateOrCreateUpcomingPayment(for card: CreditCard, amountToPay: Decimal) {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: selectedPeriodDate)
        comps.day = min(card.paymentDueDay, 28) // Evitar overflow de febrero
        let dueDate = calendar.date(from: comps) ?? Date()

        if let existing = card.upcomingPayments?.first(where: { p in
            calendar.isDate(p.dueDate, equalTo: dueDate, toGranularity: .month)
        }) {
            existing.fullPaymentNoInterest = amountToPay
            existing.actualAmountToPay = amountToPay
        } else {
            let newPayment = UpcomingPayment(
                concept: "Pago para no generar intereses - \(card.name)",
                dueDate: dueDate,
                minimumPayment: amountToPay * 0.10, // Estimado 10%
                fullPaymentNoInterest: amountToPay,
                actualAmountToPay: amountToPay,
                status: .pending,
                card: card
            )
            modelContext.insert(newPayment)
        }
    }
}
