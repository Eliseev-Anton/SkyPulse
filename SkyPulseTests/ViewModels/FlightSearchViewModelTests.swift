import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import SkyPulse

/// Тесты FlightSearchViewModel: поиск, история, очистка.
final class FlightSearchViewModelTests: XCTestCase {

    private var viewModel: FlightSearchViewModel!
    private var mockRepository: MockFlightRepository!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockRepository = MockFlightRepository()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        let searchUseCase = SearchFlightsUseCase(
            flightRepository: mockRepository,
            realmManager: .shared
        )
        viewModel = FlightSearchViewModel(
            searchFlightsUseCase: searchUseCase,
            realmManager: .shared
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - Тесты

    /// Проверяем выполнение поиска по нажатию кнопки
    func testSearchTriggeredOnButtonTap() {
        mockRepository.stubbedFlights = [TestData.activeFlight]

        let searchText = scheduler.createHotObservable([.next(200, "SU1234")])
        let searchTrigger = scheduler.createHotObservable([.next(300, ())])

        let input = FlightSearchViewModel.Input(
            searchText: searchText.asObservable(),
            searchTrigger: searchTrigger.asObservable(),
            cancelTrigger: .never(),
            flightSelected: .never(),
            historySelected: .never(),
            clearHistory: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver([Flight].self)
        output.flights
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(mockRepository.fetchFlightsCallCount, 1)
    }

    /// Проверяем, что пустой текст не вызывает поиск
    func testEmptySearchTextDoesNotTriggerSearch() {
        let searchText = scheduler.createHotObservable([.next(200, "")])
        let searchTrigger = scheduler.createHotObservable([.next(300, ())])

        let input = FlightSearchViewModel.Input(
            searchText: searchText.asObservable(),
            searchTrigger: searchTrigger.asObservable(),
            cancelTrigger: .never(),
            flightSelected: .never(),
            historySelected: .never(),
            clearHistory: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver([Flight].self)
        output.flights
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(mockRepository.fetchFlightsCallCount, 0)
    }

    /// Проверяем видимость истории при пустом поле
    func testHistoryVisibleWhenSearchEmpty() {
        let searchText = scheduler.createHotObservable([.next(200, "")])

        let input = FlightSearchViewModel.Input(
            searchText: searchText.asObservable(),
            searchTrigger: .never(),
            cancelTrigger: .never(),
            flightSelected: .never(),
            historySelected: .never(),
            clearHistory: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver(Bool.self)
        output.isHistoryVisible
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertTrue(observer.events.contains { $0.value.element == true })
    }

    /// Проверяем, что история скрывается при вводе текста
    func testHistoryHiddenWhenSearchHasText() {
        let searchText = scheduler.createHotObservable([.next(200, "SU")])

        let input = FlightSearchViewModel.Input(
            searchText: searchText.asObservable(),
            searchTrigger: .never(),
            cancelTrigger: .never(),
            flightSelected: .never(),
            historySelected: .never(),
            clearHistory: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver(Bool.self)
        output.isHistoryVisible
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertTrue(observer.events.contains { $0.value.element == false })
    }
}
