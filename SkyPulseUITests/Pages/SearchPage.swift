import XCTest

/// Page Object для экрана поиска (UI-тесты).
final class SearchPage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    var searchBar: XCUIElement {
        app.searchFields["searchBar"]
    }

    var searchResults: XCUIElementQuery {
        app.tables.cells
    }

    func typeSearch(_ text: String) {
        searchBar.tap()
        searchBar.typeText(text)
    }

    func submitSearch() {
        app.keyboards.buttons["Search"].tap()
    }
}
