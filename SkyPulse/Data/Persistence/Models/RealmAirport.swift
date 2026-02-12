import Foundation
import RealmSwift

/// Realm-объект для кэширования данных аэропорта.
class RealmAirport: Object {

    @Persisted(primaryKey: true) var iataCode: String
    @Persisted var icaoCode: String
    @Persisted var name: String
    @Persisted var city: String
    @Persisted var country: String
    @Persisted var latitude: Double
    @Persisted var longitude: Double
    @Persisted var timezone: String
    @Persisted var cachedAt: Date
}
