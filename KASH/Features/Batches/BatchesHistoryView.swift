import SwiftUI
import UIKit
import SwiftData
import WidgetKit

// MARK: - BatchesHistoryView
struct BatchesHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MonthlyRecord.periodDate, order: .reverse) private var monthlyRecords: [MonthlyRecord]

    @State private var periodFilter = PeriodFilterSelection()
    @State private var expandedYears: Set<Int> = [Calendar.current.component(.year, from: Date())]
    @State private var isBatchLogSheetPresented = false
    @State private var recordToEdit: MonthlyRecord? = nil
    @State private var recordToDelete: MonthlyRecord? = nil
    @State private var isShowingDeleteConfirmation = false

    private var filteredRecords: [MonthlyRecord] {
        monthlyRecords.filter { rec in
            periodFilter.matches(date: rec.periodDate)
        }
    }

    private var allRecordsGroupedByYear: [(year: Int, records: [MonthlyRecord])] {
        let grouped = Dictionary(grouping: monthlyRecords) { rec in
            Calendar.current.component(.year, from: rec.periodDate)
        }
        return grouped.keys.sorted(by: >).map { year in
            let sortedInYear = (grouped[year] ?? []).sorted { $0.periodDate > $1.periodDate }
            return (year: year, records: sortedInYear)
        }
    }

    private func chronologicalPreviousRecord(for record: MonthlyRecord) -> MonthlyRecord? {
        guard let idx = monthlyRecords.firstIndex(where: { $0.id == record.id }) else { return nil }
        return idx + 1 < monthlyRecords.count ? monthlyRecords[idx + 1] : nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Selector de Mes / Histórico arriba en la pestaña (por defecto Mes Actual)
                PeriodFilterHeaderView(selection: $periodFilter)
                    .onChange(of: periodFilter.selectedMonthDate) { _, _ in
                        expandedYears.insert(periodFilter.selectedYear)
                    }

                Divider()

                ScrollView {
                    VStack(spacing: 18) {
                        // 2. Gráfico de historial de evolución de deuda
                        DebtHistoryChartView(records: monthlyRecords)
                            .padding(.horizontal)

                        // 3. Si está en modo Mes, mostrar tarjeta destacada del mes seleccionado
                        if periodFilter.mode == .month {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Corte de \(periodFilter.periodTitle)")
                                        .font(.kashTitleMedium)
                                    Spacer()
                                    if !monthlyRecords.isEmpty {
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                periodFilter.mode = .historical
                                            }
                                        } label: {
                                            Text("Modo Histórico (\(monthlyRecords.count))")
                                                .font(.kashCaptionBold)
                                                .foregroundStyle(Color(hex: "#2563EB"))
                                        }
                                    }
                                }
                                .padding(.horizontal)

                                if filteredRecords.isEmpty {
                                    HStack(spacing: 12) {
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.system(size: 26))
                                            .foregroundStyle(Color(hex: "#2563EB"))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Sin corte registrado en \(periodFilter.periodTitle)")
                                                .font(.kashCaptionBold)
                                            Text("Registra el corte de este periodo para actualizar tus métricas.")
                                                .font(.kashMicro)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Button {
                                            isBatchLogSheetPresented = true
                                        } label: {
                                            Text("Registrar")
                                                .font(.kashCaptionBold)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 7)
                                                .background(Color(hex: "#2563EB"), in: Capsule())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(16)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(filteredRecords) { record in
                                            let prev = chronologicalPreviousRecord(for: record)
                                            MonthlyRecordCard(
                                                record: record,
                                                previousRecord: prev,
                                                onEdit: {
                                                    recordToEdit = record
                                                },
                                                onDelete: {
                                                    recordToDelete = record
                                                    isShowingDeleteConfirmation = true
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // 4. Historial de Cortes agrupado por año y colapsable (Año actual descolapsado por defecto)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Historial de Cortes por Año")
                                    .font(.kashTitleMedium)
                                Spacer()
                                if !monthlyRecords.isEmpty {
                                    Text("\(monthlyRecords.count) \(monthlyRecords.count == 1 ? "corte" : "cortes")")
                                        .font(.kashCaption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)

                            if monthlyRecords.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                    Text("Aún no tienes cortes mensuales registrados")
                                        .font(.kashBodyBold)
                                        .multilineTextAlignment(.center)

                                    Text("Registra tu primer corte con el botón superior para calcular deltas y gráficas de amortización.")
                                        .font(.kashCaption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)

                                    Button {
                                        isBatchLogSheetPresented = true
                                    } label: {
                                        Label("Registrar Corte", systemImage: "plus.circle.fill")
                                            .font(.kashCaptionBold)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color(hex: "#2563EB"), in: Capsule())
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.top, 4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(28)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(allRecordsGroupedByYear, id: \.year) { group in
                                        let isYearExpanded = expandedYears.contains(group.year)
                                        VStack(spacing: 10) {
                                            // Cabecera de Año colapsable (Año actual descolapsado por defecto)
                                            Button {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                                    if isYearExpanded {
                                                        expandedYears.remove(group.year)
                                                    } else {
                                                        expandedYears.insert(group.year)
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: isYearExpanded ? "folder.fill" : "folder")
                                                            .font(.system(size: 15, weight: .semibold))
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
                                                    }

                                                    Spacer()

                                                    Text("\(group.records.count) \(group.records.count == 1 ? "corte" : "cortes")")
                                                        .font(.kashMicro)
                                                        .foregroundStyle(.secondary)

                                                    Image(systemName: isYearExpanded ? "chevron.up" : "chevron.down")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundStyle(.secondary)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                                            }
                                            .buttonStyle(.plain)

                                            if isYearExpanded {
                                                VStack(spacing: 10) {
                                                    ForEach(group.records) { record in
                                                        let prev = chronologicalPreviousRecord(for: record)
                                                        MonthlyRecordCard(
                                                            record: record,
                                                            previousRecord: prev,
                                                            onEdit: {
                                                                recordToEdit = record
                                                            },
                                                            onDelete: {
                                                                recordToDelete = record
                                                                isShowingDeleteConfirmation = true
                                                            }
                                                        )
                                                    }
                                                }
                                                .padding(.leading, 6)
                                                .transition(.opacity.combined(with: .move(edge: .top)))
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
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Cortes Mensuales")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    PrivacyToggleButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isBatchLogSheetPresented = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Registrar Corte")
                        }
                        .font(.kashCaptionBold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2563EB"), in: Capsule())
                        .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $isBatchLogSheetPresented) {
                BatchLogSheet()
            }
            .sheet(item: $recordToEdit) { record in
                BatchLogSheet(editingRecord: record)
            }
            .alert("¿Eliminar Corte?", isPresented: $isShowingDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {
                    recordToDelete = nil
                }
                Button("Eliminar", role: .destructive) {
                    if let rec = recordToDelete {
                        deleteRecord(rec)
                    }
                }
            } message: {
                if let rec = recordToDelete {
                    Text("Se eliminará el corte de \(rec.periodDate.spanishMonthAndYear). Esta acción no se puede deshacer.")
                } else {
                    Text("Esta acción eliminará el registro del corte y sus saldos asociados.")
                }
            }
        }
    }

    private func deleteRecord(_ record: MonthlyRecord) {
        modelContext.delete(record)
        try? modelContext.save()
        KASHWidgetSyncService.sync(modelContext: modelContext)
        recordToDelete = nil
    }
}

// MARK: - MonthlyRecordCard
struct MonthlyRecordCard: View {
    let record: MonthlyRecord
    let previousRecord: MonthlyRecord?
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Fila superior (siempre visible y clickeable para colapsar/descolapsar)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(record.periodDate.spanishMonthAndYear)
                                .font(.kashBodyBold)
                                .foregroundStyle(.primary)

                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "#2563EB"))
                        }

                        if let notes = record.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.kashCaption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        PrivacyAwareText(amount: record.totalDebt, font: .kashAmountMedium)

                        // Delta respecto al mes anterior ($ y %)
                        if let previous = previousRecord {
                            let delta = record.totalDebt - previous.totalDebt
                            let isReduction = delta <= 0

                            HStack(spacing: 4) {
                                Image(systemName: isReduction ? "arrow.down.right" : "arrow.up.right")
                                    .font(.system(size: 11, weight: .bold))

                                Text(delta >= 0 ? "+\(delta.formatted(.currency(code: "MXN")))" : delta.formatted(.currency(code: "MXN")))
                                    .font(.kashMicro)
                            }
                            .foregroundStyle(isReduction ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Contenido expandible (colapsado por defecto)
            if isExpanded {
                VStack(spacing: 10) {
                    Divider()

                    if let balances = record.balances, !balances.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(balances) { b in
                                HStack {
                                    Circle()
                                        .fill(Color(hex: b.card?.colorHex ?? "#64748B"))
                                        .frame(width: 8, height: 8)

                                    Text(b.card?.name ?? "Tarjeta")
                                        .font(.kashCaption)

                                    Spacer()

                                    PrivacyAwareText(amount: b.balanceUsed, font: .kashCaptionBold)
                                }
                            }
                        }
                    } else {
                        Text("Sin desglose de tarjetas para este periodo")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Acciones de edición y eliminación
                    HStack(spacing: 12) {
                        Button {
                            onEdit()
                        } label: {
                            Label("Editar Corte", systemImage: "pencil")
                                .font(.kashCaptionBold)
                                .foregroundStyle(Color(hex: "#2563EB"))
                        }

                        Spacer()

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                                .font(.kashCaptionBold)
                                .foregroundStyle(Color(hex: "#EF4444"))
                        }
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
