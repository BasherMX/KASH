import Foundation
import UserNotifications

// MARK: - NotificationManager
/// Administrador de Notificaciones Locales (Offline-first)
/// Gestiona recordatorios mensuales de registro de cortes y avisos de vencimientos de tarjetas
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized: Bool = false

    private init() {
        checkAuthorization()
    }

    /// Verifica el estado actual del permiso de notificaciones
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Solicita permiso al usuario para enviar notificaciones locales
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            self.isAuthorized = granted
            return granted
        } catch {
            self.isAuthorized = false
            return false
        }
    }

    /// Programa recordatorio mensual para registrar los cortes de las tarjetas (ej. Día 5 de cada mes a las 9:00 AM)
    func scheduleMonthlyCutoffReminder(dayOfMonth: Int) {
        let center = UNUserNotificationCenter.current()
        let identifier = "kash.monthly.cutoff.reminder"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "📅 Recordatorio de Corte Mensual KASH"
        content.body = "Es momento de capturar los saldos deudores de tus estados de cuenta para actualizar tus métricas."
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.day = min(dayOfMonth, 28)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    /// Programa alertas de anticipación para pagos próximos a vencer
    func schedulePaymentDueReminder(cardName: String, dueDate: Date, daysBefore: Int, amount: Decimal) {
        let center = UNUserNotificationCenter.current()
        let identifier = "kash.payment.due.\(cardName).\(dueDate.timeIntervalSince1970)"

        guard isAuthorized else { return }

        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate) else { return }

        // Si la fecha de recordatorio ya pasó, no programar
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "💳 Vencimiento Próximo: \(cardName)"
        content.body = "Tu tarjeta vence en \(daysBefore) días. Monto para no generar intereses: $\(amount)."
        content.sound = .default

        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    /// Solicita autorización si es necesario y envía una notificación local de prueba tras 2 segundos
    func sendTestNotification() async -> Bool {
        let granted = isAuthorized ? true : await requestAuthorization()
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = "🔔 Prueba de Notificación KASH"
        content.body = "¡Excelente! El sistema de notificaciones está funcionando correctamente. Recibirás avisos de cortes y fechas límite."
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest(
            identifier: "kash.test.notification.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            return false
        }
    }
}
