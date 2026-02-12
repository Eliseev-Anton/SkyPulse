import XCTest
import RxSwift
@testable import SkyPulse

final class FavoritesRepositoryTests: XCTestCase {

    private var mockRepo: MockFavoritesRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockRepo = MockFavoritesRepository()
        disposeBag = DisposeBag()
    }

    func testAddAndGetFavorites() {
        _ = mockRepo.addFavorite(TestData.activeFlight).subscribe()
        var result: [Flight]?

        mockRepo.getFavorites()
            .subscribe(onNext: { result = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(mockRepo.addFavoriteCallCount, 1)
    }

    func testRemoveFavorite() {
        _ = mockRepo.addFavorite(TestData.activeFlight).subscribe()
        _ = mockRepo.removeFavorite(flightId: TestData.activeFlight.id).subscribe()

        var result: [Flight]?
        mockRepo.getFavorites()
            .subscribe(onNext: { result = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(result?.count, 0)
        XCTAssertEqual(mockRepo.removeFavoriteCallCount, 1)
    }

    func testIsFavorite() {
        _ = mockRepo.addFavorite(TestData.activeFlight).subscribe()
        var isFav: Bool?

        mockRepo.isFavorite(flightId: TestData.activeFlight.id)
            .subscribe(onNext: { isFav = $0 })
            .disposed(by: disposeBag)

        XCTAssertTrue(isFav ?? false)
    }

    func testIsNotFavorite() {
        var isFav: Bool?
        mockRepo.isFavorite(flightId: "nonexistent")
            .subscribe(onNext: { isFav = $0 })
            .disposed(by: disposeBag)

        XCTAssertFalse(isFav ?? true)
    }
}
