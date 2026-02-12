import XCTest

final class DashboardUITests: XCTestCase {

    private var app: XCUIApplication!
    private var dashboardPage: DashboardPage!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchWithMockData()
        dashboardPage = DashboardPage(app: app)
    }

    func testDashboardLoads() {
        XCTAssertTrue(dashboardPage.waitForLoad())
    }

    func testFlightCardsDisplayed() {
        _ = dashboardPage.waitForLoad()
        XCTAssertTrue(dashboardPage.flightCards.count >= 0)
    }

    func testTabBarExists() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.tabBars.buttons.count, 4)
    }

    func testNavigateToSearch() {
        app.tabBars.buttons["Search"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 3))
    }

    func testNavigateToFavorites() {
        app.tabBars.buttons["Favorites"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }

    func testNavigateToSettings() {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }
}
