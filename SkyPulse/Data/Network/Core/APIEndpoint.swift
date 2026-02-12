import Foundation

/// Описание API-эндпоинта для построения URLRequest.
/// Инкапсулирует все параметры запроса в одном месте.
struct APIEndpoint {
    let baseURL: String
    let path: String
    let method: HTTPMethod
    let queryParams: [String: String]
    let headers: [String: String]

    init(
        baseURL: String,
        path: String,
        method: HTTPMethod = .get,
        queryParams: [String: String] = [:],
        headers: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.queryParams = queryParams
        self.headers = headers
    }

    /// Собирает URLRequest из параметров эндпоинта
    var urlRequest: URLRequest {
        get throws {
            guard var components = URLComponents(string: baseURL + path) else {
                throw NetworkError.invalidURL
            }

            if !queryParams.isEmpty {
                components.queryItems = queryParams.map {
                    URLQueryItem(name: $0.key, value: $0.value)
                }
            }

            guard let url = components.url else {
                throw NetworkError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.timeoutInterval = AppConfiguration.networkTimeoutInterval

            // Стандартные заголовки
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            // Пользовательские заголовки
            headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }

            return request
        }
    }
}
