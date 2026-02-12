import Foundation
import CoreLocation

/// Телеметрия самолёта в реальном времени.
///
/// Содержит нормализованные значения высоты, скорости, курса и пр.,
/// полученные из OpenSky Network API (state vectors), и удобные производные
/// свойства для отображения на карте и в интерфейсе.
struct FlightLiveData: Equatable, Hashable, Codable {
    /// Географическая широта самолёта в десятичных градусах.
    let latitude: Double

    /// Географическая долгота самолёта в десятичных градусах.
    let longitude: Double

    /// Барометрическая высота полёта в метрах.
    let altitude: Double

    /// Наземная скорость в метрах в секунду.
    let speed: Double

    /// Магнитный курс в градусах, где 0° — север, 90° — восток.
    let heading: Double

    /// Скорость набора или снижения в метрах в секунду (положительное — набор).
    let verticalRate: Double

    /// Флаг, указывающий, что самолёт находится на земле.
    let isOnGround: Bool

    /// Время последнего обновления данных телеметрии.
    let lastUpdated: Date

    /// Координаты для отображения самолёта на карте (`MapKit`).
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Высота полёта, сконвертированная в футы (авиационный стандарт).
    var altitudeInFeet: Int {
        Int(altitude * 3.28084)
    }

    /// Скорость полёта в узлах (knots).
    var speedInKnots: Int {
        Int(speed * 1.94384)
    }

    /// Форматированная строка высоты, например `35000 ft`.
    var altitudeFormatted: String { "\(altitudeInFeet) ft" }

    /// Форматированная строка скорости, например `450 kts`.
    var speedFormatted: String { "\(speedInKnots) kts" }
}
