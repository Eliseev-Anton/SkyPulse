import RxFlow

/// Шаги навигации во flow поиска.
enum SearchStep: Step {
    case searchIsRequired
    case resultSelected(flightId: String, icao24: String?)
    case airportSelected(airportCode: String)
}
