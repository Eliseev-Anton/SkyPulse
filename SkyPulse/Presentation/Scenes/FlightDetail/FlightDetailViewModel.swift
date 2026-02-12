import Foundation
import RxSwift
import RxCocoa
import RxFlow
import RxRelay

/// ViewModel экрана деталей рейса: информация, live‑позиция и избранное.
///
/// Отвечает за загрузку детальной информации о рейсе (включая live‑данные),
/// управление статусом избранного и навигацию на карту.
final class FlightDetailViewModel: ViewModelType, Stepper {

    /// Поток шагов навигации (открытие карты и т.п.).
    let steps = PublishRelay<Step>()

    struct Input {
        /// Сигнал первого появления экрана.
        let viewDidLoad: Observable<Void>
        /// Тап по кнопке избранного.
        let toggleFavorite: Observable<Void>
        /// Тап по кнопке «Показать на карте».
        let showOnMap: Observable<Void>
        /// Триггер обновления по pull‑to‑refresh.
        let refreshTrigger: Observable<Void>
    }

    struct Output {
        /// Детальная информация о рейсе (включая live‑данные).
        let flight: Driver<Flight?>
        /// Флаг, показывающий, что рейс в избранном.
        let isFavorite: Driver<Bool>
        /// Флаг загрузки (биндится к `UIRefreshControl`).
        let isLoading: Driver<Bool>
        /// Текст ошибки, если загрузка рейса завершилась неудачно.
        let errorMessage: Driver<String?>
    }

    /// Идентификатор рейса, детали которого нужно загрузить.
    private let flightId: String

    /// ICAO24‑идентификатор самолёта (для запроса live‑позиции).
    private let icao24: String?

    /// Use case для получения деталей рейса и live‑данных.
    private let trackFlightUseCase: TrackFlightUseCase

    /// Use case для управления избранными рейсами.
    private let manageFavoritesUseCase: ManageFavoritesUseCase
    private let disposeBag = DisposeBag()

    /// Создаёт ViewModel экрана деталей рейса.
    ///
    /// - Parameters:
    ///   - flightId: Идентификатор рейса.
    ///   - icao24: ICAO24‑идентификатор самолёта (опционально).
    ///   - trackFlightUseCase: Use case для загрузки деталей рейса.
    ///   - manageFavoritesUseCase: Use case для управления избранным.
    init(
        flightId: String,
        icao24: String?,
        trackFlightUseCase: TrackFlightUseCase,
        manageFavoritesUseCase: ManageFavoritesUseCase
    ) {
        self.flightId = flightId
        self.icao24 = icao24
        self.trackFlightUseCase = trackFlightUseCase
        self.manageFavoritesUseCase = manageFavoritesUseCase
    }

    /// Преобразует входные события в выходные потоки данных и навигации.
    ///
    /// - Parameter input: Структура с событиями экрана.
    /// - Returns: Структура `Output` с данными для биндинга в контроллере.
    func transform(input: Input) -> Output {
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = BehaviorRelay<String?>(value: nil)
        let flightRelay = BehaviorRelay<Flight?>(value: nil)

        // Загрузка данных рейса.
        let loadTrigger = Observable.merge(input.viewDidLoad, input.refreshTrigger)

        loadTrigger
            .do(onNext: {
                isLoading.accept(true)
                errorMessage.accept(nil)
            })
            .flatMapLatest { [weak self] _ -> Observable<Flight> in
                guard let self = self else { return .empty() }
                return self.trackFlightUseCase.execute(
                    flightId: self.flightId,
                    icao24: self.icao24
                )
                .catch { error in
                    errorMessage.accept(error.localizedDescription)
                    return .empty()
                }
            }
            .do(onNext: { _ in isLoading.accept(false) })
            .bind(to: flightRelay)
            .disposed(by: disposeBag)

        // Статус избранного — реактивный relay, обновляется после каждого toggle.
        let isFavoriteRelay = BehaviorRelay<Bool>(value: false)

        manageFavoritesUseCase.isFavorite(flightId: flightId)
            .take(1)
            .bind(to: isFavoriteRelay)
            .disposed(by: disposeBag)

        // Переключение избранного — используем текущее состояние relay как источник правды.
        input.toggleFavorite
            .withLatestFrom(Observable.combineLatest(
                flightRelay.asObservable(),
                isFavoriteRelay.asObservable()
            ))
            .compactMap { (flight, isFav) -> (Flight, Bool)? in
                guard let flight else { return nil }
                return (flight, isFav)
            }
            .flatMapLatest { [weak self] (flight, isFav) -> Observable<Bool> in
                guard let self else { return .just(isFav) }
                return self.manageFavoritesUseCase.toggleFavorite(flight: flight, isFavorited: isFav)
            }
            .bind(to: isFavoriteRelay)
            .disposed(by: disposeBag)

        let isFavorite = isFavoriteRelay.asDriver()

        // Показать на карте.
        input.showOnMap
            .withLatestFrom(flightRelay)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] flight in
                self?.steps.accept(MainStep.mapIsRequired(flights: [flight]))
            })
            .disposed(by: disposeBag)

        return Output(
            flight: flightRelay.asDriver(),
            isFavorite: isFavorite,
            isLoading: isLoading.asDriver(),
            errorMessage: errorMessage.asDriver()
        )
    }
}
