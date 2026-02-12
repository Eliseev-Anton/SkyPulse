import Foundation

/// Фасад для работы с OpenSky Network API (async/await).
/// OpenSky — полностью бесплатный API без ключа авторизации.
final class OpenSkyAPI {

    private let asyncService: AsyncNetworkServiceProtocol

    init(asyncService: AsyncNetworkServiceProtocol) {
        self.asyncService = asyncService
    }

    /// Получить текущую позицию самолёта по ICAO24-адресу
    func fetchLiveState(icao24: String) async throws -> FlightLiveData? {
        let endpoint = OpenSkyEndpoints.allStates(icao24: icao24)
        let response: OSStateVectorResponse = try await asyncService.request(endpoint: endpoint)

        guard let states = response.states, let first = states.first else {
            return nil
        }

        return OSStateVector(from: first)?.toDomain()
    }

    /// Получить все видимые самолёты (для карты)
    func fetchAllStates() async throws -> [FlightLiveData] {
        let endpoint = OpenSkyEndpoints.allStates()
        let response: OSStateVectorResponse = try await asyncService.request(endpoint: endpoint)

        return response.states?
            .compactMap { OSStateVector(from: $0)?.toDomain() }
            ?? []
    }
}
