import UIKit
import RxSwift
import RxCocoa
import SnapKit

/// Главный экран приложения — список отслеживаемых рейсов.
///
/// Отображает активные рейсы в таблице, показывает офлайн‑баннер,
/// пустое состояние и обрабатывает pull‑to‑refresh.
final class DashboardViewController: BaseViewController {

    /// ViewModel, предоставляющий данные и навигационные события.
    private let viewModel: DashboardViewModel

    // MARK: - UI-элементы

    /// Таблица с карточками активных рейсов.
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 140
        tv.register(ActiveFlightCell.self, forCellReuseIdentifier: ActiveFlightCell.reuseIdentifier)
        return tv
    }()

    /// Контрол для реализации жеста pull‑to‑refresh.
    private let refreshControl = UIRefreshControl()

    /// Баннер, показывающий, что устройство в офлайн‑режиме.
    private let offlineBanner: UIView = {
        let v = UIView()
        v.backgroundColor = .skyStatusOrange
        v.isHidden = true
        let label = UILabel()
        label.text = NSLocalizedString("common.offline", comment: "")
        label.font = .skyCaptionBold
        label.textColor = .white
        label.textAlignment = .center
        v.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }
        return v
    }()

    /// Вьюха пустого состояния, когда рейсов нет.
    private let emptyStateView = EmptyStateView()

    // MARK: - Инициализация

    /// Инициализирует контроллер с конкретной ViewModel.
    ///
    /// - Parameter viewModel: Экземпляр `DashboardViewModel`.
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    // MARK: - Lifecycle

    /// Настраивает UI, layout и биндинги после загрузки view.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("dashboard.title", comment: "")
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    // MARK: - Биндинги

    /// Настраивает реактивные биндинги между ViewModel и UI.
    private func bindViewModel() {
        let input = DashboardViewModel.Input(
            viewDidLoad: rx.viewWillAppear.take(1).mapToVoid(),
            pullToRefresh: refreshControl.rx.controlEvent(.valueChanged).mapToVoid(),
            flightSelected: tableView.rx.modelSelected(Flight.self).asObservable()
        )

        let output = viewModel.transform(input: input)

        // Рейсы → таблица.
        output.flights
            .drive(tableView.rx.items(
                cellIdentifier: ActiveFlightCell.reuseIdentifier,
                cellType: ActiveFlightCell.self
            )) { _, flight, cell in
                cell.configure(with: flight)
            }
            .disposed(by: disposeBag)

        // Пустое состояние.
        output.flights
            .map { !$0.isEmpty }
            .drive(emptyStateView.rx.isHidden)
            .disposed(by: disposeBag)

        // Загрузка (pull-to-refresh).
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

        // Оффлайн-баннер.
        output.isOffline
            .drive(onNext: { [weak self] isOffline in
                self?.animateOfflineBanner(show: isOffline)
            })
            .disposed(by: disposeBag)

        // Deselect строки после нажатия.
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Анимация оффлайн-баннера

    /// Анимирует показ или скрытие офлайн‑баннера.
    ///
    /// - Parameter show: `true`, чтобы показать баннер, `false` — чтобы скрыть.
    private func animateOfflineBanner(show: Bool) {
        offlineBanner.isHidden = false
        offlineBanner.snp.updateConstraints { make in
            make.height.equalTo(show ? 36 : 0)
        }
        UIView.animate(withDuration: 0.3) {
            self.offlineBanner.alpha = show ? 1 : 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.offlineBanner.isHidden = !show
        }
    }

    // MARK: - Layout

    private func setupUI() {
        tableView.refreshControl = refreshControl
        view.addSubview(offlineBanner)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        emptyStateView.configure(
            title: NSLocalizedString("dashboard.empty.title", comment: ""),
            subtitle: NSLocalizedString("dashboard.empty.subtitle", comment: "")
        )
        emptyStateView.isHidden = true

        offlineBanner.accessibilityIdentifier = Constants.AccessibilityID.offlineBanner
    }

    private func setupConstraints() {
        offlineBanner.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(offlineBanner.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }
}
