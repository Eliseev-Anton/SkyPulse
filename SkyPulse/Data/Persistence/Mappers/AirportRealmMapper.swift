import Foundation

/// Двунаправленный маппинг между доменной моделью `Airport` и Realm‑объектом `RealmAirport`.
enum AirportRealmMapper {

    /// Конвертирует `RealmAirport` в доменную модель `Airport`.
    ///
    /// - Parameter realm: Объект Realm для аэропорта.
    /// - Returns: Доменная модель `Airport`.
    static func toDomain(_ realm: RealmAirport) -> Airport {
        Airport(
            icaoCode: realm.icaoCode,
            iataCode: realm.iataCode,
            name: realm.name,
            city: realm.city,
            country: realm.country,
            latitude: realm.latitude,
            longitude: realm.longitude,
            timezone: realm.timezone
        )
    }

    /// Конвертирует доменную модель `Airport` в `RealmAirport` для сохранения в БД.
    ///
    /// - Parameter airport: Доменная модель аэропорта.
    /// - Returns: Новый объект `RealmAirport`.
    static func toRealm(_ airport: Airport) -> RealmAirport {
        let obj = RealmAirport()
        obj.iataCode = airport.iataCode
        obj.icaoCode = airport.icaoCode
        obj.name = airport.name
        obj.city = airport.city
        obj.country = airport.country
        obj.latitude = airport.latitude
        obj.longitude = airport.longitude
        obj.timezone = airport.timezone
        obj.cachedAt = Date()
        return obj
    }
}
