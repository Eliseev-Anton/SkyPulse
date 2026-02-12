import Foundation
@testable import SkyPulse

/// Фабрика тестовых данных.
enum TestData {

    // MARK: - Аэропорты

    static let svo = Airport(
        icaoCode: "UUEE", iataCode: "SVO",
        name: "Sheremetyevo International Airport",
        city: "Moscow", country: "Russia",
        latitude: 55.9726, longitude: 37.4146,
        timezone: "Europe/Moscow"
    )

    static let jfk = Airport(
        icaoCode: "KJFK", iataCode: "JFK",
        name: "John F. Kennedy International Airport",
        city: "New York", country: "United States",
        latitude: 40.6413, longitude: -73.7781,
        timezone: "America/New_York"
    )

    static let lhr = Airport(
        icaoCode: "EGLL", iataCode: "LHR",
        name: "Heathrow Airport",
        city: "London", country: "United Kingdom",
        latitude: 51.4700, longitude: -0.4543,
        timezone: "Europe/London"
    )

    // MARK: - Авиакомпании

    static let aeroflot = Airline(
        iataCode: "SU", icaoCode: "AFL", name: "Aeroflot"
    )

    static let britishAirways = Airline(
        iataCode: "BA", icaoCode: "BAW", name: "British Airways"
    )

    // MARK: - Рейсы

    static func makeFlight(
        id: String = "SU1234-2026-02-10",
        flightNumber: String = "SU1234",
        airline: Airline = aeroflot,
        departure: Airport = svo,
        arrival: Airport = jfk,
        status: FlightStatus = .active,
        liveData: FlightLiveData? = nil
    ) -> Flight {
        Flight(
            id: id,
            flightNumber: flightNumber,
            airline: airline,
            departure: FlightEndpoint(
                airport: departure,
                terminal: "D",
                gate: "12",
                scheduledTime: Date(),
                estimatedTime: nil,
                actualTime: nil,
                delay: nil
            ),
            arrival: FlightEndpoint(
                airport: arrival,
                terminal: "1",
                gate: nil,
                scheduledTime: Date().addingTimeInterval(10 * 3600),
                estimatedTime: nil,
                actualTime: nil,
                delay: nil
            ),
            status: status,
            aircraft: Aircraft(registration: "VP-BKC", icao24: "abc123", model: "A321"),
            liveData: liveData
        )
    }

    static let activeFlight = makeFlight()

    static let landedFlight = makeFlight(
        id: "BA456-2026-02-10",
        flightNumber: "BA456",
        airline: britishAirways,
        departure: lhr,
        arrival: jfk,
        status: .landed
    )

    static let scheduledFlight = makeFlight(
        id: "SU5678-2026-02-10",
        flightNumber: "SU5678",
        status: .scheduled
    )

    // MARK: - Live Data

    static let sampleLiveData = FlightLiveData(
        latitude: 52.5,
        longitude: 13.4,
        altitude: 10668,
        speed: 850,
        heading: 270,
        verticalRate: 0,
        onGround: false,
        lastUpdate: Date()
    )
}
