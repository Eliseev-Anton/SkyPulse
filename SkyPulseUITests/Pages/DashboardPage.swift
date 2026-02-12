import XCTest

/// Page Object для экрана Dashboard (UI-тесты).
final class DashboardPage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    var flightCards: XCUIElementQuery {
        app.otherElements.matching(identifier: "flightCard")
    }

    var offlineBanner: XCUIElement {
        app.otherElements["offlineBanner"]
    }

    var navigationTitle: XCUIElement {
        app.navigationBars.staticTexts["Dashboard"]
    }

    func waitForLoad(timeout: TimeInterval = 5) -> Bool {
        navigationTitle.waitForExistence(timeout: timeout)
    }

    func tapFlight(at index: Int) {
        flightCards.element(boundBy: index).tap()
    }
}
