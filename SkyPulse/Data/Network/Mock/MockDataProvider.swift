import Foundation

/// Провайдер mock-данных из бандла приложения.
/// Используется при отсутствии сети, превышении лимита API и в UI-тестах.
final class MockDataProvider {

    static let shared = MockDataProvider()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Рейсы

    func loadFlights() -> [Flight] {
        guard let dtos: [MockFlightDTO] = loadJSON(from: "mock_flights") else { return [] }
        return dtos.compactMap { $0.toDomain() }
    }

    // MARK: - Аэропорты

    func loadAirports() -> [Airport] {
        loadJSON(from: "mock_airports") ?? []
    }

    // MARK: - Позиции

    func loadPositions() -> [FlightLiveData] {
        loadJSON(from: "mock_positions") ?? []
    }

    // MARK: - Загрузка JSON из бандла

    private func loadJSON<T: Decodable>(from filename: String) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            Logger.warning("Mock-файл \(filename).json не найден в бандле")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try decoder.decode(T.self, from: data)
            Logger.data("Загружен mock: \(filename).json")
            return decoded
        } catch {
            Logger.error("Ошибка декодирования \(filename).json", error: error)
            return nil
        }
    }
}

// MARK: - Mock DTO для маппинга JSON → Domain

/// Промежуточная структура для парсинга mock_flights.json
private struct MockFlightDTO: Decodable {
    let id: String
    let flightNumber: String
    let airline: Airline
    let departure: MockEndpointDTO
    let arrival: MockEndpointDTO
    let status: String
    let aircraft: MockAircraftDTO?
    let liveData: FlightLiveData?

    func toDomain() -> Flight {
        Flight(
            id: id,
            flightNumber: flightNumber,
            airline: airline,
            departure: departure.toDomain(),
            arrival: arrival.toDomain(),
            status: FlightStatus(apiString: status),
            aircraft: aircraft?.toDomain(),
            liveData: liveData
        )
    }
}

private struct MockEndpointDTO: Decodable {
    let airport: Airport
    let terminal: String?
    let gate: String?
    let scheduledTime: Date?
    let estimatedTime: Date?
    let actualTime: Date?
    let delay: Int?

    func toDomain() -> FlightEndpoint {
        FlightEndpoint(
            airport: airport,
            terminal: terminal,
            gate: gate,
            scheduledTime: scheduledTime,
            estimatedTime: estimatedTime,
            actualTime: actualTime,
            delay: delay
        )
    }
}

private struct MockAircraftDTO: Decodable {
    let registration: String?
    let icao24: String?
    let model: String?

    func toDomain() -> Aircraft {
        Aircraft(registration: registration, icao24: icao24, model: model)
    }
}
