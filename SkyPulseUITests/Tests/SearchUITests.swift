import XCTest

final class SearchUITests: XCTestCase {

    private var app: XCUIApplication!
    private var searchPage: SearchPage!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchWithMockData()
        searchPage = SearchPage(app: app)
        app.tabBars.buttons["Search"].tap()
    }

    func testSearchBarExists() {
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 3))
    }

    func testSearchByFlightNumber() {
        searchPage.typeSearch("SU1234")
        searchPage.submitSearch()
        sleep(2)
        XCTAssertTrue(app.tables.firstMatch.exists)
    }

    func testCancelSearch() {
        searchPage.typeSearch("test")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.exists)
    }
}
