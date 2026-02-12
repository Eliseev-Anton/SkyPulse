import UIKit
import MapKit
import RxSwift
import RxCocoa
import SnapKit

/// Экран карты с отображением самолётов и маршрутов.
final class MapViewController: BaseViewController {

    private let viewModel: MapViewModel

    // MARK: - UI-элементы

    private let mapView: MKMapView = {
        let mv = MKMapView()
        mv.showsUserLocation = true
        mv.pointOfInterestFilter = .excludingAll
        return mv
    }()

    // MARK: - Инициализация

    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("map.title", comment: "")
        setupNavigationBar()
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    // MARK: - Навигация

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeMapTapped)
        )
    }

    @objc
    private func closeMapTapped() {
        navigationController?.dismiss(animated: true)
    }

    // MARK: - Биндинги

    private func bindViewModel() {
        let input = MapViewModel.Input(
            viewDidLoad: rx.viewWillAppear.take(1).mapToVoid()
        )

        let output = viewModel.transform(input: input)

        // Аннотации самолётов
        output.annotations
            .drive(onNext: { [weak self] annotations in
                guard let self = self else { return }
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations(annotations)
            })
            .disposed(by: disposeBag)

        // Маршрутная линия
        output.routeOverlay
            .compactMap { $0 }
            .drive(onNext: { [weak self] polyline in
                guard let self = self else { return }
                self.mapView.removeOverlays(self.mapView.overlays)
                self.mapView.addOverlay(polyline)
            })
            .disposed(by: disposeBag)

        // Регион карты
        output.regionToFit
            .compactMap { $0 }
            .drive(onNext: { [weak self] region in
                self?.mapView.setRegion(region, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(mapView)
        mapView.delegate = self
    }

    private func setupConstraints() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let flightAnnotation = annotation as? FlightAnnotation else { return nil }

        let identifier = "FlightPin"
        let view: MKAnnotationView

        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
        }

        // Иконка самолёта с поворотом по heading
        let planeImage = UIImage(systemName: "airplane")?
            .withTintColor(.skyPrimaryBlue, renderingMode: .alwaysOriginal)
        view.image = planeImage

        // Поворот самолёта по направлению
        if let heading = flightAnnotation.flight.liveData?.heading {
            let radians = heading * .pi / 180
            view.transform = CGAffineTransform(rotationAngle: CGFloat(radians))
        }

        return view
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .skyPrimaryBlue
            renderer.lineWidth = 3
            renderer.lineDashPattern = [8, 6]
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
