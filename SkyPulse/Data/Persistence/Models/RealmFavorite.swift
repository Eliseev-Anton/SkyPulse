import Foundation
import RealmSwift

/// Realm-объект для хранения избранного рейса.
class RealmFavorite: Object {

    @Persisted(primaryKey: true) var flightId: String
    @Persisted var addedAt: Date
    @Persisted var notificationsEnabled: Bool
}
