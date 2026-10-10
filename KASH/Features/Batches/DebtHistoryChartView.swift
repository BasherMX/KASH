import SwiftUI
import UIKit
import Charts
import SwiftData

// MARK: - DebtHistoryChartView
/// Gráfico dinámico en Swift Charts que muestra la evolución de la deuda total en el tiempo
struct DebtHistoryChartView: View {
    let records: [MonthlyRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Evolución de Deuda")
                        .font(.kashBodyBold)
                    Text("Historial por corte mensual")
                        .font(.kashCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if records.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 180)
                    .overlay {
                        Text("Registra al menos un corte mensual para ver la gráfica")
                            .font(.kashCaption)
                            .foregroundStyle(.secondary)
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
                }
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
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 190)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var chartData: [ChartDebtItem] {
        records.sorted { $0.periodDate < $1.periodDate }.map { record in
            ChartDebtItem(
                id: record.id,
                date: record.periodDate,
                amount: NSDecimalNumber(decimal: record.totalDebt).doubleValue
            )
        }
    }
}

// MARK: - Modelo de Ayuda para Chart
struct ChartDebtItem: Identifiable {
    let id: UUID
    let date: Date
    let amount: Double
}
