import Foundation
import RxSwift
@testable import SkyPulse

/// Мок репозитория рейсов для unit тестов.
final class MockFlightRepository: FlightRepositoryProtocol {

    // MARK: - Настраиваемые ответы

    var stubbedFlights: [Flight] = []
    var stubbedFlight: Flight?
    var stubbedError: Error?
    var stubbedLiveData: FlightLiveData?

    // MARK: - Счётчики вызовов

    var fetchFlightsCallCount = 0
    var getFlightDetailCallCount = 0
    var getLivePositionCallCount = 0

    // MARK: - FlightRepositoryProtocol (callback)

    func fetchFlights(
        params: FlightSearchParams,
        completion: @escaping (Result<[Flight], Error>) -> Void
    ) {
        fetchFlightsCallCount += 1
        if let error = stubbedError {
            completion(.failure(error))
        } else {
            completion(.success(stubbedFlights))
        }
    }

    // MARK: - FlightRepositoryProtocol (async)

    func fetchFlightsAsync(params: FlightSearchParams) async throws -> [Flight] {
        fetchFlightsCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedFlights
    }

    // MARK: - FlightRepositoryProtocol (Rx)

    func observeFlights(params: FlightSearchParams) -> Observable<[Flight]> {
        fetchFlightsCallCount += 1
        if let error = stubbedError {
            return .error(error)
        }
        return .just(stubbedFlights)
    }

    func getFlightDetail(id: String) -> Observable<Flight> {
        getFlightDetailCallCount += 1
        if let error = stubbedError {
            return .error(error)
        }
        guard let flight = stubbedFlight else {
            return .error(NetworkError.noData)
        }
        return .just(flight)
    }

    func getLivePosition(icao24: String) -> Observable<FlightLiveData?> {
        getLivePositionCallCount += 1
        return .just(stubbedLiveData)
    }
}
