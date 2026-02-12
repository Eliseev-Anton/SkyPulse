import Foundation

/// Протокол сетевого сервиса с async/await‑паттерном.
///
/// Представляет современный подход к concurrency в Swift 5.5+.
protocol AsyncNetworkServiceProtocol {
    /// Выполняет HTTP‑запрос и декодирует ответ в тип `T`.
    ///
    /// - Parameter endpoint: Описание API‑endpoint.
    /// - Returns: Декодированный объект `T`.
    /// - Throws: `NetworkError` при ошибках сети или декодирования.
    func request<T: Decodable>(endpoint: APIEndpoint) async throws -> T
}

/// Реализация сетевого сервиса с async/await.
///
/// Используется, например, в `AirportRepository` для демонстрации современного подхода.
final class AsyncNetworkService: AsyncNetworkServiceProtocol {

    /// Сессия URLSession, используемая для асинхронных запросов.
    private let session: URLSession

    /// JSON‑декодер с преднастроенными стратегиями.
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = DateFormatters.iso8601.date(from: dateString) {
                return date
            }
            if let date = DateFormatters.iso8601NoFraction.date(from: dateString) {
                return date
            }
            if let date = DateFormatters.apiDate.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Неподдерживаемый формат даты: \(dateString)")
            )
        }
    }

    func request<T: Decodable>(endpoint: APIEndpoint) async throws -> T {
        let urlRequest = try endpoint.urlRequest

        Logger.network("→ [async] \(endpoint.method.rawValue) \(urlRequest.url?.absoluteString ?? "")")

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "HTTPResponse", code: -1))
        }

        Logger.network("← [async] \(httpResponse.statusCode) \(urlRequest.url?.absoluteString ?? "")")

        if let httpError = NetworkError.fromHTTPStatus(httpResponse.statusCode) {
            throw httpError
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Logger.error("Ошибка декодирования \(T.self)", error: error)
            throw NetworkError.decodingError(error)
        }
    }
}
