import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import SkyPulse

/// Тесты FavoritesViewModel: список, удаление, пустое состояние.
final class FavoritesViewModelTests: XCTestCase {

    private var viewModel: FavoritesViewModel!
    private var mockFavoritesRepository: MockFavoritesRepository!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockFavoritesRepository = MockFavoritesRepository()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()

        let useCase = ManageFavoritesUseCase(favoritesRepository: mockFavoritesRepository)
        viewModel = FavoritesViewModel(manageFavoritesUseCase: useCase)
    }

    override func tearDown() {
        viewModel = nil
        mockFavoritesRepository = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - Тесты

    /// Проверяем пустое состояние без избранных
    func testEmptyStateWhenNoFavorites() {
        let input = FavoritesViewModel.Input(
            viewDidLoad: .just(()),
            flightSelected: .never(),
            deleteTriggered: .never()
        )

        let output = viewModel.transform(input: input)

        let isEmptyObserver = scheduler.createObserver(Bool.self)
        output.isEmpty
            .drive(isEmptyObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertTrue(isEmptyObserver.events.contains { $0.value.element == true })
    }

    /// Проверяем отображение избранных
    func testFavoritesDisplayed() {
        // Предварительно добавляем рейс в избранное
        _ = mockFavoritesRepository.addFavorite(TestData.activeFlight)
            .subscribe()

        let input = FavoritesViewModel.Input(
            viewDidLoad: .just(()),
            flightSelected: .never(),
            deleteTriggered: .never()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver([Flight].self)
        output.favorites
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        let lastFlights = observer.events.last?.value.element
        XCTAssertEqual(lastFlights?.count, 1)
        XCTAssertEqual(lastFlights?.first?.id, TestData.activeFlight.id)
    }

    /// Проверяем удаление из избранного
    func testDeleteFromFavorites() {
        _ = mockFavoritesRepository.addFavorite(TestData.activeFlight)
            .subscribe()

        let deleteTriggered = scheduler.createHotObservable([
            .next(300, TestData.activeFlight)
        ])

        let input = FavoritesViewModel.Input(
            viewDidLoad: .just(()),
            flightSelected: .never(),
            deleteTriggered: deleteTriggered.asObservable()
        )

        let output = viewModel.transform(input: input)

        let observer = scheduler.createObserver([Flight].self)
        output.favorites
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        // После удаления removeFavoriteCallCount должен увеличиться
        XCTAssertEqual(mockFavoritesRepository.removeFavoriteCallCount, 1)
    }
}
