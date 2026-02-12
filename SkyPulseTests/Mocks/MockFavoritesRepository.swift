import Foundation
import RxSwift
import RxRelay
@testable import SkyPulse

/// Мок репозитория избранного для unit тестов.
final class MockFavoritesRepository: FavoritesRepositoryProtocol {

    // MARK: - Хранилище

    private var favorites: [Flight] = []
    private let favoritesRelay = BehaviorRelay<[Flight]>(value: [])

    // MARK: - Счётчики

    var addFavoriteCallCount = 0
    var removeFavoriteCallCount = 0

    // MARK: - FavoritesRepositoryProtocol

    func getFavorites() -> Observable<[Flight]> {
        favoritesRelay.asObservable()
    }

    func addFavorite(_ flight: Flight) -> Completable {
        addFavoriteCallCount += 1
        favorites.append(flight)
        favoritesRelay.accept(favorites)
        return .empty()
    }

    func removeFavorite(flightId: String) -> Completable {
        removeFavoriteCallCount += 1
        favorites.removeAll { $0.id == flightId }
        favoritesRelay.accept(favorites)
        return .empty()
    }

    func isFavorite(flightId: String) -> Observable<Bool> {
        favoritesRelay.map { flights in
            flights.contains { $0.id == flightId }
        }
    }
}
