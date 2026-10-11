import SwiftUI

// MARK: - PeriodFilterMode
enum PeriodFilterMode: String, CaseIterable, Identifiable {
    case month = "month"
    case historical = "historical"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: return "Por Mes"
        case .historical: return "Histórico"
        }
    }
}

// MARK: - PeriodFilterSelection
struct PeriodFilterSelection: Equatable {
    var mode: PeriodFilterMode = .month
    var selectedMonthDate: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }()

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonthDate, equalTo: Date(), toGranularity: .month)
    }

    var selectedYear: Int {
        Calendar.current.component(.year, from: selectedMonthDate)
    }

    var selectedMonth: Int {
        Calendar.current.component(.month, from: selectedMonthDate)
    }

    var periodTitle: String {
        switch mode {
        case .month:
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "es_MX")
            fmt.dateFormat = "LLLL yyyy"
            return fmt.string(from: selectedMonthDate).capitalized
        case .historical:
            return "Histórico Completo"
        }
    }

    func matches(date: Date, calendar: Calendar = .current) -> Bool {
        switch mode {
        case .historical:
            return true
        case .month:
            return calendar.isDate(date, equalTo: selectedMonthDate, toGranularity: .month)
        }
    }

    mutating func shiftMonth(by delta: Int) {
        let cal = Calendar.current
        if let newDate = cal.date(byAdding: .month, value: delta, to: selectedMonthDate) {
            selectedMonthDate = newDate
        }
    }

    mutating func resetToCurrentMonth() {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        selectedMonthDate = cal.date(from: comps) ?? Date()
        mode = .month
    }

    mutating func setYearAndMonth(year: Int, month: Int) {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        if let newDate = cal.date(from: comps) {
            selectedMonthDate = newDate
            mode = .month
        }
    }
}

// MARK: - PeriodFilterHeaderView
/// Selector superior unificado para cambiar entre Mes Actual / Cualquier Mes y Vista Histórica
struct PeriodFilterHeaderView: View {
    @Binding var selection: PeriodFilterSelection

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(((currentYear - 5)...(currentYear + 1)).reversed())
    }

    private let monthNames: [(Int, String)] = [
        (1, "Enero"), (2, "Febrero"), (3, "Marzo"), (4, "Abril"),
        (5, "Mayo"), (6, "Junio"), (7, "Julio"), (8, "Agosto"),
        (9, "Septiembre"), (10, "Octubre"), (11, "Noviembre"), (12, "Diciembre")
    ]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                // Selector de Modo: Por Mes vs Histórico
                HStack(spacing: 4) {
                    ForEach(PeriodFilterMode.allCases) { mode in
                        let isSelected = selection.mode == mode
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection.mode = mode
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: mode == .month ? "calendar" : "clock.arrow.circlepath")
                                    .font(.system(size: 11, weight: .bold))
                                Text(mode.title)
                                    .font(.kashCaptionBold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                isSelected ? Color(hex: "#2563EB") : Color.clear,
                                in: Capsule()
                            )
                            .foregroundStyle(isSelected ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.secondary.opacity(0.12), in: Capsule())

                Spacer()

                if selection.mode == .month {
                    // Controles de navegación mensual
                    HStack(spacing: 6) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection.shiftMonth(by: -1)
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(Color.secondary.opacity(0.12), in: Circle())
                        }
                        .buttonStyle(.plain)

                        Menu {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selection.resetToCurrentMonth()
                                }
                            } label: {
                                Label("Ir al Mes Actual", systemImage: "calendar.badge.clock")
                            }

                            Divider()

                            ForEach(availableYears, id: \.self) { year in
                                Menu("Año \(String(year))") {
                                    ForEach(monthNames, id: \.0) { monthNum, monthTitle in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selection.setYearAndMonth(year: year, month: monthNum)
                                            }
                                        } label: {
                                            if selection.selectedYear == year && selection.selectedMonth == monthNum {
                                                Label("\(monthTitle) \(String(year))", systemImage: "checkmark")
                                            } else {
                                                Text("\(monthTitle) \(String(year))")
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selection.periodTitle)
                                    .font(.kashCaptionBold)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hex: "#2563EB"))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.12), in: Capsule())
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection.shiftMonth(by: 1)
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(Color.secondary.opacity(0.12), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection.resetToCurrentMonth()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Mes Actual")
                                .font(.kashMicro)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2563EB").opacity(0.12), in: Capsule())
                        .foregroundStyle(Color(hex: "#2563EB"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}
