import Foundation
import RealmSwift

/// Realm-объект для хранения истории поисковых запросов.
class RealmSearchHistory: Object {

    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var query: String
    @Persisted var searchType: String       // rawValue из SearchQuery.SearchType
    @Persisted var timestamp: Date
}
