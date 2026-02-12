import Foundation

/// Ошибки сетевого слоя с поддержкой LocalizedError для отображения в UI.
enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case decodingError(Error)
    case invalidURL
    case rateLimited
    case unauthorized
    case notFound
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Нет подключения к интернету"
        case .timeout:
            return "Превышено время ожидания ответа"
        case .serverError(let code):
            return "Ошибка сервера (код \(code))"
        case .decodingError:
            return "Ошибка обработки данных"
        case .invalidURL:
            return "Некорректный URL запроса"
        case .rateLimited:
            return "Превышен лимит запросов API"
        case .unauthorized:
            return "Ошибка авторизации API"
        case .notFound:
            return "Данные не найдены"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    /// Преобразование HTTP status code в типизированную ошибку
    static func fromHTTPStatus(_ code: Int) -> NetworkError? {
        switch code {
        case 200...299: return nil
        case 401:       return .unauthorized
        case 404:       return .notFound
        case 429:       return .rateLimited
        default:        return .serverError(statusCode: code)
        }
    }
}
