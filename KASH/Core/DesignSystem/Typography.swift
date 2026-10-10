import SwiftUI

// MARK: - Typography Hierarchy
/// Estándar de tipografía financiera de alta legibilidad
extension Font {
    /// SF Pro Rounded - Para grandes balances y KPIs financieros
    static let kashAmountHero = Font.system(size: 32, weight: .bold, design: .rounded)
    static let kashAmountLarge = Font.system(size: 26, weight: .bold, design: .rounded)
    static let kashAmountMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let kashAmountSmall = Font.system(size: 16, weight: .semibold, design: .rounded)

    /// Textos de interfaz y jerarquía informativa
    static let kashTitleLarge = Font.system(size: 24, weight: .bold, design: .default)
    static let kashTitleMedium = Font.system(size: 18, weight: .semibold, design: .default)
    static let kashBody = Font.system(size: 15, weight: .regular, design: .default)
    static let kashBodyBold = Font.system(size: 15, weight: .semibold, design: .default)
    static let kashCaption = Font.system(size: 13, weight: .regular, design: .default)
    static let kashCaptionBold = Font.system(size: 13, weight: .semibold, design: .default)
    static let kashMicro = Font.system(size: 11, weight: .medium, design: .default)
}
