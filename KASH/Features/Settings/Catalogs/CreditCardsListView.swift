import SwiftUI
import SwiftData

// MARK: - CreditCardsListView
struct CreditCardsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CreditCard.displayOrder) private var creditCards: [CreditCard]
    @State private var isAddCardSheetPresented = false
    @State private var selectedCardForEdit: CreditCard?

    var body: some View {
        NavigationStack {
            List {
                if creditCards.isEmpty {
                    ContentUnavailableView(
                        "Sin Tarjetas Registradas",
                        systemImage: "creditcard",
                        description: Text("Agrega tus tarjetas de crédito para dar seguimiento a tus fechas de corte, límites y saldos.")
                    )
                } else {
                    Section {
                        ForEach(creditCards) { card in
                            NavigationLink {
                                CreditCardDetailView(card: card)
                            } label: {
                                CreditCardRow(card: card)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    selectedCardForEdit = card
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(Color(hex: "#2563EB"))
                            }
                        }
                        .onDelete(perform: deleteCards)
                    } header: {
                        Text("Tus Tarjetas (\(creditCards.count))")
                    }
                }
            }
            .navigationTitle("Tarjetas de Crédito")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddCardSheetPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $isAddCardSheetPresented) {
                CreditCardEditSheet(cardToEdit: nil)
            }
            .sheet(item: $selectedCardForEdit) { card in
                CreditCardEditSheet(cardToEdit: card)
            }
        }
    }

    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            let card = creditCards[index]
            modelContext.delete(card)
        }
        try? modelContext.save()
    }
}

// MARK: - CreditCardRow
struct CreditCardRow: View {
    let card: CreditCard

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: card.colorHex))
                    .frame(width: 44, height: 44)

                Image(systemName: card.iconName.isEmpty ? "creditcard.fill" : card.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.name)
                        .font(.kashBodyBold)
                    if !card.isActive {
                        Text("Archivada")
                            .font(.kashMicro)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2), in: Capsule())
                    }
                }

                Text("\(card.institution) • Corte día \(card.cutoffDay) • Pago día \(card.paymentDueDay)")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Límite")
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
                PrivacyAwareText(amount: card.creditLimit, font: .kashCaptionBold)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - CreditCardEditSheet
struct CreditCardEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let cardToEdit: CreditCard?

    @State private var name: String = ""
    @State private var institution: String = ""
    @State private var creditLimitString: String = ""
    @State private var cutoffDay: Int = 1
    @State private var paymentDueDay: Int = 20
    @State private var annualInterestRatePercent: Double = 50.0
    @State private var selectedColorHex: String = "#1E293B"
    @State private var selectedIcon: String = "creditcard.fill"
    @State private var isActive: Bool = true

    private let availableColors = [
        "#1E293B", "#0F172A", "#334155", // Slate / Grafito
        "#1E3A8A", "#2563EB", "#3B82F6", // Azul Real / Cobalto / Cielo
        "#0D9488", "#059669", "#10B981", // Teal / Esmeralda / Menta
        "#D97706", "#F59E0B", "#EA580C", // Ámbar / Oro / Naranja
        "#DC2626", "#EF4444", "#991B1B", // Rojo Carmesí / Rubí / Vino
        "#7C3AED", "#8B5CF6", "#6366F1", // Púrpura / Violeta / Índigo
        "#DB2777", "#EC4899", "#BE185D", // Rosa Mexicano / Magenta
        "#0891B2", "#0284C7", "#475569"  // Cian / Océano / Titanio
    ]

    private let availableIcons = [
        "creditcard.fill", "sparkles.rectangle.stack.fill", "star.circle.fill", "bolt.shield.fill",
        "bag.circle.fill", "airplane.circle.fill", "cart.circle.fill", "giftcard.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos Básicos") {
                    TextField("Nombre (ej. Plata Card)", text: $name)
                    TextField("Institución emisora (ej. Nu, Banregio)", text: $institution)
                    TextField("Límite de Crédito ($)", text: $creditLimitString)
                        .keyboardType(.decimalPad)
                }

                Section("Fechas Críticas de Estado de Cuenta") {
                    Picker("Día de Corte", selection: $cutoffDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("Día \(day)").tag(day)
                        }
                    }

                    Picker("Día Límite de Pago", selection: $paymentDueDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("Día \(day)").tag(day)
                        }
                    }
                }

                Section("Condiciones Financieras") {
                    HStack {
                        Text("Tasa Anual: \(annualInterestRatePercent, specifier: "%.1f")%")
                        Spacer()
                    }
                    Slider(value: $annualInterestRatePercent, in: 0...150, step: 0.5)
                }

                Section("Personalización Visual") {
                    // Selector de color
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

                    // Selector de ícono
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

                    Toggle("Tarjeta Activa", isOn: $isActive)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(cardToEdit == nil ? "Nueva Tarjeta" : "Editar Tarjeta")
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
                        saveCard()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let card = cardToEdit {
                    name = card.name
                    institution = card.institution
                    creditLimitString = "\(card.creditLimit)"
                    cutoffDay = card.cutoffDay
                    paymentDueDay = card.paymentDueDay
                    annualInterestRatePercent = card.annualInterestRate * 100
                    selectedColorHex = card.colorHex
                    selectedIcon = card.iconName
                    isActive = card.isActive
                }
            }
        }
    }

    private func saveCard() {
        let cleanLimit = Decimal(string: creditLimitString.replacingOccurrences(of: ",", with: "")) ?? 0
        let rateFraction = annualInterestRatePercent / 100.0

        if let card = cardToEdit {
            card.name = name
            card.institution = institution
            card.creditLimit = cleanLimit
            card.cutoffDay = cutoffDay
            card.paymentDueDay = paymentDueDay
            card.annualInterestRate = rateFraction
            card.colorHex = selectedColorHex
            card.iconName = selectedIcon
            card.isActive = isActive
        } else {
            let newCard = CreditCard(
                name: name,
                institution: institution,
                creditLimit: cleanLimit,
                cutoffDay: cutoffDay,
                paymentDueDay: paymentDueDay,
                annualInterestRate: rateFraction,
                colorHex: selectedColorHex,
                iconName: selectedIcon,
                isActive: isActive
            )
            modelContext.insert(newCard)
        }

        try? modelContext.save()
        dismiss()
    }
}
