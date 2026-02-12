import Foundation
import CoreLocation
import RxSwift
import RxRelay

/// Сервис геолокации на базе `CLLocationManager` и Rx.
///
/// Предоставляет реактивный доступ к текущей позиции пользователя и статусу авторизации,
/// а также вспомогательные методы для расчёта расстояния.
final class LocationService: NSObject {

    /// Синглтон‑экземпляр сервиса геолокации.
    static let shared = LocationService()

    /// Низкоуровневый менеджер CoreLocation.
    private let locationManager = CLLocationManager()

    /// Хранилище текущего местоположения пользователя.
    private let currentLocationRelay = BehaviorRelay<CLLocation?>(value: nil)

    /// Реактивный поток текущего местоположения пользователя.
    var currentLocation: Observable<CLLocation?> {
        currentLocationRelay.asObservable()
    }

    /// Хранилище статуса авторизации на использование геолокации.
    private let authorizationStatusRelay = BehaviorRelay<CLAuthorizationStatus>(value: .notDetermined)

    /// Реактивный поток статуса авторизации (изменяется при действиях пользователя).
    var authorizationStatus: Observable<CLAuthorizationStatus> {
        authorizationStatusRelay.asObservable()
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000 // обновления каждые 1 км
    }

    // MARK: - Управление

    /// Запрашивает у пользователя разрешение на использование геолокации «при использовании».
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Начинает отслеживание позиции пользователя в фоне.
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        Logger.data("Геолокация: начато отслеживание")
    }

    /// Останавливает отслеживание позиции пользователя.
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        Logger.data("Геолокация: отслеживание остановлено")
    }

    /// Запрашивает разовое обновление позиции пользователя.
    func requestLocation() {
        locationManager.requestLocation()
    }

    // MARK: - Расчёты

    /// Возвращает расстояние до указанных координат в километрах.
    ///
    /// - Parameter coordinate: Целевая точка на карте.
    /// - Returns: Расстояние в километрах или `nil`, если текущая позиция неизвестна.
    func distance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let current = currentLocationRelay.value else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target) / 1000 // метры → километры
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocationRelay.accept(location)
        Logger.data("Геолокация обновлена: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.error("Ошибка геолокации", error: error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatusRelay.accept(manager.authorizationStatus)

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            Logger.data("Геолокация: доступ запрещён")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
