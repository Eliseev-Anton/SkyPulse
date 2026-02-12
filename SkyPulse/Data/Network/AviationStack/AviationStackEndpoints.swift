import Foundation

/// Конструктор эндпоинтов для AviationStack API.
enum AviationStackEndpoints {

    private static let baseURL = AppConfiguration.aviationStackBaseURL

    /// Поиск рейсов с фильтрацией
    static func flights(params: FlightSearchParams, apiKey: String) -> APIEndpoint {
        var query: [String: String] = ["access_key": apiKey]

        if let number = params.flightNumber {
            query["flight_iata"] = number
        }
        if let dep = params.departureIata {
            query["dep_iata"] = dep
        }
        if let arr = params.arrivalIata {
            query["arr_iata"] = arr
        }
        if let airline = params.airlineIata {
            query["airline_iata"] = airline
        }
        if let status = params.status {
            query["flight_status"] = status.rawValue
        }

        return APIEndpoint(baseURL: baseURL, path: "/flights", queryParams: query)
    }

    /// Поиск аэропортов
    static func airports(search: String, apiKey: String) -> APIEndpoint {
        APIEndpoint(
            baseURL: baseURL,
            path: "/airports",
            queryParams: [
                "access_key": apiKey,
                "search": search
            ]
        )
    }
}
