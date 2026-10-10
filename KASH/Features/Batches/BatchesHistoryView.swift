import SwiftUI
import UIKit
import SwiftData

// MARK: - BatchesHistoryView
struct BatchesHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MonthlyRecord.periodDate, order: .reverse) private var monthlyRecords: [MonthlyRecord]
    @State private var isBatchLogSheetPresented = false

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
                                    MonthlyRecordCard(record: record, previousRecord: previousRecord)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
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
        }
    }
}

// MARK: - MonthlyRecordCard
struct MonthlyRecordCard: View {
    let record: MonthlyRecord
    let previousRecord: MonthlyRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.periodDate.formatted(.dateTime.month(.wide).year()).capitalized)
                        .font(.kashBodyBold)

                    if let notes = record.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
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

            // Desglose de tarjetas en este corte
            if let balances = record.balances, !balances.isEmpty {
                Divider()
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
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
