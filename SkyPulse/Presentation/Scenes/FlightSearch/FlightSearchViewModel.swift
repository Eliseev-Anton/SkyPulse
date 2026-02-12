import Foundation
import RxSwift
import RxCocoa
import RxFlow
import RxRelay

/// ViewModel экрана поиска рейсов с историей запросов.
///
/// Обрабатывает ввод в поисковую строку, формирует `SearchQuery`,
/// сохраняет историю запросов в Realm и управляет навигацией к деталям рейса.
final class FlightSearchViewModel: ViewModelType, Stepper {

    /// Поток шагов навигации (переход к результату поиска).
    let steps = PublishRelay<Step>()

    struct Input {
        /// Текст поиска из `UISearchBar`.
        let searchText: Observable<String>
        /// Триггер нажатия кнопки «Поиск» на клавиатуре.
        let searchTrigger: Observable<Void>
        /// Триггер нажатия кнопки «Отмена».
        let cancelTrigger: Observable<Void>
        /// Событие выбора рейса из результатов поиска.
        let flightSelected: Observable<Flight>
        /// Событие выбора элемента из истории поиска.
        let historySelected: Observable<SearchQuery>
        /// Событие очистки истории запросов.
        let clearHistory: Observable<Void>
    }

    struct Output {
        /// Результаты поиска рейсов.
        let flights: Driver<[Flight]>
        /// История поисковых запросов.
        let searchHistory: Driver<[SearchQuery]>
        /// Флаг активности поиска (используется для показа LoadingView).
        let isLoading: Driver<Bool>
        /// Текст ошибки, если поиск завершился неудачно.
        let errorMessage: Driver<String?>
        /// Флаг видимости блока истории (true = показывать историю вместо результатов).
        let isHistoryVisible: Driver<Bool>
    }

    /// Use case для поиска рейсов по запросу.
    private let searchFlightsUseCase: SearchFlightsUseCase

    /// Менеджер Realm для чтения/очистки истории поиска.
    private let realmManager: RealmManager
    private let disposeBag = DisposeBag()

    /// Создаёт ViewModel для экрана поиска рейсов.
    ///
    /// - Parameters:
    ///   - searchFlightsUseCase: Use case для поиска рейсов.
    ///   - realmManager: Менеджер базы данных для истории запросов.
    init(searchFlightsUseCase: SearchFlightsUseCase, realmManager: RealmManager) {
        self.searchFlightsUseCase = searchFlightsUseCase
        self.realmManager = realmManager
    }

    /// Преобразует входные события в выходные потоки для биндинга в контроллере.
    ///
    /// - Parameter input: Структура входных событий.
    /// - Returns: Структура `Output` с данными для UI.
    func transform(input: Input) -> Output {
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = BehaviorRelay<String?>(value: nil)
        let currentSearchText = BehaviorRelay<String>(value: "")

        // Сохраняем текущий текст для отслеживания.
        input.searchText
            .bind(to: currentSearchText)
            .disposed(by: disposeBag)

        // Поиск по нажатию кнопки, по вводу текста (с debounce) или выбору из истории.
        let searchFromButton = input.searchTrigger
            .withLatestFrom(currentSearchText)
            .filter { !$0.isEmpty }
            .map { SearchQuery.detect(from: $0) }

        let searchFromText = input.searchText
            .debounce(.milliseconds(800), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .filter { $0.count >= 3 }
            .map { SearchQuery.detect(from: $0) }

        let searchFromHistory = input.historySelected.asObservable()

        let searchQuery = Observable.merge(searchFromButton, searchFromText, searchFromHistory)

        // Выполнение поиска.
        let flights = searchQuery
            .do(onNext: { _ in
                isLoading.accept(true)
                errorMessage.accept(nil)
            })
            .flatMapLatest { [weak self] query -> Observable<[Flight]> in
                guard let self = self else { return .just([]) }
                return self.searchFlightsUseCase.execute(query: query)
                    .catch { error in
                        errorMessage.accept(error.localizedDescription)
                        return .just([])
                    }
            }
            .do(onNext: { _ in isLoading.accept(false) })
            .share(replay: 1)

        // История поиска из Realm (обновляется при изменении текста и после очистки).
        let historyReload = PublishRelay<Void>()

        let searchHistory = Observable.merge(
                currentSearchText.mapToVoid(),
                historyReload.asObservable()
            )
            .map { [weak self] _ -> [SearchQuery] in
                self?.realmManager.getRecentSearches() ?? []
            }
            .asDriver(onErrorJustReturn: [])

        // Очистка истории.
        input.clearHistory
            .subscribe(onNext: { [weak self] in
                self?.realmManager.clearSearchHistory()
                historyReload.accept(())
            })
            .disposed(by: disposeBag)

        // Навигация: выбор рейса → детали.
        input.flightSelected
            .subscribe(onNext: { [weak self] flight in
                self?.steps.accept(SearchStep.resultSelected(
                    flightId: flight.id,
                    icao24: flight.aircraft?.icao24
                ))
            })
            .disposed(by: disposeBag)

        // Показать историю, когда поле пустое и нет результатов.
        let isHistoryVisible = currentSearchText
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)

        return Output(
            flights: flights.asDriver(onErrorJustReturn: []),
            searchHistory: searchHistory,
            isLoading: isLoading.asDriver(),
            errorMessage: errorMessage.asDriver(),
            isHistoryVisible: isHistoryVisible
        )
    }
}
