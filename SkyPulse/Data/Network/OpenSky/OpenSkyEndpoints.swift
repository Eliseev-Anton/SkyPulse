import Foundation

/// Конструктор эндпоинтов OpenSky Network API (полностью бесплатный).
enum OpenSkyEndpoints {

    private static let baseURL = AppConfiguration.openSkyBaseURL

    /// Получить все state vectors (позиции самолётов)
    static func allStates(icao24: String? = nil) -> APIEndpoint {
        var query: [String: String] = [:]
        if let icao24 = icao24 {
            query["icao24"] = icao24
        }
        return APIEndpoint(baseURL: baseURL, path: "/states/all", queryParams: query)
    }

    /// Получить вылеты из аэропорта за период
    static func departures(airportIcao: String, begin: Int, end: Int) -> APIEndpoint {
        APIEndpoint(
            baseURL: baseURL,
            path: "/flights/departure",
            queryParams: [
                "airport": airportIcao,
                "begin": String(begin),
                "end": String(end)
            ]
        )
    }

    /// Получить прилёты в аэропорт за период
    static func arrivals(airportIcao: String, begin: Int, end: Int) -> APIEndpoint {
        APIEndpoint(
            baseURL: baseURL,
            path: "/flights/arrival",
            queryParams: [
                "airport": airportIcao,
                "begin": String(begin),
                "end": String(end)
            ]
        )
    }
}
