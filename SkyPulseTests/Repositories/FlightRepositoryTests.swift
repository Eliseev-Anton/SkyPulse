import XCTest
import RxSwift
import RxTest
@testable import SkyPulse

final class FlightRepositoryTests: XCTestCase {

    private var mockRepo: MockFlightRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockRepo = MockFlightRepository()
        disposeBag = DisposeBag()
    }

    func testFetchFlightsCallback() {
        mockRepo.stubbedFlights = [TestData.activeFlight]
        var result: [Flight]?

        mockRepo.fetchFlights(params: .dashboard) { res in
            if case .success(let flights) = res { result = flights }
        }

        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(mockRepo.fetchFlightsCallCount, 1)
    }

    func testFetchFlightsAsync() async throws {
        mockRepo.stubbedFlights = [TestData.activeFlight, TestData.landedFlight]
        let flights = try await mockRepo.fetchFlightsAsync(params: .dashboard)
        XCTAssertEqual(flights.count, 2)
    }

    func testFetchFlightsObservable() {
        mockRepo.stubbedFlights = [TestData.scheduledFlight]
        var result: [Flight]?

        mockRepo.observeFlights(params: .dashboard)
            .subscribe(onNext: { result = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(result?.count, 1)
    }

    func testErrorPropagation() {
        mockRepo.stubbedError = NetworkError.serverError(500)
        var receivedError: Error?

        mockRepo.fetchFlights(params: .dashboard) { res in
            if case .failure(let err) = res { receivedError = err }
        }

        XCTAssertNotNil(receivedError)
    }

    func testGetFlightDetail() {
        mockRepo.stubbedFlight = TestData.activeFlight
        var result: Flight?

        mockRepo.getFlightDetail(id: "SU1234")
            .subscribe(onNext: { result = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(result?.flightNumber, "SU1234")
        XCTAssertEqual(mockRepo.getFlightDetailCallCount, 1)
    }
}
