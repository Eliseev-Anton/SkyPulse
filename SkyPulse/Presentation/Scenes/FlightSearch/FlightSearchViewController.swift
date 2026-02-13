import UIKit
import RxSwift
import RxCocoa
import SnapKit

/// Экран поиска рейсов: поисковая строка, результаты, история запросов.
///
/// Предоставляет текстовый поиск по номеру рейса, маршруту или аэропорту,
/// показывает историю запросов и список найденных рейсов.
final class FlightSearchViewController: BaseViewController {

    /// ViewModel, реализующая бизнес‑логику поиска.
    private let viewModel: FlightSearchViewModel

    // MARK: - UI-элементы

    /// Поисковая строка для ввода номера рейса, маршрута или кода аэропорта.
    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = NSLocalizedString("search.placeholder", comment: "")
        sb.searchBarStyle = .minimal
        sb.accessibilityIdentifier = Constants.AccessibilityID.searchBar
        return sb
    }()

    /// Таблица для отображения результатов поиска.
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 140
        tv.register(FlightResultCell.self, forCellReuseIdentifier: FlightResultCell.reuseIdentifier)
        tv.keyboardDismissMode = .onDrag
        return tv
    }()

    /// Таблица истории поисковых запросов.
    private lazy var historyTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorColor = .skyTextSecondary.withAlphaComponent(0.2)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 50
        tv.register(SearchHistoryCell.self, forCellReuseIdentifier: SearchHistoryCell.reuseIdentifier)
        return tv
    }()

    /// Заголовок блока истории с текстом «Недавние запросы».
    private let historyHeaderView: UIView = {
        let v = UIView()
        let label = UILabel()
        label.text = NSLocalizedString("search.history.title", comment: "")
        label.font = .skySubheadlineBold
        label.textColor = .skyTextSecondary
        v.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Constants.Layout.defaultPadding)
            make.centerY.equalToSuperview()
        }
        return v
    }()

    /// Кнопка очистки истории поиска.
    private lazy var clearHistoryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("search.history.clear", comment: ""), for: .normal)
        btn.titleLabel?.font = .skyCaption
        btn.tintColor = .skyStatusRed
        return btn
    }()

    /// Вьюха пустого состояния, когда по запросу не найдено рейсов.
    private let emptyResultView = EmptyStateView()

    // MARK: - Инициализация

    /// Инициализирует контроллер с ViewModel поиска рейсов.
    ///
    /// - Parameter viewModel: Экземпляр `FlightSearchViewModel`.
    init(viewModel: FlightSearchViewModel) {
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
        title = NSLocalizedString("search.title", comment: "")
        setupUI()
        setupConstraints()
        bindViewModel()

        // Скрытие клавиатуры при тапе по пустой области.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }

    // MARK: - Биндинги

    /// Настраивает реактивные биндинги между ViewModel и UI.
    private func bindViewModel() {
        let searchText = searchBar.rx.text.orEmpty.asObservable()
            .distinctUntilChanged()

        // Скрываем клавиатуру при нажатии кнопки «Поиск».
        let searchTrigger = searchBar.rx.searchButtonClicked.asObservable()
            .do(onNext: { [weak self] in self?.searchBar.resignFirstResponder() })

        let cancelTrigger = searchBar.rx.cancelButtonClicked.asObservable()
            .do(onNext: { [weak self] in
                self?.searchBar.text = ""
                self?.searchBar.resignFirstResponder()
            })

        let input = FlightSearchViewModel.Input(
            searchText: searchText,
            searchTrigger: searchTrigger,
            cancelTrigger: cancelTrigger,
            flightSelected: tableView.rx.modelSelected(Flight.self).asObservable(),
            historySelected: historyTableView.rx.modelSelected(SearchQuery.self).asObservable(),
            clearHistory: clearHistoryButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        // Результаты поиска → таблица.
        output.flights
            .drive(tableView.rx.items(
                cellIdentifier: FlightResultCell.reuseIdentifier,
                cellType: FlightResultCell.self
            )) { _, flight, cell in
                cell.configure(with: flight)
            }
            .disposed(by: disposeBag)

        // История поиска → таблица.
        output.searchHistory
            .drive(historyTableView.rx.items(
                cellIdentifier: SearchHistoryCell.reuseIdentifier,
                cellType: SearchHistoryCell.self
            )) { _, query, cell in
                cell.configure(with: query)
            }
            .disposed(by: disposeBag)

        // Видимость блоков: история / результаты.
        output.isHistoryVisible
            .drive(onNext: { [weak self] showHistory in
                self?.historyTableView.isHidden = !showHistory
                self?.historyHeaderView.isHidden = !showHistory
                self?.clearHistoryButton.isHidden = !showHistory
                self?.tableView.isHidden = showHistory
            })
            .disposed(by: disposeBag)

        // Пустое состояние: скрыто когда идёт история ИЛИ есть результаты.
        Driver.combineLatest(output.isHistoryVisible, output.flights) { showHistory, flights in
            showHistory || !flights.isEmpty
        }
        .drive(emptyResultView.rx.isHidden)
        .disposed(by: disposeBag)

        // Загрузка.
        output.isLoading
            .drive(onNext: { [weak self] loading in
                if loading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            })
            .disposed(by: disposeBag)

        // Ошибки.
        output.errorMessage
            .compactMap { $0 }
            .drive(onNext: { [weak self] message in
                self?.showError(message)
            })
            .disposed(by: disposeBag)

        // Deselect после нажатия.
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)

        historyTableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.historyTableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Показ/скрытие загрузки

    private var loadingView: LoadingView?

    /// Показывает полноэкранный индикатор загрузки.
    private func showLoading() {
        guard loadingView == nil else { return }
        let lv = LoadingView()
        view.addSubview(lv)
        lv.snp.makeConstraints { $0.edges.equalToSuperview() }
        lv.show(in: view)
        loadingView = lv
    }

    /// Скрывает индикатор загрузки.
    private func hideLoading() {
        loadingView?.hide()
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(historyHeaderView)
        view.addSubview(historyTableView)
        view.addSubview(emptyResultView)

        historyHeaderView.addSubview(clearHistoryButton)

        emptyResultView.configure(
            title: NSLocalizedString("search.empty.title", comment: ""),
            subtitle: NSLocalizedString("search.empty.subtitle", comment: "")
        )
        emptyResultView.isHidden = true

        searchBar.showsCancelButton = false
    }

    private func setupConstraints() {
        let padding = Constants.Layout.defaultPadding

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }

        // Заголовок истории
        historyHeaderView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        clearHistoryButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
        }

        // Таблица истории
        historyTableView.snp.makeConstraints { make in
            make.top.equalTo(historyHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // Таблица результатов
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyResultView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }
}
