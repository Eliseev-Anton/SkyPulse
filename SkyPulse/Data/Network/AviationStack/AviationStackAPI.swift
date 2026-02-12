import Foundation

/// Фасад для работы с AviationStack API.
/// Предоставляет оба стиля: callback (@escaping) и async/await.
final class AviationStackAPI {

    private let networkService: NetworkServiceProtocol
    private let asyncService: AsyncNetworkServiceProtocol
    private let apiKey: String

    init(
        networkService: NetworkServiceProtocol,
        asyncService: AsyncNetworkServiceProtocol,
        apiKey: String
    ) {
        self.networkService = networkService
        self.asyncService = asyncService
        self.apiKey = apiKey
    }

    // MARK: - Callback-паттерн

    /// Получить рейсы через completion handler
    func fetchFlights(
        params: FlightSearchParams,
        completion: @escaping (Result<[ASFlightDTO], NetworkError>) -> Void
    ) {
        let endpoint = AviationStackEndpoints.flights(params: params, apiKey: apiKey)
        networkService.request(endpoint: endpoint) { (result: Result<ASFlightResponse, NetworkError>) in
            switch result {
            case .success(let response):
                if let apiError = response.error {
                    let networkError: NetworkError
                    switch apiError.code {
                    case 101, 102: networkError = .unauthorized
                    case 104:      networkError = .rateLimited
                    default:       networkError = .serverError(statusCode: apiError.code ?? -1)
                    }
                    completion(.failure(networkError))
                } else {
                    completion(.success(response.data ?? []))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Async/await-паттерн

    /// Поиск аэропортов через async/await
    func fetchAirports(query: String) async throws -> [ASAirportDTO] {
        let endpoint = AviationStackEndpoints.airports(search: query, apiKey: apiKey)
        let response: ASAirportResponse = try await asyncService.request(endpoint: endpoint)
        if let apiError = response.error {
            let networkError: NetworkError
            switch apiError.code {
            case 101, 102: networkError = .unauthorized
            case 104:      networkError = .rateLimited
            default:       networkError = .serverError(statusCode: apiError.code ?? -1)
            }
            throw networkError
        }
        return response.data ?? []
    }
}
