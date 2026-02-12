import Foundation
import UserNotifications

/// Сервис локальных уведомлений на базе `UNUserNotificationCenter`.
///
/// Отправляет уведомления об изменении статуса рейсов и напоминания о вылете,
/// а также управляет разрешениями и категориями уведомлений.
final class NotificationService {

    /// Синглтон‑экземпляр сервиса уведомлений.
    static let shared = NotificationService()

    /// Центр уведомлений, предоставленный iOS.
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Разрешения

    /// Запрашивает у пользователя разрешение на показ локальных уведомлений.
    ///
    /// - Parameter completion: Клоужер, в который прокидывается флаг `granted`
    ///   (`true`, если пользователь выдал разрешение).
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.error("Ошибка запроса уведомлений", error: error)
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Проверить текущий статус разрешений
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Уведомления о статусе рейса

    /// Планирует уведомление об изменении статуса рейса.
    ///
    /// - Parameters:
    ///   - flightNumber: Номер рейса.
    ///   - status: Новый статус рейса.
    ///   - departureAirport: Название аэропорта вылета.
    ///   - arrivalAirport: Название аэропорта прилёта.
    func scheduleFlightStatusNotification(
        flightNumber: String,
        status: FlightStatus,
        departureAirport: String,
        arrivalAirport: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(flightNumber) — \(status.displayName)"
        content.body = "\(departureAirport) → \(arrivalAirport)"
        content.sound = .default
        content.categoryIdentifier = Constants.NotificationCategory.flightStatus

        let identifier = "flight_status_\(flightNumber)_\(Date().timeIntervalSince1970)"

        // Отправляем уведомление практически немедленно (через 1 секунду).
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Ошибка отправки уведомления", error: error)
            } else {
                Logger.data("Уведомление отправлено: \(flightNumber) — \(status.displayName)")
            }
        }
    }

    // MARK: - Напоминание о вылете

    /// Планирует напоминание о вылете за указанное количество минут до отправления.
    ///
    /// - Parameters:
    ///   - flightNumber: Номер рейса.
    ///   - departureDate: Время вылета.
    ///   - minutesBefore: За сколько минут до вылета напомнить (по умолчанию 60).
    func scheduleDepartureReminder(
        flightNumber: String,
        departureDate: Date,
        minutesBefore: Int = 60
    ) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.departure.title", comment: "")
        content.body = String(
            format: NSLocalizedString("notification.departure.body", comment: ""),
            flightNumber, minutesBefore
        )
        content.sound = .default
        content.categoryIdentifier = Constants.NotificationCategory.departureReminder

        // Вычисляем дату уведомления относительно времени вылета.
        let notificationDate = departureDate.addingTimeInterval(-Double(minutesBefore * 60))
        guard notificationDate > Date() else {
            Logger.data("Напоминание не запланировано — дата уже прошла")
            return
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "departure_reminder_\(flightNumber)"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Ошибка планирования напоминания", error: error)
            } else {
                Logger.data("Напоминание запланировано: \(flightNumber) за \(minutesBefore) мин")
            }
        }
    }

    // MARK: - Управление уведомлениями

    /// Удаляет все запланированные уведомления, связанные с конкретным рейсом.
    ///
    /// - Parameter flightNumber: Номер рейса, по которому нужно отменить уведомления.
    func cancelNotifications(for flightNumber: String) {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let identifiers = requests
                .filter { $0.identifier.contains(flightNumber) }
                .map { $0.identifier }

            self?.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
            Logger.data("Отменено \(identifiers.count) уведомлений для \(flightNumber)")
        }
    }

    /// Удаляет все запланированные и доставленные уведомления приложения.
    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        Logger.data("Все уведомления удалены")
    }

    // MARK: - Настройка категорий

    /// Регистрирует категории уведомлений (вызывается при старте приложения).
    func registerCategories() {
        let flightStatusCategory = UNNotificationCategory(
            identifier: Constants.NotificationCategory.flightStatus,
            actions: [],
            intentIdentifiers: []
        )

        let departureCategory = UNNotificationCategory(
            identifier: Constants.NotificationCategory.departureReminder,
            actions: [],
            intentIdentifiers: []
        )

        notificationCenter.setNotificationCategories([flightStatusCategory, departureCategory])
    }
}
