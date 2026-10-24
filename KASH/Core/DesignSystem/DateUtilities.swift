import Foundation

// MARK: - Formateador Centralizado en Español (es_MX)
extension Date {
    /// Formato en español completo de mes y año (ej. "Octubre 2026")
    var spanishMonthAndYear: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_MX")
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: self).capitalized
    }

    /// Formato en español abreviado de mes y año (ej. "Oct 2026")
    var spanishShortMonthAndYear: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_MX")
        fmt.dateFormat = "LLL yyyy"
        return fmt.string(from: self).capitalized
    }

    /// Formato en español de solo mes completo (ej. "Octubre")
    var spanishMonthName: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_MX")
        fmt.dateFormat = "LLLL"
        return fmt.string(from: self).capitalized
    }

    /// Formato en español abreviado de solo mes (ej. "Oct")
    var spanishShortMonthName: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_MX")
        fmt.dateFormat = "LLL"
        return fmt.string(from: self).capitalized
    }

    /// Formato de fecha mediana legible en español (ej. "24 de oct de 2026")
    var spanishMediumDate: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_MX")
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: self)
    }

    /// Formato corto legible (ej. "24 oct")
    var spanishShortDate: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_MX")
        fmt.dateFormat = "d MMM"
        return fmt.string(from: self)
    }
}
