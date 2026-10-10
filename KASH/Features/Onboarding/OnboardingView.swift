import SwiftUI
import SwiftData

// MARK: - OnboardingView
/// Flujo de Bienvenida y Configuración Limpia (Zero Hardcoded Data)
/// Enseña la Regla de Oro y asiste al usuario a registrar su primera cuenta o importar datos.
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
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Barra de progreso
                HStack(spacing: 6) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index <= currentStep ? Color(hex: "#2563EB") : Color.secondary.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)

                Spacer()

                // Contenido del Paso
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
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                Spacer()

                // Botones de Navegación
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // PASO 0: BIENVENIDA
    private var welcomeStepView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#2563EB").opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 54))
                    .foregroundStyle(Color(hex: "#2563EB"))
            }

            VStack(spacing: 8) {
                Text("Bienvenido a KASH")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("El gestor financiero personal 100% offline-first, privado y seguro.")
                    .font(.kashBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // PASO 1: REGLA DE ORO FINANCIERA
    private var goldenRuleStepView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#F59E0B").opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: "#F59E0B"))
            }

            VStack(spacing: 12) {
                Text("La Regla de Oro")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("⚠️ \"El crédito disponible en una Tarjeta de Crédito NO es dinero propio.\"")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#DC2626"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("En KASH tu disponible se muestra como Capacidad de Endeudamiento, jamás como liquidez. Tu Liquidez Real solo se compone de tu dinero propio.")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // PASO 2: ASISTENTE INICIAL (OPCIONAL)
    private var initialSetupStepView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Configuración Básica")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text("Cero datos quemados en el código. Agrega tu información real:")
                    .font(.kashCaption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu Sueldo Mensual Neto ($)")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                    TextField("$ 0.00", text: $initialSalaryString)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu Tarjeta de Crédito Principal")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("Ej. Nu / BBVA", text: $initialCardName)
                        TextField("Límite ($)", text: $initialCardLimitString)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu Cuenta de Débito / Efectivo")
                        .font(.kashMicro)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("Ej. BBVA Nómina", text: $initialDebitName)
                        TextField("Saldo ($)", text: $initialDebitBalanceString)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // PASO 3: TODO LISTO
    private var completionStepView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#10B981").opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(Color(hex: "#10B981"))
            }

            VStack(spacing: 10) {
                Text("¡Todo Listo!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("Tus datos están protegidos en reposo bajo el Secure Enclave de tu dispositivo. KASH no se conecta a internet ni comparte tu información.")
                    .font(.kashBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        }
    }

    private func completeOnboarding() {
        // Guardar configuración inicial introducida si existe
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
