import XCTest

/// Расширение для запуска приложения с mock-данными в UI-тестах.
extension XCUIApplication {

    /// Запуск с предзагруженными mock-данными (без обращения к реальным API)
    func launchWithMockData() {
        launchArguments = ["--uitesting", "--use-mock-data"]
        launch()
    }
}
