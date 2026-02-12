import Foundation
import RxSwift

/// Получение табло вылетов/прилётов для конкретного аэропорта.
final class FetchAirportBoardUseCase {

    private let airportRepository: AirportRepositoryProtocol

    init(airportRepository: AirportRepositoryProtocol) {
        self.airportRepository = airportRepository
    }

    func fetchDepartures(airportCode: String) -> Observable<[Flight]> {
        airportRepository.fetchDepartures(airportCode: airportCode)
    }

    func fetchArrivals(airportCode: String) -> Observable<[Flight]> {
        airportRepository.fetchArrivals(airportCode: airportCode)
    }

    func searchAirports(query: String) -> Observable<[Airport]> {
        airportRepository.searchAirports(query: query)
    }
}
