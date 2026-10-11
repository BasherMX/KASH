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
