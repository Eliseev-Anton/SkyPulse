import Foundation
import RxSwift

/// Use case для управления списком избранных рейсов.
///
/// Инкапсулирует операции добавления, удаления, проверки и получения избранных рейсов
/// поверх `FavoritesRepositoryProtocol`.
final class ManageFavoritesUseCase {

    /// Репозиторий, предоставляющий доступ к данным избранных рейсов.
    private let favoritesRepository: FavoritesRepositoryProtocol

    /// Инициализирует use case с конкретной реализацией репозитория.
    ///
    /// - Parameter favoritesRepository: Репозиторий, отвечающий за чтение и
    ///   запись избранных рейсов в хранилище.
    init(favoritesRepository: FavoritesRepositoryProtocol) {
        self.favoritesRepository = favoritesRepository
    }

    /// Получает текущий список избранных рейсов.
    ///
    /// - Returns: Observable, испускающий массив `Flight` при каждом изменении.
    func getFavorites() -> Observable<[Flight]> {
        favoritesRepository.getFavorites()
    }

    /// Переключает состояние «избранное» для конкретного рейса.
    ///
    /// - Parameters:
    ///   - flight: Рейс, для которого нужно изменить состояние избранного.
    ///   - isFavorited: Текущее состояние флага «в избранном».
    /// - Returns: Observable, испускающий новое состояние `isFavorited`
    ///   (`true`, если рейс стал избранным, `false` — если был удалён).
    func toggleFavorite(flight: Flight, isFavorited: Bool) -> Observable<Bool> {
        if isFavorited {
            // Если рейс уже в избранном — удаляем его и возвращаем `false`.
            return favoritesRepository.removeFavorite(flightId: flight.id)
                .andThen(.just(false))
        } else {
            // Если рейса нет в избранном — добавляем и возвращаем `true`.
            return favoritesRepository.addFavorite(flight)
                .andThen(.just(true))
        }
    }

    /// Проверяет, находится ли рейс в списке избранных.
    ///
    /// - Parameter flightId: Уникальный идентификатор рейса.
    /// - Returns: Observable, испускающий `true`, если рейс в избранном, иначе `false`.
    func isFavorite(flightId: String) -> Observable<Bool> {
        favoritesRepository.isFavorite(flightId: flightId)
    }
}
