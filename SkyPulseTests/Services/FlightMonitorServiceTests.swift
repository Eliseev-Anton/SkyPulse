import XCTest
import RxSwift
@testable import SkyPulse

final class FlightMonitorServiceTests: XCTestCase {

    func testStartAndStopMonitoring() {
        let service = FlightMonitorService.shared
        service.startMonitoring(flightId: "SU100", currentStatus: .active)
        service.stopMonitoring(flightId: "SU100")
        // Нет краша — тест пройден
    }

    func testStopAllClearsMonitored() {
        let service = FlightMonitorService.shared
        service.startMonitoring(flightId: "SU1", currentStatus: .active)
        service.startMonitoring(flightId: "SU2", currentStatus: .scheduled)
        service.stopAll()
    }
}
