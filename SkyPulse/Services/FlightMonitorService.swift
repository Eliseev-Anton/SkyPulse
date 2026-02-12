import Foundation
import RxSwift
import RxRelay

/// Сервис фонового мониторинга статуса рейсов.
///
/// Использует `OperationQueue` для периодического опроса API через `FlightRepository`,
/// публикует изменения статуса через Rx и отправляет локальные уведомления.
final class FlightMonitorService {

    /// Синглтон‑экземпляр сервиса мониторинга рейсов.
    static let shared = FlightMonitorService()

    /// Очередь для фоновых операций мониторинга.
    private let monitorQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.skypulse.flightmonitor"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .background
        return queue
    }()

    /// Таймер периодического опроса статуса рейсов.
    private var pollingTimer: Timer?

    /// Отслеживаемые рейсы, где ключ — `flightId`, значение — последний известный статус.
    private var monitoredFlights: [String: FlightStatus] = [:]
    private let monitoredFlightsLock = NSLock()

    /// Реле, публикующее события об изменении статуса рейса.
    private let statusChangeRelay = PublishRelay<(flightId: String, oldStatus: FlightStatus, newStatus: FlightStatus)>()

    /// Публичный поток изменений статуса рейсов.
    var statusChanges: Observable<(flightId: String, oldStatus: FlightStatus, newStatus: FlightStatus)> {
        statusChangeRelay.asObservable()
    }

    private let disposeBag = DisposeBag()

    /// Репозиторий рейсов, используемый для получения актуального статуса.
    private var flightRepository: FlightRepositoryProtocol?

    private init() {}

    // MARK: - Конфигурация

    /// Настраивает сервис зависимостью от репозитория рейсов.
    ///
    /// - Parameter flightRepository: Репозиторий, который будет использован
    ///   для получения актуальных данных о рейсах.
    func configure(flightRepository: FlightRepositoryProtocol) {
        self.flightRepository = flightRepository
    }

    // MARK: - Управление мониторингом

    /// Начинает мониторинг статуса конкретного рейса.
    ///
    /// - Parameters:
    ///   - flightId: Идентификатор рейса, который нужно отслеживать.
    ///   - currentStatus: Текущий известный статус рейса.
    func startMonitoring(flightId: String, currentStatus: FlightStatus) {
        monitoredFlightsLock.lock()
        monitoredFlights[flightId] = currentStatus
        monitoredFlightsLock.unlock()

        Logger.data("Мониторинг начат для рейса: \(flightId)")

        // Запускаем polling при добавлении первого рейса.
        if monitoredFlights.count == 1 {
            startPolling()
        }
    }

    /// Останавливает мониторинг конкретного рейса.
    ///
    /// - Parameter flightId: Идентификатор рейса, который больше не нужно отслеживать.
    func stopMonitoring(flightId: String) {
        monitoredFlightsLock.lock()
        monitoredFlights.removeValue(forKey: flightId)
        monitoredFlightsLock.unlock()

        Logger.data("Мониторинг остановлен для рейса: \(flightId)")

        // Останавливаем polling, если отслеживаемых рейсов больше нет.
        if monitoredFlights.isEmpty {
            stopPolling()
        }
    }

    /// Полностью останавливает мониторинг всех рейсов.
    func stopAll() {
        monitoredFlightsLock.lock()
        monitoredFlights.removeAll()
        monitoredFlightsLock.unlock()

        stopPolling()
        monitorQueue.cancelAllOperations()

        Logger.data("Весь мониторинг остановлен")
    }

    // MARK: - Polling

    /// Запускает периодический опрос статуса всех отслеживаемых рейсов.
    private func startPolling() {
        stopPolling()

        let interval = AppConfiguration.flightMonitorPollingInterval

        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.checkAllFlights()
        }

        // Сразу выполняем первую проверку, не дожидаясь срабатывания таймера.
        checkAllFlights()

        Logger.data("Polling запущен с интервалом \(interval)с")
    }

    /// Останавливает периодический опрос рейсов.
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Проверка рейсов

    /// Запускает проверки статуса для всех отслеживаемых рейсов.
    private func checkAllFlights() {
        monitoredFlightsLock.lock()
        let flightIds = Array(monitoredFlights.keys)
        monitoredFlightsLock.unlock()

        for flightId in flightIds {
            let operation = FlightCheckOperation(
                flightId: flightId,
                flightRepository: flightRepository
            ) { [weak self] flightId, newStatus in
                self?.handleStatusUpdate(flightId: flightId, newStatus: newStatus)
            }

            monitorQueue.addOperation(operation)
        }
    }

    /// Обрабатывает обновлённый статус рейса.
    ///
    /// - Parameters:
    ///   - flightId: Идентификатор рейса.
    ///   - newStatus: Новый статус, полученный от репозитория.
    private func handleStatusUpdate(flightId: String, newStatus: FlightStatus) {
        monitoredFlightsLock.lock()
        let oldStatus = monitoredFlights[flightId]
        monitoredFlights[flightId] = newStatus
        monitoredFlightsLock.unlock()

        guard let oldStatus = oldStatus, oldStatus != newStatus else { return }

        Logger.data("Статус рейса \(flightId) изменился: \(oldStatus.displayName) → \(newStatus.displayName)")

        // Отправляем событие
        statusChangeRelay.accept((flightId: flightId, oldStatus: oldStatus, newStatus: newStatus))

        // Отправляем локальное уведомление
        NotificationService.shared.scheduleFlightStatusNotification(
            flightNumber: flightId,
            status: newStatus,
            departureAirport: "",
            arrivalAirport: ""
        )
    }
}

// MARK: - FlightCheckOperation

/// Операция для проверки статуса конкретного рейса в фоне.
///
/// Использует реактивный API `FlightRepository` и `DispatchSemaphore`,
/// чтобы синхронно завершить операцию после получения результата.
private final class FlightCheckOperation: Operation {

    /// Идентификатор рейса, который необходимо проверить.
    private let flightId: String

    /// Репозиторий рейсов, из которого запрашивается актуальный статус.
    private let flightRepository: FlightRepositoryProtocol?

    /// Клоужер, вызываемый при успешном получении статуса.
    /// Параметры: `flightId` и обновлённый `FlightStatus`.
    private let completion: (String, FlightStatus) -> Void

    /// Создаёт операцию проверки статуса рейса.
    ///
    /// - Parameters:
    ///   - flightId: Идентификатор рейса.
    ///   - flightRepository: Репозиторий рейсов.
    ///   - completion: Клоужер, вызываемый при успешном обновлении статуса.
    init(
        flightId: String,
        flightRepository: FlightRepositoryProtocol?,
        completion: @escaping (String, FlightStatus) -> Void
    ) {
        self.flightId = flightId
        self.flightRepository = flightRepository
        self.completion = completion
    }

    override func main() {
        guard !isCancelled else { return }

        // Используем callback‑стиль для демонстрации @escaping + GCD.
        let semaphore = DispatchSemaphore(value: 0)

        flightRepository?.getFlightDetail(id: flightId)
            .take(1)
            .subscribe(onNext: { [weak self] flight in
                guard let self = self, !self.isCancelled else {
                    semaphore.signal()
                    return
                }
                self.completion(self.flightId, flight.status)
                semaphore.signal()
            }, onError: { error in
                Logger.error("Ошибка проверки рейса", error: error)
                semaphore.signal()
            })

        semaphore.wait()
    }
}
