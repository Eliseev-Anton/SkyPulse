import Foundation
import RxSwift

/// Контракт доступа к данным о рейсах.
/// Реализация координирует API, кэш и mock-данные.
protocol FlightRepositoryProtocol {

    // MARK: - Callback-паттерн (legacy)

    /// Получить список рейсов через completion handler
    func fetchFlights(
        params: FlightSearchParams,
        completion: @escaping (Result<[Flight], NetworkError>) -> Void
    )

    // MARK: - Async/await-паттерн (современный)

    /// Получить список рейсов через async/await
    func fetchFlights(params: FlightSearchParams) async throws -> [Flight]

    // MARK: - Реактивный паттерн (Rx)

    /// Наблюдать за списком рейсов
    func observeFlights(params: FlightSearchParams) -> Observable<[Flight]>

    /// Получить детальную информацию о конкретном рейсе
    func getFlightDetail(id: String) -> Observable<Flight>

    /// Получить live-позицию самолёта по ICAO24-адресу
    func getLivePosition(icao24: String) -> Observable<FlightLiveData?>
}
