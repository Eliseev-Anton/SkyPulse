import UIKit
import RxSwift
import RxCocoa
import SnapKit

/// Экран избранных рейсов: список с swipe‑to‑delete.
///
/// Отображает сохранённые рейсы, позволяет открыть детали или удалить рейс
/// жестом смахивания строки.
final class FavoritesViewController: BaseViewController {

    /// ViewModel, управляющая данными и навигацией.
    private let viewModel: FavoritesViewModel

    // MARK: - UI-элементы

    /// Таблица с карточками избранных рейсов.
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 140
        tv.register(FavoriteFlightCell.self, forCellReuseIdentifier: FavoriteFlightCell.reuseIdentifier)
        return tv
    }()

    /// Вьюха пустого состояния, когда избранных рейсов нет.
    private let emptyStateView = EmptyStateView()

    /// Relay для swipe‑to‑delete, передаёт выбранный рейс во ViewModel.
    private let deleteRelay = PublishRelay<Flight>()

    // MARK: - Инициализация

    /// Инициализирует контроллер ViewModel-ью избранного.
    ///
    /// - Parameter viewModel: Экземпляр `FavoritesViewModel`.
    init(viewModel: FavoritesViewModel) {
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
        title = NSLocalizedString("favorites.title", comment: "")
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    // MARK: - Биндинги

    /// Настраивает реактивные биндинги между ViewModel и UI.
    private func bindViewModel() {
        let input = FavoritesViewModel.Input(
            viewDidLoad: rx.viewWillAppear.mapToVoid(),
            flightSelected: tableView.rx.modelSelected(Flight.self).asObservable(),
            deleteTriggered: deleteRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        // Рейсы → таблица (с кастомным dataSource для swipe‑to‑delete).
        output.favorites
            .drive(tableView.rx.items(
                cellIdentifier: FavoriteFlightCell.reuseIdentifier,
                cellType: FavoriteFlightCell.self
            )) { _, flight, cell in
                cell.configure(with: flight)
            }
            .disposed(by: disposeBag)

        // Пустое состояние.
        output.isEmpty
            .drive(onNext: { [weak self] isEmpty in
                self?.emptyStateView.isHidden = !isEmpty
                self?.tableView.isHidden = isEmpty
            })
            .disposed(by: disposeBag)

        // Deselect.
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)

        // Swipe‑to‑delete.
        tableView.rx.itemDeleted
            .withLatestFrom(output.favorites) { indexPath, flights in
                flights[indexPath.row]
            }
            .bind(to: deleteRelay)
            .disposed(by: disposeBag)

        // Включаем редактирование для swipe‑to‑delete.
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        emptyStateView.configure(
            title: NSLocalizedString("favorites.empty.title", comment: ""),
            subtitle: NSLocalizedString("favorites.empty.subtitle", comment: "")
        )
        emptyStateView.isHidden = true
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDelegate (swipe-to-delete)

extension FavoritesViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            // Удаление обрабатывается через rx.itemDeleted
            self?.tableView.dataSource?.tableView?(
                tableView,
                commit: .delete,
                forRowAt: indexPath
            )
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "heart.slash.fill")
        deleteAction.backgroundColor = .skyStatusRed

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
