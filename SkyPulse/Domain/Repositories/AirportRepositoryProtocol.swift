import Foundation
import RxSwift

/// Контракт доступа к данным аэропортов и их расписаниям.
protocol AirportRepositoryProtocol {

    /// Получить список вылетов из аэропорта
    func fetchDepartures(airportCode: String) -> Observable<[Flight]>

    /// Получить список прилётов в аэропорт
    func fetchArrivals(airportCode: String) -> Observable<[Flight]>

    /// Поиск аэропортов по текстовому запросу (код или название)
    func searchAirports(query: String) -> Observable<[Airport]>

    /// Получить аэропорт по IATA-коду (из кэша или API)
    func getAirport(byIataCode code: String) async throws -> Airport
}
