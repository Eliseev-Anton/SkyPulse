import Foundation
import RxSwift

/// Use case для поиска рейсов с сохранением истории запросов.
///
/// Формирует параметры поиска на основе введённого пользователем текста и типа запроса
/// и сохраняет запрос в историю через `RealmManager`.
final class SearchFlightsUseCase {

    /// Репозиторий, выполняющий фактический поиск рейсов.
    private let flightRepository: FlightRepositoryProtocol

    /// Менеджер базы Realm, используемый для сохранения истории поиска.
    private let realmManager: RealmManager

    /// Инициализирует use case с зависимостями.
    ///
    /// - Parameters:
    ///   - flightRepository: Репозиторий, отвечающий за поиск рейсов.
    ///   - realmManager: Менеджер базы данных для сохранения истории запросов.
    init(flightRepository: FlightRepositoryProtocol, realmManager: RealmManager) {
        self.flightRepository = flightRepository
        self.realmManager = realmManager
    }

    /// Выполняет поиск рейсов по указанному запросу и типу.
    ///
    /// - Parameter query: Объект `SearchQuery`, содержащий текст и тип поиска.
    /// - Returns: Observable, испускающий массив найденных рейсов.
    func execute(query: SearchQuery) -> Observable<[Flight]> {
        // Сохраняем текущий поисковый запрос в историю.
        realmManager.saveSearch(query)

        // Параметры, которые будут переданы в репозиторий для получения рейсов.
        let params: FlightSearchParams

        switch query.type {
        case .flightNumber:
            // Поиск по номеру рейса.
            params = .byFlightNumber(query.text)
        case .route:
            // Ожидаем формат "FROM-TO" (например, "SVO-JFK").
            let parts = query.text.split(separator: "-").map(String.init)
            guard parts.count == 2 else { return .just([]) }
            params = .byRoute(from: parts[0], to: parts[1])
        case .airport:
            // Поиск по аэропорту вылета с текущей датой.
            params = FlightSearchParams(
                flightNumber: nil, departureIata: query.text,
                arrivalIata: nil, airlineIata: nil,
                flightDate: Date(), status: nil
            )
        }

        // Делегируем наблюдение за списком рейсов репозиторию.
        return flightRepository.observeFlights(params: params)
    }
}
