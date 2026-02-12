import Foundation

/// DTO для ответа AviationStack API /airports
struct ASAirportResponse: Decodable {
    let pagination: ASPagination?
    let data: [ASAirportDTO]?
    let error: ASAPIError?
}

struct ASAirportDTO: Decodable {
    let airportName: String?
    let iataCode: String?
    let icaoCode: String?
    let latitude: String?
    let longitude: String?
    let geoname_id: String?
    let timezone: String?
    let gmt: String?
    let countryName: String?
    let cityIataCode: String?
    let countryIso2: String?

    /// Маппинг в доменную модель Airport
    func toDomain() -> Airport? {
        guard let iata = iataCode, !iata.isEmpty else { return nil }
        return Airport(
            icaoCode: icaoCode ?? "",
            iataCode: iata,
            name: airportName ?? "",
            city: cityIataCode ?? "",
            country: countryName ?? "",
            latitude: Double(latitude ?? "0") ?? 0,
            longitude: Double(longitude ?? "0") ?? 0,
            timezone: timezone ?? "UTC"
        )
    }
}
