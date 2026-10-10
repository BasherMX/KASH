import SwiftUI

// MARK: - Color Tokens FinTech Design System
/// Basado en los estándares de diseño financiero (Revolut / Robinhood / Wise / Stripe)
/// Soporte adaptativo para Modo Claro y Modo Oscuro
extension Color {
    static let kashBackgroundPrimary = Color("backgroundPrimary", bundle: nil)
    static let kashBackgroundSecondary = Color("backgroundSecondary", bundle: nil)
    static let kashBackgroundTertiary = Color("backgroundTertiary", bundle: nil)
    static let kashBrandPrimary = Color("brandPrimary", bundle: nil)
    static let kashScoreOptimal = Color("scoreOptimal", bundle: nil)
    static let kashScoreWarning = Color("scoreWarning", bundle: nil)
    static let kashScoreCritical = Color("scoreCritical", bundle: nil)
    static let kashTextPrimary = Color("textPrimary", bundle: nil)
    static let kashTextSecondary = Color("textSecondary", bundle: nil)
    static let kashCardBorder = Color("cardBorder", bundle: nil)
}

// MARK: - Fallback dinámico nativo para cuando no se usan Asset Catalogs
struct KashColors {
    static func backgroundPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#0B0E14") : Color(hex: "#F8FAFC")
    }

    static func backgroundSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#161B26") : Color(hex: "#FFFFFF")
    }

    static func backgroundTertiary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#222938") : Color(hex: "#F1F5F9")
    }

    static func brandPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#3B82F6") : Color(hex: "#2563EB")
    }

    static func scoreOptimal(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#059669") : Color(hex: "#10B981")
    }

    static func scoreWarning(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#D97706") : Color(hex: "#F59E0B")
    }

    static func scoreCritical(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#DC2626") : Color(hex: "#EF4444")
    }

    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#F8FAFC") : Color(hex: "#0F172A")
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#94A3B8") : Color(hex: "#64748B")
    }

    static func cardBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color(hex: "#0F172A").opacity(0.06)
    }
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        let uic = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uic.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - Keyboard Dismiss Utilities
extension View {
    /// Permite descartar el teclado interactivamente y al hacer scroll o tap en espacios libres
    func dismissKeyboardOnTap() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }
}

extension UIApplication {
    static func endEditing() {
        shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
