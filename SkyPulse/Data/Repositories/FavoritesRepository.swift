import Foundation
import RxSwift

/// Реализация `FavoritesRepositoryProtocol`.
///
/// Работает полностью через `RealmManager`, без сетевых запросов:
/// хранит только идентификаторы избранных рейсов и при необходимости
/// подтягивает соответствующие объекты `Flight` из кэша.
final class FavoritesRepository: FavoritesRepositoryProtocol {

    /// Менеджер, отвечающий за операции чтения/записи в Realm.
    private let realmManager: RealmManager

    /// Репозиторий рейсов, используемый для дополнения избранных рейсов доменными моделями.
    private let flightRepository: FlightRepositoryProtocol

    /// Инициализирует репозиторий избранных рейсов.
    ///
    /// - Parameters:
    ///   - realmManager: Менеджер работы с Realm.
    ///   - flightRepository: Репозиторий рейсов.
    init(realmManager: RealmManager, flightRepository: FlightRepositoryProtocol) {
        self.realmManager = realmManager
        self.flightRepository = flightRepository
    }

    /// Возвращает список избранных рейсов.
    ///
    /// - Returns: Observable, испускающий массив `Flight`, собранный
    ///   на основании сохранённых в Realm избранных идентификаторов.
    func getFavorites() -> Observable<[Flight]> {
        Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            // Получаем все записи избранного и подгружаем соответствующие рейсы из кэша.
            let favorites = self.realmManager.getAllFavorites()
            let flights = favorites.compactMap { fav -> Flight? in
                self.realmManager.getCachedFlight(id: fav.flightId)
            }

            observer.onNext(flights)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    /// Добавляет рейс в избранное, сохраняя его и в кэше.
    ///
    /// - Parameter flight: Рейс, который нужно пометить как избранный.
    /// - Returns: `Completable`, завершающийся после успешной записи.
    func addFavorite(_ flight: Flight) -> Completable {
        Completable.create { [weak self] completable in
            self?.realmManager.cacheFlights([flight])
            self?.realmManager.addFavorite(flightId: flight.id)
            completable(.completed)
            return Disposables.create()
        }
    }

    /// Удаляет рейс из избранного.
    ///
    /// - Parameter flightId: Идентификатор рейса.
    /// - Returns: `Completable`, завершающийся после удаления.
    func removeFavorite(flightId: String) -> Completable {
        Completable.create { [weak self] completable in
            self?.realmManager.removeFavorite(flightId: flightId)
            completable(.completed)
            return Disposables.create()
        }
    }

    /// Проверяет, помечен ли рейс как избранный.
    ///
    /// - Parameter flightId: Идентификатор рейса.
    /// - Returns: Observable, испускающий `true`, если рейс в избранном.
    func isFavorite(flightId: String) -> Observable<Bool> {
        Observable.just(realmManager.isFavorite(flightId: flightId))
    }
}
