import UIKit
import RxSwift
import RxCocoa
import SnapKit

/// Экран деталей рейса: маршрут, статус, информация, кнопки избранного и карты.
///
/// Состоит из нескольких секций (`FlightRouteSection`, `FlightStatusSection`,
/// `FlightInfoSection`) и позволяет добавить рейс в избранное или открыть его на карте.
final class FlightDetailViewController: BaseViewController {

    /// ViewModel, предоставляющая данные рейса и навигационные события.
    private let viewModel: FlightDetailViewModel

    // MARK: - UI-элементы

    /// Скролл‑контейнер для вертикального списка секций.
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    /// Вертикальный стек, содержащий все секции деталей.
    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.distribution = .fill
        sv.alignment = .fill
        return sv
    }()

    /// Секция с маршрутом (вылет/прилёт, времена, прогресс).
    private let routeSection = FlightRouteSection()
    /// Секция с live‑статусом рейса (высота, скорость, курс).
    private let statusSection = FlightStatusSection()
    /// Секция с общей информацией (авиакомпания, самолёт, дата).
    private let infoSection = FlightInfoSection()

    /// Кнопка избранного в навигационной панели (иконка сердца).
    private lazy var favoriteButtonView: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "heart"), for: .normal)
        btn.tintColor = .skyPrimaryBlue
        btn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        btn.accessibilityIdentifier = Constants.AccessibilityID.favoriteButton
        return btn
    }()

    /// Элемент навигационной панели, оборачивающий кнопку избранного.
    private lazy var favoriteButton: UIBarButtonItem = {
        UIBarButtonItem(customView: favoriteButtonView)
    }()

    /// Кнопка открытия рейса на карте.
    private lazy var mapButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("detail.showOnMap", comment: ""), for: .normal)
        btn.setImage(UIImage(systemName: "map"), for: .normal)
        btn.titleLabel?.font = .skyBodyBold
        btn.tintColor = .white
        btn.backgroundColor = .skyPrimaryBlue
        btn.layer.cornerRadius = Constants.Layout.smallCornerRadius
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        return btn
    }()

    /// Контрол для реализации pull‑to‑refresh в скролле.
    private let refreshControl = UIRefreshControl()

    // MARK: - Инициализация

    /// Инициализирует контроллер конкретной ViewModel.
    ///
    /// - Parameter viewModel: Экземпляр `FlightDetailViewModel`.
    init(viewModel: FlightDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    // MARK: - Lifecycle

    /// Вызывается после загрузки view: настраивает UI и биндинги.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("detail.title", comment: "")
        navigationItem.rightBarButtonItem = favoriteButton
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    // MARK: - Биндинги

    /// Настраивает реактивные биндинги между ViewModel и UI.
    private func bindViewModel() {
        let input = FlightDetailViewModel.Input(
            viewDidLoad: rx.viewWillAppear.take(1).mapToVoid(),
            toggleFavorite: favoriteButtonView.rx.tap.asObservable(),
            showOnMap: mapButton.rx.tap.asObservable(),
            refreshTrigger: refreshControl.rx.controlEvent(.valueChanged).mapToVoid()
        )

        let output = viewModel.transform(input: input)

        // Данные рейса → секции.
        output.flight
            .compactMap { $0 }
            .drive(onNext: { [weak self] flight in
                self?.routeSection.configure(with: flight)
                self?.statusSection.configure(with: flight)
                self?.infoSection.configure(with: flight)
                self?.title = flight.flightNumber
                self?.mapButton.isHidden = false
            })
            .disposed(by: disposeBag)

        // Статус избранного → иконка.
        output.isFavorite
            .drive(onNext: { [weak self] isFav in
                guard let self else { return }
                let imageName = isFav ? "heart.fill" : "heart"
                self.favoriteButtonView.setImage(UIImage(systemName: imageName), for: .normal)
                self.favoriteButtonView.tintColor = isFav ? .skyStatusRed : .skyPrimaryBlue

                UIView.animate(
                    withDuration: 0.15,
                    animations: {
                        self.favoriteButtonView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                    },
                    completion: { _ in
                        UIView.animate(withDuration: 0.15) {
                            self.favoriteButtonView.transform = .identity
                        }
                    }
                )
            })
            .disposed(by: disposeBag)

        // Загрузка.
        output.isLoading
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        // Ошибка.
        output.errorMessage
            .compactMap { $0 }
            .drive(onNext: { [weak self] message in
                self?.showError(message)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Layout

    private func setupUI() {
        scrollView.refreshControl = refreshControl
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        [routeSection, statusSection, infoSection, mapButton].forEach {
            contentStack.addArrangedSubview($0)
        }

        mapButton.isHidden = true
    }

    private func setupConstraints() {
        let padding = Constants.Layout.defaultPadding

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(padding)
            make.width.equalTo(scrollView).offset(-padding * 2)
        }

        mapButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }
}
