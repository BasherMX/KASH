import SwiftUI
import SwiftData
import WidgetKit

// MARK: - TransactionsListView
struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.transactionDate, order: .reverse) private var transactions: [Transaction]

    @State private var periodFilter = PeriodFilterSelection()
    @State private var expandedYears: Set<Int> = [Calendar.current.component(.year, from: Date())]
    @State private var selectedFilter: TransactionType? = nil
    @State private var isQuickTxSheetPresented = false
    @State private var isCardPaymentSheetPresented = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var transactionToDelete: Transaction? = nil
    @State private var isShowingDeleteTransactionAlert = false

    private var transactionsGroupedByYear: [(year: Int, items: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            Calendar.current.component(.year, from: tx.transactionDate)
        }
        return grouped.keys.sorted(by: >).map { year in
            let items = (grouped[year] ?? []).sorted { $0.transactionDate > $1.transactionDate }
            return (year: year, items: items)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Selector de Mes / Histórico arriba en la pestaña (por defecto Mes Actual)
                PeriodFilterHeaderView(selection: $periodFilter)

                Divider()

                // 2. Filtro rápido de tipo de movimiento
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
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            periodFilter.mode == .month
                                ? "Sin Movimientos en \(periodFilter.periodTitle)"
                                : "Sin Movimientos Registrados",
                            systemImage: "list.bullet.rectangle.portrait",
                            description: Text(
                                periodFilter.mode == .month
                                    ? "No hay movimientos registrados para este mes. Puedes cambiar de mes arriba o ver el histórico completo."
                                    : "Registra compras con tarjeta, ingresos o abonos para mantener tu historial al día."
                            )
                        )

                        if periodFilter.mode == .month && !transactions.isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    periodFilter.mode = .historical
                                }
                            } label: {
                                Label("Ver Histórico Completo (\(transactions.count) movimientos)", systemImage: "clock.arrow.circlepath")
                                    .font(.kashCaptionBold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "#2563EB").opacity(0.12), in: Capsule())
                                    .foregroundStyle(Color(hex: "#2563EB"))
                            }
                            .padding(.bottom, 24)
                        }
                    }
                } else if periodFilter.mode == .historical {
                    List {
                        ForEach(transactionsGroupedByYear, id: \.year) { group in
                            let isYearExpanded = expandedYears.contains(group.year)
                            Section {
                                if isYearExpanded {
                                    ForEach(group.items) { tx in
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
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    transactionToDelete = tx
                                                    isShowingDeleteTransactionAlert = true
                                                } label: {
                                                    Label("Eliminar", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            } header: {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                        if isYearExpanded {
                                            expandedYears.remove(group.year)
                                        } else {
                                            expandedYears.insert(group.year)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: isYearExpanded ? "folder.fill" : "folder")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#2563EB"))

                                        Text("Año \(String(group.year))")
                                            .font(.kashBodyBold)
                                            .foregroundStyle(.primary)

                                        if group.year == Calendar.current.component(.year, from: Date()) {
                                            Text("Actual")
                                                .font(.kashMicro)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(hex: "#2563EB").opacity(0.15), in: Capsule())
                                                .foregroundStyle(Color(hex: "#2563EB"))
                                        }

                                        Spacer()

                                        Text("\(group.items.count) \(group.items.count == 1 ? "movimiento" : "movimientos")")
                                            .font(.kashMicro)
                                            .foregroundStyle(.secondary)

                                        Image(systemName: isYearExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.plain)
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        transactionToDelete = tx
                                        isShowingDeleteTransactionAlert = true
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                        }
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
            .alert("¿Eliminar Movimiento?", isPresented: $isShowingDeleteTransactionAlert) {
                Button("Cancelar", role: .cancel) {
                    transactionToDelete = nil
                }
                Button("Eliminar", role: .destructive) {
                    if let tx = transactionToDelete {
                        deleteTransaction(tx)
                    }
                }
            } message: {
                if let tx = transactionToDelete {
                    Text("Se eliminará '\(tx.concept)' por \(tx.amount.formatted(.currency(code: "MXN"))). Los saldos serán recalculados automáticamente.")
                } else {
                    Text("Esta acción eliminará el movimiento permanentemente.")
                }
            }
        }
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { tx in
            let matchesPeriod = periodFilter.matches(date: tx.transactionDate)
            let matchesType = selectedFilter == nil || tx.type == selectedFilter
            return matchesPeriod && matchesType
        }
    }

    private func revertTransactionBalances(_ tx: Transaction) {
        switch tx.type {
        case .expense:
            if let acc = tx.liquidityAccount {
                acc.availableBalance += tx.amount
                acc.updatedAt = Date()
            }
            if let card = tx.creditCard, let latest = card.sortedBalances.first {
                latest.balanceUsed = max(0 as Decimal, latest.balanceUsed - tx.amount)
            }
        case .income:
            if let acc = tx.liquidityAccount {
                acc.availableBalance -= tx.amount
                acc.updatedAt = Date()
            }
        case .cardPayment:
            if let acc = tx.liquidityAccount {
                acc.availableBalance += tx.amount
                acc.updatedAt = Date()
            }
            if let latestBalance = tx.destinationCard?.sortedBalances.first {
                latestBalance.balanceUsed += tx.amount
            }
        case .transfer:
            if let source = tx.liquidityAccount {
                source.availableBalance += tx.amount
                source.updatedAt = Date()
            }
            if let dest = tx.destinationLiquidityAccount {
                dest.availableBalance -= tx.amount
                dest.updatedAt = Date()
            }
        }
    }

    private func deleteTransaction(_ tx: Transaction) {
        revertTransactionBalances(tx)
        modelContext.delete(tx)
        try? modelContext.save()
        KASHWidgetSyncService.sync(modelContext: modelContext)
        transactionToDelete = nil
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
