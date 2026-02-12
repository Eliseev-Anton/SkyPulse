import Foundation
import RxSwift

/// Use case для отслеживания конкретного рейса.
///
/// Комбинирует детальную информацию о рейсе из `AviationStack` с live‑позицией
/// из `OpenSky` (если доступен ICAO24‑идентификатор), возвращая объединённый `Flight`.
final class TrackFlightUseCase {

    /// Репозиторий, предоставляющий детали рейса и live‑позицию.
    private let flightRepository: FlightRepositoryProtocol

    /// Инициализирует use case конкретной реализацией репозитория рейсов.
    ///
    /// - Parameter flightRepository: Репозиторий, через который запрашиваются данные рейса.
    init(flightRepository: FlightRepositoryProtocol) {
        self.flightRepository = flightRepository
    }

    /// Получает детали рейса и при наличии ICAO24 дополняет их live‑телеметрией.
    ///
    /// - Parameters:
    ///   - flightId: Уникальный идентификатор рейса в локальном хранилище.
    ///   - icao24: ICAO24‑адрес самолёта для запроса live‑позиции (опционально).
    /// - Returns: Observable с объектом `Flight`, дополненным live‑данными, если они доступны.
    func execute(flightId: String, icao24: String?) -> Observable<Flight> {
        let detail = flightRepository.getFlightDetail(id: flightId)

        guard let icao24 = icao24 else {
            // Без ICAO24 — применяем расчётную позицию как fallback
            return detail.map { Self.applyFallback($0) }
        }

        let livePosition = flightRepository.getLivePosition(icao24: icao24.lowercased())

        return Observable.combineLatest(detail, livePosition) { flight, liveData in
            // Приоритет: OpenSky → AviationStack live → расчётная позиция
            let resolved = liveData ?? flight.liveData ?? Self.estimatedPosition(for: flight)
            guard resolved != flight.liveData else { return flight }
            return Self.replacing(flight, liveData: resolved)
        }
    }

    // MARK: - Private helpers

    private static func applyFallback(_ flight: Flight) -> Flight {
        guard flight.liveData == nil, let estimated = estimatedPosition(for: flight) else {
            return flight
        }
        return replacing(flight, liveData: estimated)
    }

    private static func replacing(_ flight: Flight, liveData: FlightLiveData?) -> Flight {
        Flight(
            id: flight.id,
            flightNumber: flight.flightNumber,
            airline: flight.airline,
            departure: flight.departure,
            arrival: flight.arrival,
            status: flight.status,
            aircraft: flight.aircraft,
            liveData: liveData
        )
    }

    /// Расчётная позиция самолёта на основе координат аэропортов и прогресса полёта.
    /// Используется только для активных рейсов когда ни AviationStack, ни OpenSky
    /// не вернули live-данные.
    private static func estimatedPosition(for flight: Flight) -> FlightLiveData? {
        guard flight.status == .active else { return nil }

        let depLat = flight.departure.airport.latitude
        let depLon = flight.departure.airport.longitude
        let arrLat = flight.arrival.airport.latitude
        let arrLon = flight.arrival.airport.longitude

        guard abs(depLat) > 0.001 || abs(depLon) > 0.001,
              abs(arrLat) > 0.001 || abs(arrLon) > 0.001 else { return nil }

        let p = flight.flightProgress
        let lat = depLat + (arrLat - depLat) * p
        let lon = depLon + (arrLon - depLon) * p

        // Курс (bearing) между аэропортами
        let dLon = (arrLon - depLon) * .pi / 180
        let φ1 = depLat * .pi / 180
        let φ2 = arrLat * .pi / 180
        let y = sin(dLon) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(dLon)
        let heading = (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)

        return FlightLiveData(
            latitude: lat,
            longitude: lon,
            altitude: 10668,  // ~35 000 ft — типичная крейсерская высота
            speed: 230,       // ~450 kts
            heading: heading,
            verticalRate: 0,
            isOnGround: false,
            lastUpdated: Date()
        )
    }
}
