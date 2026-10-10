import SwiftUI
import SwiftData

// MARK: - TransactionsListView
struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.transactionDate, order: .reverse) private var transactions: [Transaction]

    @State private var selectedFilter: TransactionType? = nil
    @State private var isQuickTxSheetPresented = false
    @State private var isCardPaymentSheetPresented = false
    @State private var transactionToEdit: Transaction? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtro rápido de tipo
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "Todos",
                            isSelected: selectedFilter == nil
                        ) {
                            selectedFilter = nil
                        }

                        ForEach(TransactionType.allCases, id: \.self) { type in
                            FilterChip(
                                title: type.title,
                                isSelected: selectedFilter == type
                            ) {
                                selectedFilter = type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(uiColor: .systemBackground))

                Divider()

                if filteredTransactions.isEmpty {
                    ContentUnavailableView(
                        "Sin Movimientos Registrados",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("Registra compras con tarjeta, ingresos o abonos para mantener tu historial al día.")
                    )
                } else {
                    List {
                        ForEach(filteredTransactions) { tx in
                            TransactionRow(tx: tx)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    transactionToEdit = tx
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        transactionToEdit = tx
                                    } label: {
                                        Label("Editar", systemImage: "pencil")
                                    }
                                    .tint(Color(hex: "#2563EB"))
                                }
                        }
                        .onDelete(perform: deleteTransactions)
                    }
                    .listStyle(.plain)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Movimientos")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    PrivacyToggleButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isQuickTxSheetPresented = true
                        } label: {
                            Label("Nuevo Gasto / Ingreso", systemImage: "plus.circle")
                        }

                        Button {
                            isCardPaymentSheetPresented = true
                        } label: {
                            Label("Pagar Tarjeta de Crédito", systemImage: "creditcard.and.123")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "#2563EB"))
                    }
                }
            }
            .sheet(isPresented: $isQuickTxSheetPresented) {
                QuickTransactionSheet()
            }
            .sheet(isPresented: $isCardPaymentSheetPresented) {
                CardPaymentSheet()
            }
            .sheet(item: $transactionToEdit) { tx in
                QuickTransactionSheet(editingTransaction: tx)
            }
        }
    }

    private var filteredTransactions: [Transaction] {
        guard let filter = selectedFilter else { return transactions }
        return transactions.filter { $0.type == filter }
    }

    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let tx = filteredTransactions[index]
            modelContext.delete(tx)
        }
        try? modelContext.save()
    }
}

// MARK: - TransactionRow
struct TransactionRow: View {
    let tx: Transaction

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(iconBackgroundColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tx.concept)
                    .font(.kashBodyBold)

                HStack(spacing: 6) {
                    if let cat = tx.category {
                        Text(cat.name)
                            .font(.kashMicro)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: cat.colorHex).opacity(0.15), in: Capsule())
                            .foregroundStyle(Color(hex: cat.colorHex))
                    }

                    Text(tx.transactionDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.kashCaption)
                        .foregroundStyle(.secondary)
                }

                if let destCard = tx.destinationCard {
                    Text("Destino: \(destCard.name)")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                } else if let card = tx.creditCard {
                    Text("Tarjeta: \(card.name)")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                } else if let acc = tx.liquidityAccount {
                    Text("Cuenta: \(acc.name)")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    Text(prefixSign)
                    PrivacyAwareText(
                        amount: tx.amount,
                        font: .kashCaptionBold,
                        foregroundColor: amountColor
                    )
                }

                Text(tx.type.title)
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var prefixSign: String {
        switch tx.type {
        case .expense: return "-"
        case .income: return "+"
        case .cardPayment: return "↘"
        case .transfer: return "↔"
        }
    }

    private var amountColor: Color {
        switch tx.type {
        case .expense: return Color(hex: "#EF4444")
        case .income: return Color(hex: "#10B981")
        case .cardPayment: return Color(hex: "#2563EB")
        case .transfer: return Color(hex: "#64748B")
        }
    }

    private var iconBackgroundColor: Color {
        if let cat = tx.category {
            return Color(hex: cat.colorHex)
        }
        return amountColor
    }

    private var iconName: String {
        if let cat = tx.category {
            return cat.iconName
        }
        return tx.type.icon
    }
}

// MARK: - FilterChip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kashCaptionBold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "#2563EB") : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}
