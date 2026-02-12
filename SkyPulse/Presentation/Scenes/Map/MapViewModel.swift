import Foundation
import RxSwift
import RxCocoa
import RxFlow
import RxRelay
import MapKit

/// ViewModel экрана карты: отображение позиций самолётов и маршрутов.
final class MapViewModel: ViewModelType, Stepper {

    let steps = PublishRelay<Step>()

    struct Input {
        let viewDidLoad: Observable<Void>
    }

    struct Output {
        let annotations: Driver<[FlightAnnotation]>
        let routeOverlay: Driver<MKPolyline?>
        let regionToFit: Driver<MKCoordinateRegion?>
    }

    private let flights: [Flight]
    private let disposeBag = DisposeBag()

    init(flights: [Flight]) {
        self.flights = flights
    }

    func transform(input: Input) -> Output {
        // Создаём аннотации для каждого рейса с live-данными
        let annotations = input.viewDidLoad
            .map { [weak self] _ -> [FlightAnnotation] in
                guard let self = self else { return [] }
                return self.flights.compactMap { flight -> FlightAnnotation? in
                    // Приоритет: live-позиция → координаты аэропорта вылета
                    let coordinate: CLLocationCoordinate2D
                    if let live = flight.liveData {
                        coordinate = CLLocationCoordinate2D(
                            latitude: live.latitude,
                            longitude: live.longitude
                        )
                    } else {
                        coordinate = flight.departure.airport.coordinate
                    }

                    return FlightAnnotation(
                        coordinate: coordinate,
                        flight: flight
                    )
                }
            }
            .asDriver(onErrorJustReturn: [])

        // Построение маршрута polyline для одного рейса
        let routeOverlay = input.viewDidLoad
            .map { [weak self] _ -> MKPolyline? in
                guard let self = self,
                      self.flights.count == 1,
                      let flight = self.flights.first else { return nil }

                let depCoord = flight.departure.airport.coordinate
                let arrCoord = flight.arrival.airport.coordinate

                var coordinates = [depCoord]

                // Если есть live-позиция, добавляем промежуточную точку
                if let live = flight.liveData {
                    coordinates.append(CLLocationCoordinate2D(
                        latitude: live.latitude,
                        longitude: live.longitude
                    ))
                }

                coordinates.append(arrCoord)

                return MKPolyline(coordinates: coordinates, count: coordinates.count)
            }
            .asDriver(onErrorJustReturn: nil)

        // Регион для показа всех аннотаций
        let regionToFit = input.viewDidLoad
            .map { [weak self] _ -> MKCoordinateRegion? in
                guard let self = self, !self.flights.isEmpty else { return nil }

                var coordinates: [CLLocationCoordinate2D] = []

                for flight in self.flights {
                    coordinates.append(flight.departure.airport.coordinate)
                    coordinates.append(flight.arrival.airport.coordinate)
                    if let live = flight.liveData {
                        coordinates.append(CLLocationCoordinate2D(
                            latitude: live.latitude,
                            longitude: live.longitude
                        ))
                    }
                }

                guard !coordinates.isEmpty else { return nil }

                let lats = coordinates.map { $0.latitude }
                let lons = coordinates.map { $0.longitude }

                let center = CLLocationCoordinate2D(
                    latitude: (lats.min()! + lats.max()!) / 2,
                    longitude: (lons.min()! + lons.max()!) / 2
                )

                let span = MKCoordinateSpan(
                    latitudeDelta: (lats.max()! - lats.min()!) * 1.4 + 2,
                    longitudeDelta: (lons.max()! - lons.min()!) * 1.4 + 2
                )

                return MKCoordinateRegion(center: center, span: span)
            }
            .asDriver(onErrorJustReturn: nil)

        return Output(
            annotations: annotations,
            routeOverlay: routeOverlay,
            regionToFit: regionToFit
        )
    }
}

// MARK: - FlightAnnotation

/// Аннотация самолёта на карте.
final class FlightAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let flight: Flight

    var title: String? { flight.flightNumber }
    var subtitle: String? {
        "\(flight.departure.airport.iataCode) → \(flight.arrival.airport.iataCode)"
    }

    init(coordinate: CLLocationCoordinate2D, flight: Flight) {
        self.coordinate = coordinate
        self.flight = flight
        super.init()
    }
}
