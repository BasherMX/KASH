import SwiftUI
import SwiftData

// MARK: - BatchLogSheet
/// Formulario vertical ultra-rápido para registrar o editar en ~15 segundos todos los saldos deudores
/// de las tarjetas de crédito al día del corte mensual.
/// Solo se permite un corte por mes (si se ingresa el mismo mes, se edita el existente).
struct BatchLogSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingRecord: MonthlyRecord? = nil

    @Query(sort: \CreditCard.displayOrder) private var creditCards: [CreditCard]
    @Query(sort: \MonthlyRecord.periodDate, order: .reverse) private var existingRecords: [MonthlyRecord]

    @State private var selectedPeriodDate: Date = {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comps) ?? Date()
    }()

    @State private var balancesDict: [UUID: String] = [:]
    @State private var notes: String = ""

    private var isEditing: Bool {
        editingRecord != nil
    }

    private var duplicateMonthRecord: MonthlyRecord? {
        let calendar = Calendar.current
        let targetComps = calendar.dateComponents([.year, .month], from: selectedPeriodDate)
        return existingRecords.first { rec in
            if let editRec = editingRecord, rec.id == editRec.id {
                return false
            }
            let c = calendar.dateComponents([.year, .month], from: rec.periodDate)
            return c.year == targetComps.year && c.month == targetComps.month
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if let dup = duplicateMonthRecord {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color(hex: "#F59E0B"))
                            Text("Ya existe un corte para \(dup.periodDate.formatted(.dateTime.month(.wide).year())). Al guardar, se actualizarán los datos de ese corte existente.")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

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
                    Text("Solo se permite un corte por mes. Las tarjetas siempre toman el corte cronológico más reciente como el actual.")
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
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Editar Corte Mensual" : "Registrar Corte")
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
        if let rec = editingRecord {
            selectedPeriodDate = rec.periodDate
            notes = rec.notes ?? ""
            for balance in rec.balances ?? [] {
                if let cardId = balance.card?.id {
                    balancesDict[cardId] = "\(balance.balanceUsed)"
                }
            }
        } else {
            for card in creditCards {
                if card.currentBalance > 0 {
                    balancesDict[card.id] = "\(card.currentBalance)"
                }
            }
        }
    }

    private func saveBatch() {
        let calendar = Calendar.current
        let targetComps = calendar.dateComponents([.year, .month], from: selectedPeriodDate)

        // 1. Determinar el registro a guardar
        let recordToSave: MonthlyRecord
        if let editRec = editingRecord {
            recordToSave = editRec
            recordToSave.periodDate = selectedPeriodDate
            recordToSave.notes = notes.isEmpty ? nil : notes
        } else if let existingRecord = duplicateMonthRecord {
            recordToSave = existingRecord
            recordToSave.periodDate = selectedPeriodDate
            recordToSave.notes = notes.isEmpty ? nil : notes
        } else {
            let newRec = MonthlyRecord(periodDate: selectedPeriodDate, notes: notes.isEmpty ? nil : notes)
            modelContext.insert(newRec)
            recordToSave = newRec
        }

        // 2. Actualizar o insertar balances para cada tarjeta activa
        for card in creditCards where card.isActive {
            let amountString = balancesDict[card.id] ?? "0"
            let amount = Decimal(string: amountString.replacingOccurrences(of: ",", with: "")) ?? 0

            if let existingBalance = recordToSave.balances?.first(where: { $0.card?.id == card.id }) {
                existingBalance.balanceUsed = amount
                existingBalance.recordedAt = selectedPeriodDate
            } else {
                let newBalance = CardMonthlyBalance(
                    balanceUsed: amount,
                    recordedAt: selectedPeriodDate,
                    card: card,
                    monthlyRecord: recordToSave
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
