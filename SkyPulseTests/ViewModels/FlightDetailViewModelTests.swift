import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import SkyPulse

/// Тесты FlightDetailViewModel: загрузка деталей, избранное, обновление.
final class FlightDetailViewModelTests: XCTestCase {

    private var viewModel: FlightDetailViewModel!
    private var mockRepository: MockFlightRepository!
    private var mockFavoritesRepository: MockFavoritesRepository!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockRepository = MockFlightRepository()
        mockFavoritesRepository = MockFavoritesRepository()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        let trackUseCase = TrackFlightUseCase(flightRepository: mockRepository)
        let favoritesUseCase = ManageFavoritesUseCase(favoritesRepository: mockFavoritesRepository)

        viewModel = FlightDetailViewModel(
            flightId: TestData.activeFlight.id,
            icao24: "abc123",
            trackFlightUseCase: trackUseCase,
            manageFavoritesUseCase: favoritesUseCase
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockFavoritesRepository = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - Тесты

    /// Проверяем загрузку данных рейса при viewDidLoad
    func testFlightLoadedOnViewDidLoad() {
        mockRepository.stubbedFlight = TestData.activeFlight
        mockRepository.stubbedLiveData = TestData.sampleLiveData

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let input = FlightDetailViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            toggleFavorite: .never(),
            showOnMap: .never(),
            refreshTrigger: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver(Flight?.self)
        output.flight
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(mockRepository.getFlightDetailCallCount, 1)
        XCTAssertEqual(mockRepository.getLivePositionCallCount, 1)
    }

    /// Проверяем переключение избранного
    func testToggleFavoriteAddsToFavorites() {
        mockRepository.stubbedFlight = TestData.activeFlight

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let toggleFavorite = scheduler.createHotObservable([.next(300, ())])

        let input = FlightDetailViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            toggleFavorite: toggleFavorite.asObservable(),
            showOnMap: .never(),
            refreshTrigger: .never()
        )

        let output = viewModel.transform(input: input)

        let favObserver = scheduler.createObserver(Bool.self)
        output.isFavorite
            .drive(favObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(mockFavoritesRepository.addFavoriteCallCount, 1)
    }

    /// Проверяем обработку ошибки при загрузке
    func testErrorOnFlightLoadFailure() {
        mockRepository.stubbedError = NetworkError.noData

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let input = FlightDetailViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            toggleFavorite: .never(),
            showOnMap: .never(),
            refreshTrigger: .never()
        )

        let output = viewModel.transform(input: input)

        let errorObserver = scheduler.createObserver(String?.self)
        output.errorMessage
            .drive(errorObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        let lastError = errorObserver.events.last?.value.element as? String
        XCTAssertNotNil(lastError)
    }

    /// Проверяем pull-to-refresh
    func testRefreshReloadsFlightData() {
        mockRepository.stubbedFlight = TestData.activeFlight

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let refresh = scheduler.createHotObservable([.next(300, ())])

        let input = FlightDetailViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            toggleFavorite: .never(),
            showOnMap: .never(),
            refreshTrigger: refresh.asObservable()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver(Flight?.self)
        output.flight
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        // viewDidLoad + refresh = 2 вызова
        XCTAssertEqual(mockRepository.getFlightDetailCallCount, 2)
    }
}
