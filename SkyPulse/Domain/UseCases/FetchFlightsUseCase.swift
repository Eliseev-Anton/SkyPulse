import Foundation
import RxSwift

/// Use case для получения списка рейсов.
///
/// Делегирует фактическую загрузку и наблюдение за данными `FlightRepositoryProtocol`.
/// При необходимости может учитывать состояние сети через `ReachabilityServiceProtocol`.
final class FetchFlightsUseCase {

    /// Репозиторий, предоставляющий доступ к данным рейсов.
    private let flightRepository: FlightRepositoryProtocol

    /// Сервис, позволяющий определить доступность сети (для выбора источника данных).
    private let reachability: ReachabilityServiceProtocol

    /// Инициализирует use case с зависимостями.
    ///
    /// - Parameters:
    ///   - flightRepository: Репозиторий, отвечающий за загрузку и кэширование рейсов.
    ///   - reachability: Сервис проверки сетевой доступности.
    init(flightRepository: FlightRepositoryProtocol, reachability: ReachabilityServiceProtocol) {
        self.flightRepository = flightRepository
        self.reachability = reachability
    }

    /// Наблюдает список рейсов по заданным параметрам поиска.
    ///
    /// - Parameter params: Параметры поиска рейсов (`FlightSearchParams`).
    /// - Returns: Observable, испускающий актуальный массив рейсов при обновлении данных.
    func execute(params: FlightSearchParams) -> Observable<[Flight]> {
        // На текущий момент просто делегируем запрос репозиторию.
        // При необходимости здесь можно добавить логику выбора источника (онлайн/кэш).
        flightRepository.observeFlights(params: params)
    }
}
