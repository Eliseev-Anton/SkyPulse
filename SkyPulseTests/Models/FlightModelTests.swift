import XCTest
@testable import SkyPulse

final class FlightModelTests: XCTestCase {

    func testFlightProgressLanded() {
        let flight = TestData.makeFlight(status: .landed)
        XCTAssertEqual(flight.flightProgress, 1.0)
    }

    func testFlightProgressScheduled() {
        let flight = TestData.makeFlight(status: .scheduled)
        XCTAssertEqual(flight.flightProgress, 0.0)
    }

    func testSearchQueryDetectFlightNumber() {
        let query = SearchQuery.detect(from: "SU1234")
        XCTAssertEqual(query.type, .flightNumber)
        XCTAssertEqual(query.text, "SU1234")
    }

    func testSearchQueryDetectRoute() {
        let query = SearchQuery.detect(from: "SVO-JFK")
        XCTAssertEqual(query.type, .route)
    }

    func testSearchQueryDetectAirport() {
        let query = SearchQuery.detect(from: "SVO")
        XCTAssertEqual(query.type, .airport)
    }

    func testFlightEndpointBestTime() {
        let now = Date()
        let endpoint = FlightEndpoint(
            airport: TestData.svo, terminal: nil, gate: nil,
            scheduledTime: now, estimatedTime: now.addingTimeInterval(600),
            actualTime: nil, delay: 10
        )
        XCTAssertEqual(endpoint.bestAvailableTime, now.addingTimeInterval(600))
    }

    func testFlightEndpointDelayString() {
        let endpoint = FlightEndpoint(
            airport: TestData.svo, terminal: nil, gate: nil,
            scheduledTime: nil, estimatedTime: nil, actualTime: nil, delay: 25
        )
        XCTAssertEqual(endpoint.delayDisplayString, "+25 min")
    }

    func testFlightEndpointNoDelay() {
        let endpoint = FlightEndpoint(
            airport: TestData.svo, terminal: nil, gate: nil,
            scheduledTime: nil, estimatedTime: nil, actualTime: nil, delay: nil
        )
        XCTAssertNil(endpoint.delayDisplayString)
    }

    func testFlightStatusFromAPIString() {
        XCTAssertEqual(FlightStatus(apiString: "active"), .active)
        XCTAssertEqual(FlightStatus(apiString: "landed"), .landed)
        XCTAssertEqual(FlightStatus(apiString: "unknown_value"), .unknown)
    }

    func testAirportDisplayName() {
        XCTAssertEqual(TestData.svo.displayName, "SVO — Moscow")
    }
}
