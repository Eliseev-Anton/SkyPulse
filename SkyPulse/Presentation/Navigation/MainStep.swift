import RxFlow

/// Шаги навигации внутри основного flow (TabBar + push‑переходы).
///
/// Позволяют декларативно описать переходы между главными вкладками и детальными экранами.
enum MainStep: Step {
    /// Показать главный экран Dashboard.
    case dashboardIsRequired
    /// Показать экран поиска рейсов.
    case flightSearchIsRequired
    /// Показать экран деталей конкретного рейса.
    /// - Parameters:
    ///   - flightId: Идентификатор рейса.
    ///   - icao24: ICAO24‑идентификатор самолёта (опционально).
    case flightDetailIsRequired(flightId: String, icao24: String?)
    /// Показать табло аэропорта по коду.
    case airportBoardIsRequired(airportCode: String)
    /// Показать экран избранных рейсов.
    case favoritesIsRequired
    /// Показать настройки приложения.
    case settingsIsRequired
    /// Показать карту с выбранными рейсами.
    case mapIsRequired(flights: [Flight])
    /// Закрыть модально представленный экран.
    case dismissModal
    /// Выполнить `pop` на текущем navigation stack.
    case popScreen
}
