import Foundation
import RealmSwift

/// Realm-объект для кэширования данных рейса.
/// Все вложенные структуры (Airport, Airline) хранятся в развёрнутом виде
/// для простоты запросов и отсутствия зависимости от вложенных объектов.
class RealmFlight: Object {

    @Persisted(primaryKey: true) var id: String           // "SU1234-2026-02-10"
    @Persisted var flightNumber: String
    @Persisted var status: String

    // Авиакомпания
    @Persisted var airlineIata: String
    @Persisted var airlineIcao: String
    @Persisted var airlineName: String

    // Вылет
    @Persisted var departureIata: String
    @Persisted var departureName: String
    @Persisted var departureCity: String
    @Persisted var departureCountry: String
    @Persisted var departureLat: Double
    @Persisted var departureLon: Double
    @Persisted var departureTimezone: String
    @Persisted var departureTerminal: String?
    @Persisted var departureGate: String?
    @Persisted var departureScheduled: Date?
    @Persisted var departureEstimated: Date?
    @Persisted var departureActual: Date?
    @Persisted var departureDelay: Int?

    // Прилёт
    @Persisted var arrivalIata: String
    @Persisted var arrivalName: String
    @Persisted var arrivalCity: String
    @Persisted var arrivalCountry: String
    @Persisted var arrivalLat: Double
    @Persisted var arrivalLon: Double
    @Persisted var arrivalTimezone: String
    @Persisted var arrivalTerminal: String?
    @Persisted var arrivalGate: String?
    @Persisted var arrivalScheduled: Date?
    @Persisted var arrivalEstimated: Date?
    @Persisted var arrivalActual: Date?
    @Persisted var arrivalDelay: Int?

    // Воздушное судно
    @Persisted var aircraftRegistration: String?
    @Persisted var aircraftIcao24: String?
    @Persisted var aircraftModel: String?

    // Мета
    @Persisted var cachedAt: Date
}
