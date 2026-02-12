import Foundation

/// Авиакомпания, выполняющая рейс.
struct Airline: Equatable, Hashable, Codable {
    let iataCode: String   // например, "SU"
    let icaoCode: String   // например, "AFL"
    let name: String       // например, "Aeroflot"

    static let placeholder = Airline(
        iataCode: "--",
        icaoCode: "---",
        name: "Unknown Airline"
    )
}
