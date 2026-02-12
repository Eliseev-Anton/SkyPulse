import Foundation

/// Протокол сетевого сервиса с callback‑паттерном (`@escaping`).
///
/// Демонстрирует классический подход к асинхронному networking в iOS до появления async/await.
protocol NetworkServiceProtocol {
    /// Выполняет HTTP‑запрос к указанному endpoint и возвращает результат через completion.
    ///
    /// - Parameters:
    ///   - endpoint: Описание API‑endpoint (URL, метод, параметры).
    ///   - completion: Клоужер с результатом: успешно декодированный объект `T`
    ///     или ошибка `NetworkError`.
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        completion: @escaping (Result<T, NetworkError>) -> Void
    )
}

/// Реализация сетевого сервиса на основе `URLSession` с callback‑паттерном.
///
/// Парсинг JSON выполняется на фоновом потоке через GCD, результат
/// возвращается на main queue для удобной работы с UI.
final class NetworkService: NetworkServiceProtocol {

    /// Сессия URLSession, используемая для выполнения запросов.
    private let session: URLSession

    /// JSON‑декодер с преднастроенными стратегиями для ключей и дат.
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Пробуем разные форматы дат из API
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

    func request<T: Decodable>(
        endpoint: APIEndpoint,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.urlRequest
        } catch {
            completion(.failure(.invalidURL))
            return
        }

        Logger.network("→ \(endpoint.method.rawValue) \(urlRequest.url?.absoluteString ?? "")")

        let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            // Обработка сетевой ошибки
            if let error = error {
                let nsError = error as NSError
                let networkError: NetworkError = nsError.code == NSURLErrorTimedOut
                    ? .timeout
                    : nsError.code == NSURLErrorNotConnectedToInternet
                        ? .noConnection
                        : .unknown(error)

                Logger.error("Сетевая ошибка: \(networkError)", error: error)
                DispatchQueue.main.async { completion(.failure(networkError)) }
                return
            }

            // Проверка HTTP-статуса
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(.unknown(NSError()))) }
                return
            }

            Logger.network("← \(httpResponse.statusCode) \(urlRequest.url?.absoluteString ?? "")")

            if let httpError = NetworkError.fromHTTPStatus(httpResponse.statusCode) {
                DispatchQueue.main.async { completion(.failure(httpError)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(.decodingError(NSError()))) }
                return
            }

            // Парсинг на фоновом потоке для разгрузки main queue
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let decoded = try self.decoder.decode(T.self, from: data)
                    DispatchQueue.main.async { completion(.success(decoded)) }
                } catch {
                    Logger.error("Ошибка декодирования \(T.self)", error: error)
                    DispatchQueue.main.async { completion(.failure(.decodingError(error))) }
                }
            }
        }

        task.resume()
    }
}
