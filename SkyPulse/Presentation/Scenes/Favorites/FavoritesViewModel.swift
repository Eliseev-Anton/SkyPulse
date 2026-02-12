import Foundation
import RxSwift
import RxCocoa
import RxFlow
import RxRelay

/// ViewModel экрана избранных рейсов с поддержкой удаления.
///
/// Отвечает за загрузку списка избранных рейсов, удаление через swipe‑to‑delete
/// и навигацию на экран деталей рейса.
final class FavoritesViewModel: ViewModelType, Stepper {

    /// Поток шагов навигации (переход на детали рейса).
    let steps = PublishRelay<Step>()

    struct Input {
        /// Событие появления экрана.
        let viewDidLoad: Observable<Void>
        /// Событие выбора рейса из списка.
        let flightSelected: Observable<Flight>
        /// Событие удаления рейса (swipe‑to‑delete).
        let deleteTriggered: Observable<Flight>
    }

    struct Output {
        /// Текущий список избранных рейсов.
        let favorites: Driver<[Flight]>
        /// Флаг пустого списка избранного.
        let isEmpty: Driver<Bool>
    }

    /// Use case для управления избранными рейсами.
    private let manageFavoritesUseCase: ManageFavoritesUseCase
    private let disposeBag = DisposeBag()

    /// Создаёт ViewModel для экрана избранных рейсов.
    ///
    /// - Parameter manageFavoritesUseCase: Use case, инкапсулирующий работу с избранным.
    init(manageFavoritesUseCase: ManageFavoritesUseCase) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
    }

    /// Связывает входные события с выходными потоками и навигацией.
    ///
    /// - Parameter input: Структура входных событий.
    /// - Returns: Структура `Output` с данными для UI.
    func transform(input: Input) -> Output {
        // Триггеры для перезагрузки: при появлении экрана и после удаления.
        let reloadTrigger = Observable.merge(
            input.viewDidLoad,
            input.deleteTriggered.mapToVoid()
        )

        // Список избранных: перезагружается при появлении экрана или после удаления.
        let favorites = reloadTrigger
            .flatMapLatest { [weak self] _ -> Observable<[Flight]> in
                guard let self = self else { return .just([]) }
                return self.manageFavoritesUseCase.getFavorites()
            }
            .share(replay: 1)

        // Удаление из избранного (flight всегда является избранным в этом контексте).
        input.deleteTriggered
            .flatMapLatest { [weak self] flight -> Observable<Bool> in
                guard let self = self else { return .just(false) }
                return self.manageFavoritesUseCase.toggleFavorite(flight: flight, isFavorited: true)
            }
            .subscribe()
            .disposed(by: disposeBag)

        // Навигация: выбор рейса → детали.
        input.flightSelected
            .subscribe(onNext: { [weak self] flight in
                self?.steps.accept(MainStep.flightDetailIsRequired(
                    flightId: flight.id,
                    icao24: flight.aircraft?.icao24
                ))
            })
            .disposed(by: disposeBag)

        let isEmpty = favorites.map { $0.isEmpty }.asDriver(onErrorJustReturn: true)

        return Output(
            favorites: favorites.asDriver(onErrorJustReturn: []),
            isEmpty: isEmpty
        )
    }
}
