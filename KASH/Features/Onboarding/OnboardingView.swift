import SwiftUI
import SwiftData

// MARK: - OnboardingView
/// Flujo de Bienvenida y Configuración Limpia (Zero Hardcoded Data)
/// Enseña la Regla de Oro y asiste al usuario a registrar su primera cuenta con respeto absoluto a Safe Areas y textos multilínea.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 0
    @State private var initialSalaryString: String = ""
    @State private var initialCardName: String = ""
    @State private var initialCardLimitString: String = ""
    @State private var initialDebitName: String = ""
    @State private var initialDebitBalanceString: String = ""

    var body: some View {
        ZStack {
            // Fondo adaptativo que cubre el 100% de la pantalla
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Barra de progreso fija superior (dentro de safe area)
                progressBarView
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                // 2. Contenido scrolleable para evitar colisión de teclado y recortes en cualquier pantalla
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        Group {
                            switch currentStep {
                            case 0:
                                welcomeStepView
                            case 1:
                                goldenRuleStepView
                            case 2:
                                initialSetupStepView
                            default:
                                completionStepView
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }
                .scrollDismissesKeyboard(.interactively)

                // 3. Botones de acción inferiores fijados sobre el safe area inferior
                navigationControlsView
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .background(
                        Color(uiColor: .systemGroupedBackground)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: -4)
                    )
            }
        }
    }

    // MARK: - Barra de Progreso
    private var progressBarView: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(index <= currentStep ? Color(hex: "#2563EB") : Color.secondary.opacity(0.2))
                    .frame(height: 5)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - PASO 0: BIENVENIDA
    private var welcomeStepView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#2563EB").opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 46))
                    .foregroundStyle(Color(hex: "#2563EB"))
            }

            VStack(spacing: 8) {
                Text("Bienvenido a KASH")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text("El gestor financiero personal 100% offline-first, privado y seguro.")
                    .font(.kashBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                featureBenefitRow(
                    icon: "lock.shield.fill",
                    color: Color(hex: "#10B981"),
                    title: "100% Offline y Seguro",
                    subtitle: "Tus datos nunca salen de tu iPhone ni se conectan a servidores."
                )

                featureBenefitRow(
                    icon: "scalemass.fill",
                    color: Color(hex: "#2563EB"),
                    title: "Regla de Oro Financiera",
                    subtitle: "Tu línea de crédito jamás se confunde con tu dinero propio."
                )

                featureBenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color(hex: "#8B5CF6"),
                    title: "Control de Cortes y Buró",
                    subtitle: "Monitorea tu porcentaje de uso para mantener un buró impecable."
                )
            }
        }
    }

    private func featureBenefitRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.kashBodyBold)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - PASO 1: REGLA DE ORO
    private var goldenRuleStepView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#F59E0B").opacity(0.15))
                    .frame(width: 90, height: 90)

                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: "#F59E0B"))
            }

            VStack(spacing: 6) {
                Text("La Regla de Oro")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }

            // Banner destacado de la regla
            VStack(spacing: 8) {
                Text("⚠️ \"El crédito disponible en una Tarjeta de Crédito NO es dinero propio.\"")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: "#DC2626"))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#DC2626").opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            // Explicación detallada sin truncar
            VStack(alignment: .leading, spacing: 12) {
                Text("En KASH tu disponible de tarjeta se muestra estrictamente como Capacidad de Endeudamiento, jamás como liquidez.")
                    .font(.kashBody)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Tu Liquidez Real solo se compone de tu dinero propio (cuentas de débito y efectivo disponible).")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

            // Comparativa visual
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("Dinero Propio (Débito) = Tu Liquidez Real")
                        .font(.kashCaptionBold)
                        .foregroundStyle(Color(hex: "#10B981"))
                    Spacer()
                }

                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(hex: "#EF4444"))
                    Text("Línea de Crédito TDC = Pasivo / Deuda Potencial")
                        .font(.kashCaptionBold)
                        .foregroundStyle(Color(hex: "#EF4444"))
                    Spacer()
                }
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - PASO 2: ASISTENTE INICIAL
    private var initialSetupStepView: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Configuración Básica")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Cero datos quemados en el código. Agrega tu información real para personalizar tus métricas:")
                    .font(.kashBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 16) {
                // Campo 1: Sueldo
                VStack(alignment: .leading, spacing: 6) {
                    Label("Tu Sueldo Mensual Neto", systemImage: "banknote")
                        .font(.kashCaptionBold)
                        .foregroundStyle(.primary)

                    TextField("$ 0.00", text: $initialSalaryString)
                        .keyboardType(.decimalPad)
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                // Campo 2: Tarjeta Principal
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tu Tarjeta de Crédito Principal", systemImage: "creditcard")
                        .font(.kashCaptionBold)
                        .foregroundStyle(.primary)

                    TextField("Nombre (Ej. Nu, BBVA Platino)", text: $initialCardName)
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                    TextField("Límite de Crédito ($)", text: $initialCardLimitString)
                        .keyboardType(.decimalPad)
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                // Campo 3: Débito Principal
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tu Cuenta de Débito o Efectivo Principal", systemImage: "dollarsign.circle")
                        .font(.kashCaptionBold)
                        .foregroundStyle(.primary)

                    TextField("Nombre (Ej. BBVA Nómina, Efectivo)", text: $initialDebitName)
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                    TextField("Saldo Actual ($)", text: $initialDebitBalanceString)
                        .keyboardType(.decimalPad)
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - PASO 3: TODO LISTO
    private var completionStepView: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#10B981").opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color(hex: "#10B981"))
            }

            VStack(spacing: 10) {
                Text("¡Todo Listo!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("Tus datos están protegidos en reposo bajo el Secure Enclave de tu dispositivo.")
                    .font(.kashBody)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text("KASH no se conecta a internet ni comparte tu información personal con nadie. Tus finanzas están en tus manos.")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Botones de Navegación
    private var navigationControlsView: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if currentStep < 3 {
                        currentStep += 1
                    } else {
                        completeOnboarding()
                    }
                }
            } label: {
                Text(currentStep == 3 ? "Empezar a Usar KASH" : "Continuar")
                    .font(.kashBodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#2563EB"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if currentStep == 0 {
                Button("Omitir y configurar después") {
                    completeOnboarding()
                }
                .font(.kashCaption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
            }
        }
    }

    private func completeOnboarding() {
        let salary = Decimal(string: initialSalaryString.replacingOccurrences(of: ",", with: "")) ?? 0
        let cardLimit = Decimal(string: initialCardLimitString.replacingOccurrences(of: ",", with: "")) ?? 0
        let debitBalance = Decimal(string: initialDebitBalanceString.replacingOccurrences(of: ",", with: "")) ?? 0

        let settingsDescriptor = FetchDescriptor<UserSettings>()
        let settings = (try? modelContext.fetch(settingsDescriptor))?.first ?? UserSettings()
        if salary > 0 {
            settings.monthlyIncome = salary
        }

        if !initialCardName.isEmpty && cardLimit > 0 {
            let card = CreditCard(
                name: initialCardName,
                institution: initialCardName,
                creditLimit: cardLimit,
                cutoffDay: 5,
                paymentDueDay: 25,
                colorHex: "#1E293B"
            )
            modelContext.insert(card)
        }

        if !initialDebitName.isEmpty {
            let acc = LiquidityAccount(
                name: initialDebitName,
                institution: initialDebitName,
                availableBalance: debitBalance,
                accountType: .debit,
                colorHex: "#2563EB"
            )
            modelContext.insert(acc)
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}
