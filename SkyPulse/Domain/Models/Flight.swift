import Foundation

/// Основная модель рейса, объединяющая данные из AviationStack и OpenSky.
struct Flight: Equatable, Hashable {
    let id: String                    // уникальный идентификатор: "AA1234-2026-02-10"
    let flightNumber: String          // например, "AA1234"
    let airline: Airline
    let departure: FlightEndpoint
    let arrival: FlightEndpoint
    let status: FlightStatus
    let aircraft: Aircraft?
    let liveData: FlightLiveData?     // позиция в реальном времени (OpenSky)

    /// Оставшееся время до вылета (nil если уже вылетел или нет данных)
    var minutesUntilDeparture: Int? {
        guard let scheduled = departure.scheduledTime else { return nil }
        let interval = scheduled.timeIntervalSinceNow
        guard interval > 0 else { return nil }
        return Int(interval / 60)
    }

    /// Прогресс полёта от 0.0 до 1.0 (для отображения на карточке маршрута)
    var flightProgress: Double {
        guard status == .active,
              let depTime = departure.actualTime ?? departure.scheduledTime,
              let arrTime = arrival.estimatedTime ?? arrival.scheduledTime else {
            switch status {
            case .landed:    return 1.0
            case .active:    return 0.5
            default:         return 0.0
            }
        }

        let totalDuration = arrTime.timeIntervalSince(depTime)
        guard totalDuration > 0 else { return 0.0 }

        let elapsed = Date().timeIntervalSince(depTime)
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }
}

// MARK: - Вложенные типы

/// Точка маршрута (вылет или прилёт) с данными о времени и терминале.
struct FlightEndpoint: Equatable, Hashable {
    let airport: Airport
    let terminal: String?
    let gate: String?
    let scheduledTime: Date?
    let estimatedTime: Date?
    let actualTime: Date?
    let delay: Int?               // задержка в минутах

    /// Наиболее актуальное время: фактическое → расчётное → плановое
    var bestAvailableTime: Date? {
        actualTime ?? estimatedTime ?? scheduledTime
    }

    /// Строка задержки для UI: "+25 min" или nil
    var delayDisplayString: String? {
        guard let delay = delay, delay > 0 else { return nil }
        return "+\(delay) min"
    }
}

/// Информация о воздушном судне.
struct Aircraft: Equatable, Hashable {
    let registration: String?     // например, "VP-BKC"
    let icao24: String?           // ICAO 24-bit адрес для OpenSky
    let model: String?            // например, "A321"
}

// MARK: - Параметры поиска

/// Параметры запроса рейсов к API.
struct FlightSearchParams: Equatable {
    let flightNumber: String?
    let departureIata: String?
    let arrivalIata: String?
    let airlineIata: String?
    let flightDate: Date?
    let status: FlightStatus?

    /// Запрос для главного экрана — активные рейсы
    static let dashboard = FlightSearchParams(
        flightNumber: nil,
        departureIata: nil,
        arrivalIata: nil,
        airlineIata: nil,
        flightDate: Date(),
        status: .active
    )

    /// Запрос по номеру рейса
    static func byFlightNumber(_ number: String) -> FlightSearchParams {
        FlightSearchParams(
            flightNumber: number,
            departureIata: nil,
            arrivalIata: nil,
            airlineIata: nil,
            flightDate: nil,
            status: nil
        )
    }

    /// Запрос по маршруту
    static func byRoute(from: String, to: String) -> FlightSearchParams {
        FlightSearchParams(
            flightNumber: nil,
            departureIata: from,
            arrivalIata: to,
            airlineIata: nil,
            flightDate: Date(),
            status: nil
        )
    }
}

// MARK: - Identifiable

extension Flight: Identifiable {}
