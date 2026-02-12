import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import SkyPulse

/// Тесты DashboardViewModel: загрузка, pull-to-refresh, ошибки, оффлайн-баннер.
final class DashboardViewModelTests: XCTestCase {

    private var viewModel: DashboardViewModel!
    private var mockRepository: MockFlightRepository!
    private var mockReachability: MockReachabilityService!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockRepository = MockFlightRepository()
        mockReachability = MockReachabilityService()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        let fetchFlightsUseCase = FetchFlightsUseCase(flightRepository: mockRepository)
        viewModel = DashboardViewModel(
            fetchFlightsUseCase: fetchFlightsUseCase,
            reachability: mockReachability
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockReachability = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - Тесты

    /// Проверяем, что рейсы загружаются при viewDidLoad
    func testFlightsLoadedOnViewDidLoad() {
        let flights = [TestData.activeFlight, TestData.landedFlight]
        mockRepository.stubbedFlights = flights

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let input = DashboardViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            pullToRefresh: .never(),
            flightSelected: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver([Flight].self)
        output.flights
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(observer.events.last?.value.element?.count, 2)
        XCTAssertEqual(mockRepository.fetchFlightsCallCount, 1)
    }

    /// Проверяем pull-to-refresh
    func testPullToRefreshReloadsFlights() {
        mockRepository.stubbedFlights = [TestData.activeFlight]

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let pullToRefresh = scheduler.createHotObservable([.next(300, ())])

        let input = DashboardViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            pullToRefresh: pullToRefresh.asObservable(),
            flightSelected: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver([Flight].self)
        output.flights
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        // viewDidLoad + pullToRefresh = 2 вызова
        XCTAssertEqual(mockRepository.fetchFlightsCallCount, 2)
    }

    /// Проверяем обработку ошибки
    func testErrorMessageOnFailure() {
        mockRepository.stubbedError = NetworkError.noData

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let input = DashboardViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            pullToRefresh: .never(),
            flightSelected: .never()
        )

        let output = viewModel.transform(input: input)

        let errorObserver = scheduler.createObserver(String?.self)
        output.errorMessage
            .drive(errorObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        // Должно быть сообщение об ошибке
        let lastError = errorObserver.events.last?.value.element as? String
        XCTAssertNotNil(lastError)
    }

    /// Проверяем оффлайн-баннер при отключении сети
    func testOfflineBannerShownWhenNetworkUnavailable() {
        mockRepository.stubbedFlights = []
        mockReachability.setReachable(false)

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let input = DashboardViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            pullToRefresh: .never(),
            flightSelected: .never()
        )

        let output = viewModel.transform(input: input)

        let offlineObserver = scheduler.createObserver(Bool.self)
        output.isOffline
            .drive(offlineObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertTrue(offlineObserver.events.contains { $0.value.element == true })
    }

    /// Проверяем, что isLoading переключается
    func testLoadingState() {
        mockRepository.stubbedFlights = [TestData.activeFlight]

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let input = DashboardViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            pullToRefresh: .never(),
            flightSelected: .never()
        )

        let output = viewModel.transform(input: input)

        let loadingObserver = scheduler.createObserver(Bool.self)
        output.isLoading
            .drive(loadingObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        // Loading должен быть false в конце
        XCTAssertEqual(loadingObserver.events.last?.value.element, false)
    }
}
