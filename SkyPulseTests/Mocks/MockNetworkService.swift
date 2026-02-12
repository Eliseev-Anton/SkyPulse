import Foundation
@testable import SkyPulse

/// Мок сетевого сервиса для unit тестов.
final class MockNetworkService {

    var stubbedData: Data?
    var stubbedError: NetworkError?
    var requestCallCount = 0
    var lastEndpoint: APIEndpoint?

    /// Имитация сетевого запроса с callback
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        requestCallCount += 1
        lastEndpoint = endpoint

        if let error = stubbedError {
            completion(.failure(error))
            return
        }

        guard let data = stubbedData else {
            completion(.failure(.noData))
            return
        }

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            completion(.success(decoded))
        } catch {
            completion(.failure(.decodingError(error)))
        }
    }
}
