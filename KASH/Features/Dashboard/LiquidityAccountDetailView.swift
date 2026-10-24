import SwiftUI
import SwiftData

// MARK: - LiquidityAccountDetailView
/// Vista de detalle exhaustiva para cuentas de dinero real (Débito, Efectivo, Ahorros y Préstamos)
struct LiquidityAccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: LiquidityAccount

    @Query(sort: \Transaction.transactionDate, order: .reverse)
    private var allTransactions: [Transaction]

    @State private var periodFilter = PeriodFilterSelection()
    @State private var isEditAccountSheetPresented = false
    @State private var isQuickTxSheetPresented = false
    @State private var quickTxInitialType: TransactionType = .expense
    @State private var isTransferSheetPresented = false
    @State private var isLoanPaymentSheetPresented = false
    @State private var transactionToEdit: Transaction?
    @State private var transactionToDelete: Transaction?
    @State private var isShowingDeleteTransactionAlert = false

    private var accountTransactions: [Transaction] {
        allTransactions.filter { tx in
            tx.liquidityAccount?.id == account.id || tx.destinationLiquidityAccount?.id == account.id
        }
    }

    private var filteredTransactions: [Transaction] {
        accountTransactions.filter { tx in
            periodFilter.matches(date: tx.transactionDate)
        }
    }

    private var monthIncomes: Decimal {
        filteredTransactions.filter { $0.type == .income && $0.liquidityAccount?.id == account.id }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthExpenses: Decimal {
        filteredTransactions.filter { $0.type == .expense && $0.liquidityAccount?.id == account.id }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Tarjeta Física Visual Hero
                AccountVisualHero(account: account)
                    .padding(.horizontal)

                // 2. Si es préstamo, mostrar bloque de cuotas y botón de abono
                if account.accountType == .loan {
                    loanInstallmentCard
                        .padding(.horizontal)
                }

                // 3. Métricas Financieras del Periodo
                HStack(spacing: 12) {
                    MetricTile(
                        title: account.accountType == .loan ? "Deuda Pendiente" : "Saldo Real",
                        value: account.availableBalance.formatted(.currency(code: "MXN")),
                        subtitle: account.accountType == .loan ? "Pasivo a liquidar" : "Dinero disponible",
                        tintColor: account.accountType == .loan ? Color(hex: "#EF4444") : Color(hex: "#10B981")
                    )

                    MetricTile(
                        title: "Egresos del Mes",
                        value: monthExpenses.formatted(.currency(code: "MXN")),
                        subtitle: "Gastos registrados",
                        tintColor: Color(hex: "#EF4444")
                    )

                    MetricTile(
                        title: "Ingresos del Mes",
                        value: monthIncomes.formatted(.currency(code: "MXN")),
                        subtitle: "Abonos y depósitos",
                        tintColor: Color(hex: "#10B981")
                    )
                }
                .padding(.horizontal)

                // 4. Barra de Acciones Rápidas
                HStack(spacing: 10) {
                    if account.accountType == .loan {
                        Button {
                            isLoanPaymentSheetPresented = true
                        } label: {
                            Label("Abonar Cuota", systemImage: "dollarsign.circle.fill")
                                .font(.kashCaptionBold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#10B981"), in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    } else {
                        Button {
                            quickTxInitialType = .expense
                            isQuickTxSheetPresented = true
                        } label: {
                            Label("Gasto", systemImage: "minus.circle.fill")
                                .font(.kashCaptionBold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(Color(hex: "#EF4444"))
                        }

                        Button {
                            quickTxInitialType = .income
                            isQuickTxSheetPresented = true
                        } label: {
                            Label("Ingreso", systemImage: "plus.circle.fill")
                                .font(.kashCaptionBold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#10B981").opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(Color(hex: "#10B981"))
                        }

                        Button {
                            isTransferSheetPresented = true
                        } label: {
                            Label("Transferir", systemImage: "arrow.left.arrow.right")
                                .font(.kashCaptionBold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(Color(hex: "#2563EB"))
                        }
                    }
                }
                .padding(.horizontal)

                // 5. Filtro de Periodo
                PeriodFilterHeaderView(selection: $periodFilter)

                // 6. Lista de Movimientos de la Cuenta
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Movimientos de \(account.name)")
                            .font(.kashBodyBold)
                        Spacer()
                        Text("\(filteredTransactions.count) en periodo")
                            .font(.kashMicro)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    if filteredTransactions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text("Sin movimientos registrados en este periodo")
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filteredTransactions) { tx in
                                TransactionRowView(tx: tx, currentAccount: account)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        transactionToEdit = tx
                                    }
                                    .contextMenu {
                                        Button {
                                            transactionToEdit = tx
                                        } label: {
                                            Label("Editar", systemImage: "pencil")
                                        }

                                        Button(role: .destructive) {
                                            transactionToDelete = tx
                                            isShowingDeleteTransactionAlert = true
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                PrivacyToggleButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditAccountSheetPresented = true
                } label: {
                    Text("Editar")
                        .font(.kashCaptionBold)
                }
            }
        }
        .sheet(isPresented: $isEditAccountSheetPresented) {
            LiquidityAccountEditSheet(accountToEdit: account)
        }
        .sheet(isPresented: $isQuickTxSheetPresented) {
            QuickTransactionSheet()
        }
        .sheet(isPresented: $isTransferSheetPresented) {
            TransferSheet(preselectedSourceAccount: account)
        }
        .sheet(isPresented: $isLoanPaymentSheetPresented) {
            LoanPaymentSheet(targetLoan: account)
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
                Text("Se eliminará '\(tx.concept)' por \(tx.amount.formatted(.currency(code: "MXN"))). Los saldos se actualizarán automáticamente.")
            } else {
                Text("Esta acción eliminará el movimiento seleccionado.")
            }
        }
    }

    private var loanInstallmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Plan de Cuotas del Préstamo", systemImage: "chart.bar.fill")
                    .font(.kashCaptionBold)
                Spacer()
                Text("\(account.paidInstallments) de \(account.totalInstallments) pagadas")
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
            }

            if account.totalInstallments > 0 {
                let ratio = Double(account.paidInstallments) / Double(account.totalInstallments)
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: min(1.0, max(0.0, ratio)))
                        .tint(Color(hex: "#10B981"))
                    HStack {
                        Text("\(Int(ratio * 100))% liquidado")
                            .font(.kashMicro)
                            .foregroundStyle(Color(hex: "#10B981"))
                        Spacer()
                        Text("Monto cuota: \(account.installmentAmount.formatted(.currency(code: "MXN")))")
                            .font(.kashMicro)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func deleteTransaction(_ tx: Transaction) {
        // Revertir balances
        switch tx.type {
        case .expense:
            if let acc = tx.liquidityAccount {
                acc.availableBalance += tx.amount
            }
        case .income:
            if let acc = tx.liquidityAccount {
                acc.availableBalance -= tx.amount
            }
        case .cardPayment:
            if let acc = tx.liquidityAccount {
                acc.availableBalance += tx.amount
            }
        case .transfer:
            if let src = tx.liquidityAccount {
                src.availableBalance += tx.amount
            }
            if let dst = tx.destinationLiquidityAccount {
                dst.availableBalance -= tx.amount
            }
        }
        modelContext.delete(tx)
        try? modelContext.save()
        KASHWidgetSyncService.sync(modelContext: modelContext)
        transactionToDelete = nil
    }
}

// MARK: - AccountVisualHero (Tarjeta Física de Cuenta de Débito/Efectivo)
private struct AccountVisualHero: View {
    let account: LiquidityAccount

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: account.colorHex),
                            Color(hex: account.colorHex).opacity(0.85),
                            Color.black.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 190, height: 190)
                    .offset(x: geo.size.width - 90, y: -50)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.institution.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .tracking(1.2)
                        Text(account.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Text(account.accountType.title)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2), in: Capsule())
                }

                Spacer(minLength: 12)

                HStack {
                    if account.accountType == .debit || account.accountType == .savings {
                        EMVCardChipView(width: 32, height: 23)
                    } else {
                        Image(systemName: account.iconName)
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                }

                Spacer(minLength: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.accountType == .loan ? "SALDO DEUDOR PENDIENTE" : "DISPONIBLE REAL")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .tracking(0.6)

                    PrivacyAwareText(
                        amount: account.availableBalance,
                        font: .kashAmountLarge,
                        foregroundColor: .white
                    )
                }
            }
            .padding(16)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .frame(height: 165)
        .shadow(color: Color(hex: account.colorHex).opacity(0.35), radius: 8, y: 4)
    }
}

// MARK: - TransactionRowView
private struct TransactionRowView: View {
    let tx: Transaction
    let currentAccount: LiquidityAccount

    private var isOutgoing: Bool {
        if tx.type == .expense || tx.type == .cardPayment { return true }
        if tx.type == .transfer && tx.liquidityAccount?.id == currentAccount.id { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isOutgoing ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(isOutgoing ? Color(hex: "#EF4444") : Color(hex: "#10B981"))

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.concept)
                    .font(.kashBodyBold)
                    .lineLimit(1)
                Text(tx.transactionDate.spanishShortDate)
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                PrivacyAwareText(
                    amount: tx.amount,
                    font: .kashCaptionBold,
                    foregroundColor: isOutgoing ? Color(hex: "#EF4444") : Color(hex: "#10B981")
                )
                Text(tx.type.title)
                    .font(.kashMicro)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - MetricTile Helper
private struct MetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(tintColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
