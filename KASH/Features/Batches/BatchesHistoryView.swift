import SwiftUI
import UIKit
import SwiftData

// MARK: - BatchesHistoryView
struct BatchesHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MonthlyRecord.periodDate, order: .reverse) private var monthlyRecords: [MonthlyRecord]

    @State private var isBatchLogSheetPresented = false
    @State private var recordToEdit: MonthlyRecord? = nil
    @State private var recordToDelete: MonthlyRecord? = nil
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Gráfico de historial
                    DebtHistoryChartView(records: monthlyRecords)
                        .padding(.horizontal)

                    // Lista de registros mensuales
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Historial de Cortes")
                            .font(.kashTitleMedium)
                            .padding(.horizontal)

                        if monthlyRecords.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("Aún no tienes cortes mensuales registrados")
                                    .font(.kashBodyBold)
                                Text("Registra tu primer corte con el botón superior para calcular deltas y gráficas de amortización.")
                                    .font(.kashCaption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(32)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(monthlyRecords.enumerated()), id: \.element.id) { index, record in
                                    let previousRecord = index + 1 < monthlyRecords.count ? monthlyRecords[index + 1] : nil
                                    MonthlyRecordCard(
                                        record: record,
                                        previousRecord: previousRecord,
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
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
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
                    Text("Se eliminará el corte de \(rec.periodDate.formatted(.dateTime.month(.wide).year())). Esta acción no se puede deshacer.")
                } else {
                    Text("Esta acción eliminará el registro del corte y sus saldos asociados.")
                }
            }
        }
    }

    private func deleteRecord(_ record: MonthlyRecord) {
        modelContext.delete(record)
        try? modelContext.save()
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
                            Text(record.periodDate.formatted(.dateTime.month(.wide).year()).capitalized)
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
