import Foundation
import Network
import RxSwift
import RxRelay

/// Протокол сервиса проверки доступности сети.
protocol ReachabilityServiceProtocol {
    /// Текущее состояние подключения.
    var isReachable: Bool { get }

    /// Реактивный поток состояния сети (`true` = онлайн, `false` = офлайн).
    var isReachableObservable: Observable<Bool> { get }
}

/// Обёртка над `NWPathMonitor` для отслеживания состояния сети.
///
/// Публикует изменения через RxSwift для реактивного использования.
final class ReachabilityService: ReachabilityServiceProtocol {

    /// Низкоуровневый монитор состояния сети.
    private let monitor = NWPathMonitor()

    /// Очередь, на которой выполняется мониторинг сети.
    private let monitorQueue = DispatchQueue(label: "com.skypulse.reachability", qos: .utility)

    /// Хранилище текущего состояния сети.
    private let reachabilityRelay = BehaviorRelay<Bool>(value: true)

    var isReachable: Bool {
        reachabilityRelay.value
    }

    var isReachableObservable: Observable<Bool> {
        reachabilityRelay
            .asObservable()
            .distinctUntilChanged()
    }

    init() {
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Private

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            self?.reachabilityRelay.accept(isConnected)

            if isConnected {
                Logger.network("Сеть доступна (\(path.availableInterfaces.map(\.type)))")
            } else {
                Logger.warning("Сеть недоступна")
            }
        }
        monitor.start(queue: monitorQueue)
    }
}
