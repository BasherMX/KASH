import SwiftUI
import WidgetKit
import AppIntents

// MARK: - KASHSmallWidgetView (systemSmall 2x2)
struct KASHSmallWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#3B82F6"))
                    .widgetAccentable()

                Text("DEUDA TOTAL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Spacer()
            }

            Text(entry.totalDebt.formatted(.currency(code: "MXN")))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())
                .widgetAccentable()

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text("\(entry.healthStatus) (\(Int(entry.utilizationRatio * 100))% uso)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .widgetAccentable()
                }

                if let card = entry.nextUpcomingCard, let days = entry.nextUpcomingDays {
                    Text("Próx: \(card) (\(days)d)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Liquidez: \(entry.realLiquidity.formatted(.currency(code: "MXN")))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .widgetURL(URL(string: "kash://dashboard"))
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }

    private var statusColor: Color {
        if entry.utilizationRatio < 0.30 {
            return Color(hex: "#10B981")
        } else if entry.utilizationRatio <= 0.50 {
            return Color(hex: "#F59E0B")
        } else {
            return Color(hex: "#EF4444")
        }
    }
}

// MARK: - KASHUpcomingSmallWidgetView (systemSmall 2x2)
struct KASHUpcomingSmallWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#F59E0B"))
                    .widgetAccentable()
                Text("PRÓXIMO PAGO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if let card = entry.nextUpcomingCard, let days = entry.nextUpcomingDays {
                Text(card)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .widgetAccentable()

                Text(days == 0 ? "Vence hoy" : "En \(days) \(days == 1 ? "día" : "días")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(days <= 3 ? Color(hex: "#EF4444") : Color(hex: "#F59E0B"))
            } else {
                Text("Al día")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#10B981"))
                    .widgetAccentable()

                Text("Sin pagos urgentes")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(intent: PayCardIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.and.123")
                    Text("Pagar TDC")
                }
                .font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(Color(hex: "#2563EB").opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color(hex: "#2563EB"))
            }
            .buttonStyle(.plain)
        }
        .widgetURL(URL(string: "kash://pay"))
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - KASHMediumWidgetView (systemMedium 4x2 Interactivo)
struct KASHMediumWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header con métricas
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("💳 DEUDA TOTAL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    Text(entry.totalDebt.formatted(.currency(code: "MXN")))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentTransition(.numericText())
                        .widgetAccentable()
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    Text("% UTILIZACIÓN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text("\(Int(entry.utilizationRatio * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("SALUD BURÓ")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text("🟢 \(entry.healthStatus)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "#10B981"))
                        .widgetAccentable()
                }
            }

            Divider()

            // Botones de acción rápida con AppIntents (iOS 17+)
            HStack(spacing: 8) {
                Button(intent: QuickExpenseIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Gasto")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#EF4444"))
                }
                .buttonStyle(.plain)

                Button(intent: QuickIncomeIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Ingreso")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#10B981").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#10B981"))
                }
                .buttonStyle(.plain)

                Button(intent: PayCardIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                        Text("Pagar")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#2563EB"))
                }
                .buttonStyle(.plain)
            }
        }
        .widgetURL(URL(string: "kash://dashboard"))
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - KASHLargeWidgetView (systemLarge 4x4)
struct KASHLargeWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(Color(hex: "#3B82F6"))
                        .widgetAccentable()
                    Text("KASH FINANZAS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                }
                Spacer()
                Text("🟢 Buró: \(entry.healthStatus)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "#10B981"))
            }

            // Métrica Principal + Liquidez Real
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEUDA TOTAL ACUMULADA")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text(entry.totalDebt.formatted(.currency(code: "MXN")))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .widgetAccentable()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("LIQUIDEZ REAL")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text(entry.realLiquidity.formatted(.currency(code: "MXN")))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }

            // Barra de uso
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Uso de Línea de Crédito")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(entry.utilizationRatio * 100))%")
                        .font(.system(size: 10, weight: .bold))
                }
                ProgressView(value: min(1.0, entry.utilizationRatio), total: 1.0)
                    .tint(entry.utilizationRatio < 0.3 ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
            }

            if let card = entry.nextUpcomingCard, let days = entry.nextUpcomingDays {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color(hex: "#F59E0B"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Próximo Vencimiento")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("\(card) en \(days) días")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            // Botones de acción rápida
            HStack(spacing: 8) {
                Button(intent: QuickExpenseIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Gasto")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#EF4444"))
                }
                .buttonStyle(.plain)

                Button(intent: QuickIncomeIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Ingreso")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#10B981").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#10B981"))
                }
                .buttonStyle(.plain)

                Button(intent: PayCardIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                        Text("Pagar")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#2563EB"))
                }
                .buttonStyle(.plain)
            }
        }
        .widgetURL(URL(string: "kash://dashboard"))
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - KASHAccessoryRectangularWidgetView (Lock Screen)
struct KASHAccessoryRectangularWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 10))
                Text("KASH")
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                Text("\(Int(entry.utilizationRatio * 100))% uso")
                    .font(.system(size: 9, weight: .semibold))
            }
            .widgetAccentable()

            Text(entry.totalDebt.formatted(.currency(code: "MXN")))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("Buró: \(entry.healthStatus)" + (entry.nextUpcomingCard != nil ? " • \(entry.nextUpcomingCard!)" : ""))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .widgetURL(URL(string: "kash://dashboard"))
        .containerBackground(for: .widget) { }
    }
}

// MARK: - KASHAccessoryCircularWidgetView (Lock Screen Circular)
struct KASHAccessoryCircularWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        Gauge(value: min(1.0, max(0.0, entry.utilizationRatio)), in: 0...1) {
            Image(systemName: "creditcard.fill")
        } currentValueLabel: {
            Text("\(Int(entry.utilizationRatio * 100))%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .widgetAccentable()
        .widgetURL(URL(string: "kash://dashboard"))
        .containerBackground(for: .widget) { }
    }
}

// MARK: - KASHAccessoryInlineWidgetView (Lock Screen Inline)
struct KASHAccessoryInlineWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        Text("💳 KASH: \(entry.totalDebt.formatted(.currency(code: "MXN"))) (\(Int(entry.utilizationRatio * 100))%)")
            .widgetURL(URL(string: "kash://dashboard"))
            .containerBackground(for: .widget) { }
    }
}

// MARK: - KASHMonthlyFlowMediumWidgetView (systemMedium 4x2 - Mes, Gastos | Ingresos, Botones)
struct KASHMonthlyFlowMediumWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(spacing: 10) {
            // Fila Superior: MES en mayúsculas (ej. OCTUBRE)
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "#2563EB"))
                        .widgetAccentable()

                    Text(entry.currentMonthName.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.primary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.currentMonthIncome >= entry.currentMonthExpenses ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                        .frame(width: 6, height: 6)

                    Text(entry.currentMonthIncome >= entry.currentMonthExpenses ? "Finanzas Sanas" : "Alerta de Gasto")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            // Fila Central: GASTOS | INGRESOS en una misma fila
            HStack(spacing: 0) {
                // GASTOS
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: "#EF4444")).frame(width: 5, height: 5)
                        Text("GASTOS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }

                    Text(entry.currentMonthExpenses.formatted(.currency(code: "MXN")))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#EF4444"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .widgetAccentable()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Separador vertical "|"
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 1.5, height: 28)
                    .padding(.horizontal, 10)

                // INGRESOS
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: "#10B981")).frame(width: 5, height: 5)
                        Text("INGRESOS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }

                    Text(entry.currentMonthIncome.formatted(.currency(code: "MXN")))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#10B981"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .widgetAccentable()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 4)

            Divider()

            // Fila Inferior: + Gasto | + Ingreso | Pagar
            HStack(spacing: 8) {
                Button(intent: QuickExpenseIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Gasto")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#EF4444"))
                }
                .buttonStyle(.plain)

                Button(intent: QuickIncomeIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Ingreso")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#10B981").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#10B981"))
                }
                .buttonStyle(.plain)

                Button(intent: PayCardIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                        Text("Pagar")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#2563EB"))
                }
                .buttonStyle(.plain)
            }
        }
        .widgetURL(URL(string: "kash://dashboard"))
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - KASHMonthlyFlowSmallWidgetView (systemSmall 2x2)
struct KASHMonthlyFlowSmallWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.currentMonthName.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Color(hex: "#2563EB"))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("GASTOS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(entry.currentMonthExpenses.formatted(.currency(code: "MXN")))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#EF4444"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("INGRESOS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(entry.currentMonthIncome.formatted(.currency(code: "MXN")))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#10B981"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            HStack(spacing: 4) {
                Button(intent: QuickExpenseIntent()) {
                    Text("+ Gasto")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(Color(hex: "#EF4444"))
                }
                .buttonStyle(.plain)

                Button(intent: QuickIncomeIntent()) {
                    Text("+ Ingreso")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#10B981").opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
                .buttonStyle(.plain)
            }
        }
        .widgetURL(URL(string: "kash://dashboard"))
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - KASHMonthlyFlowLargeWidgetView (systemLarge 4x4)
struct KASHMonthlyFlowLargeWidgetView: View {
    let entry: KASHWidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color(hex: "#2563EB"))
                    Text(entry.currentMonthName.uppercased())
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(0.5)
                }
                Spacer()
                Text(entry.currentMonthIncome >= entry.currentMonthExpenses ? "🟢 Finanzas Sanas" : "🔴 Alerta")
                    .font(.system(size: 11, weight: .semibold))
            }

            // GASTOS | INGRESOS
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GASTOS DEL MES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(entry.currentMonthExpenses.formatted(.currency(code: "MXN")))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#EF4444"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 1.5, height: 32)
                    .padding(.horizontal, 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("INGRESOS DEL MES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(entry.currentMonthIncome.formatted(.currency(code: "MXN")))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 4)

            Divider()

            // Balance neto
            let net = entry.currentMonthIncome - entry.currentMonthExpenses
            HStack {
                Text("Balance Neto Estimado:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text((net >= 0 ? "+" : "") + net.formatted(.currency(code: "MXN")))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(net >= 0 ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
            }

            // Deuda y Liquidez
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deuda Total")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(entry.totalDebt.formatted(.currency(code: "MXN")))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Liquidez Real")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(entry.realLiquidity.formatted(.currency(code: "MXN")))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }

            Spacer()

            // Botones
            HStack(spacing: 8) {
                Button(intent: QuickExpenseIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Gasto")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#EF4444"))
                }
                .buttonStyle(.plain)

                Button(intent: QuickIncomeIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Ingreso")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#10B981").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#10B981"))
                }
                .buttonStyle(.plain)

                Button(intent: PayCardIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                        Text("Pagar")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: "#2563EB"))
                }
                .buttonStyle(.plain)
            }
        }
        .widgetURL(URL(string: "kash://dashboard"))
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - KASHMonthlyFlowWidgetEntryView
struct KASHMonthlyFlowWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: KASHWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            KASHMonthlyFlowSmallWidgetView(entry: entry)
        case .systemMedium:
            KASHMonthlyFlowMediumWidgetView(entry: entry)
        case .systemLarge:
            KASHMonthlyFlowLargeWidgetView(entry: entry)
        default:
            KASHMonthlyFlowMediumWidgetView(entry: entry)
        }
    }
}
