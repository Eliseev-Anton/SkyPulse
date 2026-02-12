import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import SkyPulse

/// Тесты AirportBoardViewModel: загрузка табло, переключение типа.
final class AirportBoardViewModelTests: XCTestCase {

    private var viewModel: AirportBoardViewModel!
    private var mockRepository: MockFlightRepository!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockRepository = MockFlightRepository()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        // Для AirportBoardViewModel нужен AirportRepositoryProtocol
        // Используем mock через FetchAirportBoardUseCase
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - Тесты

    /// Проверяем начальный тип табло — вылеты
    func testDefaultBoardTypeIsDepartures() {
        let useCase = FetchAirportBoardUseCase(airportRepository: MockAirportRepository())
        viewModel = AirportBoardViewModel(
            airportCode: "SVO",
            fetchAirportBoardUseCase: useCase
        )

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let input = AirportBoardViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            segmentChanged: .never(),
            flightSelected: .never(),
            refreshTrigger: .never()
        )

        let output = viewModel.transform(input: input)

        let typeObserver = scheduler.createObserver(AirportBoardView.BoardType.self)
        output.boardType
            .drive(typeObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(typeObserver.events.first?.value.element, .departures)
    }

    /// Проверяем переключение на прилёты
    func testSwitchToArrivals() {
        let useCase = FetchAirportBoardUseCase(airportRepository: MockAirportRepository())
        viewModel = AirportBoardViewModel(
            airportCode: "SVO",
            fetchAirportBoardUseCase: useCase
        )

        let viewDidLoad = scheduler.createHotObservable([.next(210, ())])
        let segmentChanged = scheduler.createHotObservable([.next(300, 1)])

        let input = AirportBoardViewModel.Input(
            viewDidLoad: viewDidLoad.asObservable(),
            segmentChanged: segmentChanged.asObservable(),
            flightSelected: .never(),
            refreshTrigger: .never()
        )

        let output = viewModel.transform(input: input)

        let typeObserver = scheduler.createObserver(AirportBoardView.BoardType.self)
        output.boardType
            .drive(typeObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertTrue(typeObserver.events.contains { $0.value.element == .arrivals })
    }

    /// Проверяем название аэропорта в заголовке
    func testAirportNameIsOutput() {
        let useCase = FetchAirportBoardUseCase(airportRepository: MockAirportRepository())
        viewModel = AirportBoardViewModel(
            airportCode: "SVO",
            fetchAirportBoardUseCase: useCase
        )

        let input = AirportBoardViewModel.Input(
            viewDidLoad: .never(),
            segmentChanged: .never(),
            flightSelected: .never(),
            refreshTrigger: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver(String.self)
        output.airportName
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(observer.events.first?.value.element, "SVO")
    }
}

// MARK: - MockAirportRepository

/// Мок репозитория аэропортов для тестов.
private final class MockAirportRepository: AirportRepositoryProtocol {

    func fetchDepartures(airportCode: String) -> Observable<[Flight]> {
        .just([TestData.activeFlight])
    }

    func fetchArrivals(airportCode: String) -> Observable<[Flight]> {
        .just([TestData.landedFlight])
    }

    func searchAirports(query: String) -> Observable<[Airport]> {
        .just([TestData.svo])
    }

    func getAirport(code: String) async throws -> Airport {
        TestData.svo
    }
}
