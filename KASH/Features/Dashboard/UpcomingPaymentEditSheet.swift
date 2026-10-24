import SwiftUI
import SwiftData

// MARK: - UpcomingPaymentEditSheet
/// Hoja para registrar o editar el compromiso mensual de pago para una Tarjeta de Crédito
struct UpcomingPaymentEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var creditCards: [CreditCard]
    @Query private var existingPayments: [UpcomingPayment]

    var paymentToEdit: UpcomingPayment?

    @State private var selectedCardId: UUID?
    @State private var targetDate: Date = Date()
    @State private var dueDate: Date = Date()
    @State private var minPaymentString: String = ""
    @State private var fullPaymentString: String = ""
    @State private var reminderDays: Int = 3
    @State private var isPaid: Bool = false
    @State private var notes: String = ""

    @State private var isShowingDeleteConfirmation: Bool = false

    private var selectedCard: CreditCard? {
        creditCards.first(where: { $0.id == selectedCardId })
    }

    var body: some View {
        NavigationStack {
            Form {
                // SECCIÓN: TARJETA DE CRÉDITO
                Section {
                    Picker("Tarjeta", selection: $selectedCardId) {
                        Text("Selecciona una tarjeta").tag(Optional<UUID>.none)
                        ForEach(creditCards.filter { $0.isActive }) { card in
                            HStack {
                                Text(card.name)
                                Spacer()
                                Text("Límite día \(card.paymentDueDay)")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(Optional(card.id))
                        }
                    }
                    .onChange(of: selectedCardId) { _, _ in
                        prefillFromSelectedCard()
                    }
                } header: {
                    Label("Tarjeta a Pagar", systemImage: "creditcard.fill")
                }

                // SECCIÓN: PERIODO Y FECHA LÍMITE EXACTA
                Section {
                    DatePicker(
                        "Periodo del Mes",
                        selection: $targetDate,
                        displayedComponents: [.date]
                    )
                    .onChange(of: targetDate) { _, _ in
                        adjustDueDateForTargetMonth()
                    }

                    DatePicker(
                        "Fecha Límite Real de Pago",
                        selection: $dueDate,
                        displayedComponents: [.date]
                    )
                } header: {
                    Label("Vencimiento del Mes", systemImage: "calendar")
                } footer: {
                    Text("Puedes ajustar la fecha límite exacta de este mes para considerar fines de semana o días feriados bancarios.")
                }

                // SECCIÓN: IMPORTES A PAGAR
                Section {
                    HStack {
                        Text("Pago para no generar intereses")
                            .font(.kashCaptionBold)
                        Spacer()
                        HStack(spacing: 2) {
                            Text("$")
                                .foregroundStyle(Color(hex: "#EF4444"))
                            TextField("0.00", text: $fullPaymentString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 100)
                        }
                    }

                    HStack {
                        Text("Pago mínimo")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 2) {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $minPaymentString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 100)
                        }
                    }
                } header: {
                    Label("Montos de Pago", systemImage: "banknote")
                }

                // SECCIÓN: NOTIFICACIÓN DE RECORDATORIO
                Section {
                    Picker("Avisarme antes con", selection: $reminderDays) {
                        Text("1 día de anticipación").tag(1)
                        Text("2 días de anticipación").tag(2)
                        Text("3 días de anticipación").tag(3)
                        Text("5 días de anticipación").tag(5)
                        Text("Sin recordatorio").tag(0)
                    }
                } header: {
                    Label("Recordatorio", systemImage: "bell.badge")
                }

                // SECCIÓN: ESTADO
                if paymentToEdit != nil {
                    Section {
                        Toggle("Marcar como ya pagado", isOn: $isPaid)
                    }

                    Section {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Eliminar Próximo Pago", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(paymentToEdit == nil ? "Registrar Próximo Pago" : "Editar Próximo Pago")
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
                        savePayment()
                    }
                    .disabled(selectedCardId == nil || fullPaymentString.isEmpty)
                }
            }
            .alert("¿Eliminar Próximo Pago?", isPresented: $isShowingDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    if let payment = paymentToEdit {
                        modelContext.delete(payment)
                        try? modelContext.save()
                        KASHWidgetSyncService.sync(modelContext: modelContext)
                        dismiss()
                    }
                }
            } message: {
                Text("Esta acción eliminará el recordatorio y compromiso de pago registrado.")
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }

    private func setupInitialValues() {
        if let p = paymentToEdit {
            selectedCardId = p.card?.id
            dueDate = p.dueDate
            targetDate = p.dueDate
            fullPaymentString = "\(p.fullPaymentNoInterest)"
            minPaymentString = "\(p.minimumPayment)"
            reminderDays = p.reminderDaysBefore
            isPaid = p.status == .paid
        } else {
            selectedCardId = creditCards.first(where: { $0.isActive })?.id
            prefillFromSelectedCard()
        }
    }

    private func prefillFromSelectedCard() {
        guard let card = selectedCard else { return }
        adjustDueDateForTargetMonth()
        if fullPaymentString.isEmpty && card.currentBalance > 0 {
            fullPaymentString = "\(card.currentBalance)"
        }
    }

    private func adjustDueDateForTargetMonth() {
        guard let card = selectedCard else { return }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: targetDate)
        comps.day = min(card.paymentDueDay, 28)
        comps.hour = 12
        comps.minute = 0
        if let calculatedDate = cal.date(from: comps) {
            dueDate = calculatedDate
        }
    }

    private func savePayment() {
        guard let card = selectedCard else { return }
        let full = CurrencyInputParser.parseDecimal(fullPaymentString)
        let min = CurrencyInputParser.parseDecimal(minPaymentString)
        let cal = Calendar.current
        let targetMonth = cal.component(.month, from: dueDate)
        let targetYear = cal.component(.year, from: dueDate)

        if let p = paymentToEdit {
            p.card = card
            p.concept = "Pago \(card.name)"
            p.dueDate = dueDate
            p.fullPaymentNoInterest = full
            p.minimumPayment = min
            p.actualAmountToPay = full
            p.reminderDaysBefore = reminderDays
            p.targetMonth = targetMonth
            p.targetYear = targetYear
            p.status = isPaid ? .paid : .pending
            if isPaid && p.paymentDate == nil {
                p.paymentDate = Date()
            }
        } else {
            let newPayment = UpcomingPayment(
                concept: "Pago \(card.name)",
                dueDate: dueDate,
                minimumPayment: min,
                fullPaymentNoInterest: full,
                actualAmountToPay: full,
                status: isPaid ? .paid : .pending,
                reminderDaysBefore: reminderDays,
                targetMonth: targetMonth,
                targetYear: targetYear,
                card: card
            )
            modelContext.insert(newPayment)
        }

        // Programar recordatorio local si corresponde
        if reminderDays > 0 && !isPaid {
            NotificationManager.shared.schedulePaymentDueReminder(
                cardName: card.name,
                dueDate: dueDate,
                daysBefore: reminderDays,
                amount: full
            )
        }

        try? modelContext.save()
        KASHWidgetSyncService.sync(modelContext: modelContext)
        dismiss()
    }
}
