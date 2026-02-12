import Foundation
import RxSwift
import RxCocoa
import RxFlow
import RxRelay

/// ViewModel главного экрана — отслеживаемые рейсы, статус сети и навигация.
///
/// Реализует протокол `ViewModelType` и `Stepper`, формирует выходные потоки
/// для таблицы рейсов, состояний загрузки, ошибок и офлайн‑баннера.
final class DashboardViewModel: ViewModelType, Stepper {

    /// Поток шагов навигации, публикуемых ViewModel.
    let steps = PublishRelay<Step>()

    struct Input {
        /// Событие первого появления экрана.
        let viewDidLoad: Observable<Void>
        /// Событие жеста pull‑to‑refresh.
        let pullToRefresh: Observable<Void>
        /// Событие выбора рейса пользователем.
        let flightSelected: Observable<Flight>
    }

    struct Output {
        /// Поток рейсов для отображения в таблице.
        let flights: Driver<[Flight]>
        /// Флаг загрузки данных (биндится к `UIRefreshControl`).
        let isLoading: Driver<Bool>
        /// Текст сообщения об ошибке (опционально).
        let errorMessage: Driver<String?>
        /// Флаг офлайн‑режима (`true`, когда сети нет).
        let isOffline: Driver<Bool>
    }

    /// Use case для получения списка рейсов для дашборда.
    private let fetchFlightsUseCase: FetchFlightsUseCase

    /// Сервис доступности сети.
    private let reachability: ReachabilityServiceProtocol
    private let disposeBag = DisposeBag()

    /// Создаёт ViewModel для экрана Dashboard.
    ///
    /// - Parameters:
    ///   - fetchFlightsUseCase: Use case для загрузки рейсов.
    ///   - reachability: Сервис, предоставляющий информацию о сети.
    init(fetchFlightsUseCase: FetchFlightsUseCase, reachability: ReachabilityServiceProtocol) {
        self.fetchFlightsUseCase = fetchFlightsUseCase
        self.reachability = reachability
    }

    /// Преобразует входные события экрана в выходные потоки для биндинга в VC.
    ///
    /// - Parameter input: Структура с входными событиями.
    /// - Returns: Структура `Output` с потоками данных для UI.
    func transform(input: Input) -> Output {
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = BehaviorRelay<String?>(value: nil)

        // Загрузка рейсов по событиям `viewDidLoad` и `pullToRefresh`.
        let flights = Observable.merge(input.viewDidLoad, input.pullToRefresh)
            .do(onNext: {
                isLoading.accept(true)
                errorMessage.accept(nil)
            })
            .flatMapLatest { [weak self] _ -> Observable<[Flight]> in
                guard let self = self else { return .just([]) }
                return self.fetchFlightsUseCase.execute(params: .dashboard)
                    .catch { error in
                        errorMessage.accept(error.localizedDescription)
                        return .just([])
                    }
            }
            .do(onNext: { _ in isLoading.accept(false) })
            .share(replay: 1)

        // Навигация: выбор рейса → переход на экран деталей
        input.flightSelected
            .subscribe(onNext: { [weak self] flight in
                self?.steps.accept(MainStep.flightDetailIsRequired(
                    flightId: flight.id,
                    icao24: flight.aircraft?.icao24
                ))
            })
            .disposed(by: disposeBag)

        let isOffline = reachability.isReachableObservable.map { !$0 }

        return Output(
            flights: flights.asDriver(onErrorJustReturn: []),
            isLoading: isLoading.asDriver(),
            errorMessage: errorMessage.asDriver(),
            isOffline: isOffline.asDriver(onErrorJustReturn: false)
        )
    }
}
