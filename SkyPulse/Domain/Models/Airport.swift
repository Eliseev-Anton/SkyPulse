import Foundation
import CoreLocation

/// Аэропорт с географическими координатами и идентификаторами.
struct Airport: Equatable, Hashable, Codable {
    let icaoCode: String    // например, "UUEE"
    let iataCode: String    // например, "SVO"
    let name: String        // например, "Sheremetyevo International Airport"
    let city: String        // например, "Moscow"
    let country: String     // например, "Russia"
    let latitude: Double
    let longitude: Double
    let timezone: String    // например, "Europe/Moscow"

    /// Координаты для MapKit / CoreLocation
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Компактное отображение: "SVO — Moscow"
    var displayName: String {
        "\(iataCode) — \(city)"
    }

    static let placeholder = Airport(
        icaoCode: "XXXX",
        iataCode: "XXX",
        name: "Unknown Airport",
        city: "Unknown",
        country: "Unknown",
        latitude: 0,
        longitude: 0,
        timezone: "UTC"
    )
}
