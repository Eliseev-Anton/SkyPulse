import Foundation
import RxSwift

/// Контракт управления избранными рейсами (хранение в Realm).
protocol FavoritesRepositoryProtocol {

    /// Наблюдать за списком избранных рейсов
    func getFavorites() -> Observable<[Flight]>

    /// Добавить рейс в избранное
    func addFavorite(_ flight: Flight) -> Completable

    /// Удалить рейс из избранного
    func removeFavorite(flightId: String) -> Completable

    /// Проверить, добавлен ли рейс в избранное (реактивно)
    func isFavorite(flightId: String) -> Observable<Bool>
}
