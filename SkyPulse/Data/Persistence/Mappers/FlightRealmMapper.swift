import Foundation

/// Двунаправленный маппинг между доменной моделью `Flight` и Realm‑объектом `RealmFlight`.
enum FlightRealmMapper {

    // MARK: - Realm → Domain

    /// Конвертирует `RealmFlight` в доменную модель `Flight`.
    ///
    /// - Parameter realm: Объект Realm, представляющий рейс.
    /// - Returns: Доменная модель `Flight`, готовая для использования в UI и бизнес‑логике.
    static func toDomain(_ realm: RealmFlight) -> Flight {
        let departure = FlightEndpoint(
            airport: Airport(
                icaoCode: "", iataCode: realm.departureIata,
                name: realm.departureName, city: realm.departureCity,
                country: realm.departureCountry,
                latitude: realm.departureLat, longitude: realm.departureLon,
                timezone: realm.departureTimezone
            ),
            terminal: realm.departureTerminal,
            gate: realm.departureGate,
            scheduledTime: realm.departureScheduled,
            estimatedTime: realm.departureEstimated,
            actualTime: realm.departureActual,
            delay: realm.departureDelay
        )

        let arrival = FlightEndpoint(
            airport: Airport(
                icaoCode: "", iataCode: realm.arrivalIata,
                name: realm.arrivalName, city: realm.arrivalCity,
                country: realm.arrivalCountry,
                latitude: realm.arrivalLat, longitude: realm.arrivalLon,
                timezone: realm.arrivalTimezone
            ),
            terminal: realm.arrivalTerminal,
            gate: realm.arrivalGate,
            scheduledTime: realm.arrivalScheduled,
            estimatedTime: realm.arrivalEstimated,
            actualTime: realm.arrivalActual,
            delay: realm.arrivalDelay
        )

        let aircraft: Aircraft? = {
            guard realm.aircraftIcao24 != nil || realm.aircraftRegistration != nil else { return nil }
            return Aircraft(
                registration: realm.aircraftRegistration,
                icao24: realm.aircraftIcao24,
                model: realm.aircraftModel
            )
        }()

        return Flight(
            id: realm.id,
            flightNumber: realm.flightNumber,
            airline: Airline(
                iataCode: realm.airlineIata,
                icaoCode: realm.airlineIcao,
                name: realm.airlineName
            ),
            departure: departure,
            arrival: arrival,
            status: FlightStatus(apiString: realm.status),
            aircraft: aircraft,
            liveData: nil   // live-данные не кэшируются — актуальны только в моменте
        )
    }

    // MARK: - Domain → Realm

    /// Конвертирует доменную модель `Flight` в `RealmFlight` для сохранения в БД.
    ///
    /// - Parameter flight: Доменная модель рейса.
    /// - Returns: Заполненный объект `RealmFlight`.
    static func toRealm(_ flight: Flight) -> RealmFlight {
        let obj = RealmFlight()
        obj.id = flight.id
        obj.flightNumber = flight.flightNumber
        obj.status = flight.status.rawValue

        obj.airlineIata = flight.airline.iataCode
        obj.airlineIcao = flight.airline.icaoCode
        obj.airlineName = flight.airline.name

        obj.departureIata = flight.departure.airport.iataCode
        obj.departureName = flight.departure.airport.name
        obj.departureCity = flight.departure.airport.city
        obj.departureCountry = flight.departure.airport.country
        obj.departureLat = flight.departure.airport.latitude
        obj.departureLon = flight.departure.airport.longitude
        obj.departureTimezone = flight.departure.airport.timezone
        obj.departureTerminal = flight.departure.terminal
        obj.departureGate = flight.departure.gate
        obj.departureScheduled = flight.departure.scheduledTime
        obj.departureEstimated = flight.departure.estimatedTime
        obj.departureActual = flight.departure.actualTime
        obj.departureDelay = flight.departure.delay

        obj.arrivalIata = flight.arrival.airport.iataCode
        obj.arrivalName = flight.arrival.airport.name
        obj.arrivalCity = flight.arrival.airport.city
        obj.arrivalCountry = flight.arrival.airport.country
        obj.arrivalLat = flight.arrival.airport.latitude
        obj.arrivalLon = flight.arrival.airport.longitude
        obj.arrivalTimezone = flight.arrival.airport.timezone
        obj.arrivalTerminal = flight.arrival.terminal
        obj.arrivalGate = flight.arrival.gate
        obj.arrivalScheduled = flight.arrival.scheduledTime
        obj.arrivalEstimated = flight.arrival.estimatedTime
        obj.arrivalActual = flight.arrival.actualTime
        obj.arrivalDelay = flight.arrival.delay

        obj.aircraftRegistration = flight.aircraft?.registration
        obj.aircraftIcao24 = flight.aircraft?.icao24
        obj.aircraftModel = flight.aircraft?.model

        obj.cachedAt = Date()
        return obj
    }
}
