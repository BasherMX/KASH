import SwiftUI
import UIKit
import Charts
import SwiftData

// MARK: - DebtHistoryChartView
/// Gráfico dinámico en Swift Charts que muestra la evolución de la deuda total en el tiempo
struct DebtHistoryChartView: View {
    let records: [MonthlyRecord]

    @State private var selectedDate: Date? = nil

    private var chartData: [ChartDebtItem] {
        records.sorted { $0.periodDate < $1.periodDate }.map { record in
            ChartDebtItem(
                id: record.id,
                date: record.periodDate,
                amount: NSDecimalNumber(decimal: record.totalDebt).doubleValue
            )
        }
    }

    private var selectedItem: ChartDebtItem? {
        guard let selectedDate = selectedDate else { return nil }
        return chartData.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Evolución de Deuda")
                        .font(.kashBodyBold)
                    if let sel = selectedItem {
                        HStack(spacing: 6) {
                            Text(sel.date.spanishMonthAndYear)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "#2563EB"))
                            Text("•")
                                .foregroundStyle(.secondary)
                            PrivacyAwareText(
                                amount: Decimal(sel.amount),
                                font: .kashCaptionBold,
                                foregroundColor: Color(hex: "#2563EB")
                            )
                        }
                    } else {
                        Text("Historial por corte mensual")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()

                if selectedItem != nil {
                    Button {
                        selectedDate = nil
                    } label: {
                        Text("Limpiar")
                            .font(.kashMicro)
                            .foregroundStyle(Color(hex: "#2563EB"))
                    }
                }
            }
            .frame(height: 38, alignment: .leading)

            if records.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 180)
                    .overlay {
                        Text("Registra al menos un corte mensual para ver la gráfica")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
                    }
            } else if chartData.count == 1, let single = chartData.first {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#2563EB").opacity(0.08))
                    .frame(height: 150)
                    .overlay {
                        VStack(spacing: 6) {
                            Text(single.date.spanishMonthAndYear)
                                .font(.kashCaptionBold)
                                .foregroundStyle(.secondary)
                            PrivacyAwareText(
                                amount: Decimal(single.amount),
                                font: .kashAmountLarge,
                                foregroundColor: Color(hex: "#2563EB")
                            )
                            Text("Registra un segundo corte mensual para trazar la curva de evolución.")
                                .font(.kashMicro)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
            } else {
                Chart {
                    ForEach(chartData) { item in
                        LineMark(
                            x: .value("Fecha", item.date),
                            y: .value("Deuda", item.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color(hex: "#2563EB"))
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        AreaMark(
                            x: .value("Fecha", item.date),
                            y: .value("Deuda", item.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#2563EB").opacity(0.35),
                                    Color(hex: "#2563EB").opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("Fecha", item.date),
                            y: .value("Deuda", item.amount)
                        )
                        .foregroundStyle(Color(hex: "#1E40AF"))
                    }

                    if let sel = selectedItem {
                        RuleMark(x: .value("Selección", sel.date))
                            .foregroundStyle(Color(hex: "#2563EB").opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .plot), y: .disabled)) {
                                VStack(spacing: 2) {
                                    Text(sel.date.spanishShortMonthName)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text(Decimal(sel.amount).formatted(.currency(code: "MXN")))
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#1E293B"), in: RoundedRectangle(cornerRadius: 6))
                                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                            }

                        PointMark(
                            x: .value("Fecha", sel.date),
                            y: .value("Deuda", sel.amount)
                        )
                        .symbolSize(90)
                        .foregroundStyle(Color(hex: "#2563EB"))
                    }
                }
                .chartXSelection(value: $selectedDate)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleVal = value.as(Double.self) {
                                Text("$\(Int(doubleVal / 1000))k")
                                    .font(.kashMicro)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let dateVal = value.as(Date.self) {
                                Text(dateVal.spanishShortMonthName)
                                    .font(.system(size: 10, weight: .medium))
                            }
                        }
                    }
                }
                .frame(height: 190)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Modelo de Ayuda para Chart
struct ChartDebtItem: Identifiable {
    let id: UUID
    let date: Date
    let amount: Double
}
