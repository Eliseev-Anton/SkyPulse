import Foundation
import RealmSwift

/// Централизованный менеджер операций с Realm.
///
/// Обеспечивает единообразный доступ к кэшу рейсов, аэропортов, избранному
/// и истории поиска. Запись выполняется через `OperationQueue` для разгрузки main thread.
final class RealmManager {

    /// Синглтон‑экземпляр менеджера Realm.
    static let shared = RealmManager()

    /// Выделенная очередь для записи в Realm (демонстрация использования `OperationQueue`).
    private let writeQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.skypulse.realm.write"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    /// Экземпляр Realm, привязанный к текущему потоку.
    ///
    /// Realm нужно открывать отдельно на каждом потоке.
    private var realm: Realm {
        do {
            return try Realm()
        } catch {
            Logger.error("Не удалось открыть Realm", error: error)
            fatalError("Realm initialization failed: \(error)")
        }
    }

    // MARK: - Кэш рейсов
    /// Сохранить рейсы в кэш (выполняется в фоновой очереди)
    func cacheFlights(_ flights: [Flight]) {
        writeQueue.addOperation { [weak self] in
            guard let self = self else { return }
            let realmObjects = flights.map { FlightRealmMapper.toRealm($0) }
            autoreleasepool {
                do {
                    let bgRealm = try Realm()
                    try bgRealm.write {
                        bgRealm.add(realmObjects, update: .modified)
                    }
                    Logger.data("Закэшировано \(flights.count) рейсов")
                } catch {
                    Logger.error("Ошибка записи рейсов в Realm", error: error)
                }
            }
        }
    }

    /// Получить рейсы из кэша по параметрам поиска
    func getCachedFlights(params: FlightSearchParams) -> [Flight] {
        let results = realm.objects(RealmFlight.self)

        var filtered = results

        if let flightNumber = params.flightNumber {
            filtered = filtered.where { $0.flightNumber == flightNumber }
        }
        if let depIata = params.departureIata {
            filtered = filtered.where { $0.departureIata == depIata }
        }
        if let arrIata = params.arrivalIata {
            filtered = filtered.where { $0.arrivalIata == arrIata }
        }
        if let status = params.status {
            filtered = filtered.where { $0.status == status.rawValue }
        }

        return filtered
            .sorted(byKeyPath: "departureScheduled", ascending: true)
            .map { FlightRealmMapper.toDomain($0) }
    }

    /// Получить конкретный рейс из кэша
    func getCachedFlight(id: String) -> Flight? {
        guard let obj = realm.object(ofType: RealmFlight.self, forPrimaryKey: id) else { return nil }
        return FlightRealmMapper.toDomain(obj)
    }

    /// Очистить устаревший кэш
    func clearExpiredCache(olderThanHours hours: Int = 24) {
        writeQueue.addOperation {
            autoreleasepool {
                do {
                    let bgRealm = try Realm()
                    let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
                    let expired = bgRealm.objects(RealmFlight.self).where { $0.cachedAt < cutoff }
                    try bgRealm.write {
                        bgRealm.delete(expired)
                    }
                    Logger.data("Очищен устаревший кэш рейсов")
                } catch {
                    Logger.error("Ошибка очистки кэша", error: error)
                }
            }
        }
    }

    // MARK: - Избранное

    func addFavorite(flightId: String) {
        do {
            let fav = RealmFavorite()
            fav.flightId = flightId
            fav.addedAt = Date()
            fav.notificationsEnabled = true

            try realm.write {
                realm.add(fav, update: .modified)
            }
            Logger.data("Рейс \(flightId) добавлен в избранное")
        } catch {
            Logger.error("Ошибка добавления в избранное", error: error)
        }
    }

    func removeFavorite(flightId: String) {
        do {
            guard let fav = realm.object(ofType: RealmFavorite.self, forPrimaryKey: flightId) else { return }
            try realm.write {
                realm.delete(fav)
            }
            Logger.data("Рейс \(flightId) удалён из избранного")
        } catch {
            Logger.error("Ошибка удаления из избранного", error: error)
        }
    }

    func getAllFavorites() -> [RealmFavorite] {
        Array(realm.objects(RealmFavorite.self).sorted(byKeyPath: "addedAt", ascending: false))
    }

    func isFavorite(flightId: String) -> Bool {
        realm.object(ofType: RealmFavorite.self, forPrimaryKey: flightId) != nil
    }

    // MARK: - История поиска

    func saveSearch(_ query: SearchQuery) {
        do {
            let obj = RealmSearchHistory()
            obj.query = query.text
            obj.searchType = query.type.rawValue
            obj.timestamp = query.timestamp

            try realm.write {
                realm.add(obj)
            }

            // Ограничиваем размер истории
            trimSearchHistory()
        } catch {
            Logger.error("Ошибка сохранения поискового запроса", error: error)
        }
    }

    func getRecentSearches(limit: Int = 10) -> [SearchQuery] {
        realm.objects(RealmSearchHistory.self)
            .sorted(byKeyPath: "timestamp", ascending: false)
            .prefix(limit)
            .compactMap { obj -> SearchQuery? in
                guard let type = SearchQuery.SearchType(rawValue: obj.searchType) else { return nil }
                return SearchQuery(text: obj.query, type: type, timestamp: obj.timestamp)
            }
    }

    func clearSearchHistory() {
        do {
            let all = realm.objects(RealmSearchHistory.self)
            try realm.write {
                realm.delete(all)
            }
        } catch {
            Logger.error("Ошибка очистки истории поиска", error: error)
        }
    }

    // MARK: - Аэропорты

    func cacheAirports(_ airports: [Airport]) {
        writeQueue.addOperation {
            autoreleasepool {
                do {
                    let bgRealm = try Realm()
                    let objects = airports.map { AirportRealmMapper.toRealm($0) }
                    try bgRealm.write {
                        bgRealm.add(objects, update: .modified)
                    }
                } catch {
                    Logger.error("Ошибка кэширования аэропортов", error: error)
                }
            }
        }
    }

    func getCachedAirports(query: String) -> [Airport] {
        let results = realm.objects(RealmAirport.self)
            .where {
                $0.iataCode.contains(query, options: .caseInsensitive) ||
                $0.name.contains(query, options: .caseInsensitive) ||
                $0.city.contains(query, options: .caseInsensitive)
            }
        return results.map { AirportRealmMapper.toDomain($0) }
    }

    /// Полная очистка всех данных Realm
    func clearAll() {
        do {
            try realm.write {
                realm.deleteAll()
            }
            Logger.data("Все данные Realm очищены")
        } catch {
            Logger.error("Ошибка полной очистки Realm", error: error)
        }
    }

    // MARK: - Приватные методы

    private func trimSearchHistory() {
        let max = AppConfiguration.maxSearchHistoryEntries
        let all = realm.objects(RealmSearchHistory.self).sorted(byKeyPath: "timestamp", ascending: false)
        guard all.count > max else { return }

        do {
            let toDelete = all.suffix(from: max)
            try realm.write {
                realm.delete(toDelete)
            }
        } catch {
            Logger.error("Ошибка обрезки истории поиска", error: error)
        }
    }
}
