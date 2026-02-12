import UIKit
import RxSwift
import RxCocoa
import SnapKit

/// Экран табло аэропорта: вылеты/прилёты с flip-анимацией.
final class AirportBoardViewController: BaseViewController {

    private let viewModel: AirportBoardViewModel

    // MARK: - UI-элементы

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: [
            NSLocalizedString("board.departures", comment: ""),
            NSLocalizedString("board.arrivals", comment: "")
        ])
        sc.selectedSegmentIndex = 0
        sc.accessibilityIdentifier = Constants.AccessibilityID.boardSegment
        return sc
    }()

    private let boardView = AirportBoardView()
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    // MARK: - Инициализация

    init(viewModel: AirportBoardViewModel) {
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
        title = NSLocalizedString("board.title", comment: "")
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    // MARK: - Биндинги

    private func bindViewModel() {
        let input = AirportBoardViewModel.Input(
            viewDidLoad: rx.viewDidLoad,
            segmentChanged: segmentControl.rx.selectedSegmentIndex.asObservable(),
            flightSelected: .never(),
            refreshTrigger: refreshControl.rx.controlEvent(.valueChanged).mapToVoid()
        )

        let output = viewModel.transform(input: input)

        // Рейсы → табло
        Driver.combineLatest(output.flights, output.boardType)
            .drive(onNext: { [weak self] flights, type in
                self?.boardView.update(flights: flights, type: type)
                self?.emptyStateView.isHidden = !flights.isEmpty
            })
            .disposed(by: disposeBag)

        // Название аэропорта → заголовок
        output.airportName
            .drive(onNext: { [weak self] name in
                self?.title = "\(NSLocalizedString("board.title", comment: "")) — \(name)"
            })
            .disposed(by: disposeBag)

        // Загрузка
        output.isLoading
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        // Ошибка
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
        view.addSubview(segmentControl)
        view.addSubview(scrollView)
        scrollView.addSubview(boardView)
        view.addSubview(emptyStateView)

        emptyStateView.configure(
            title: NSLocalizedString("board.empty.title", comment: ""),
            subtitle: NSLocalizedString("board.empty.subtitle", comment: "")
        )
        emptyStateView.isHidden = true
    }

    private func setupConstraints() {
        let padding = Constants.Layout.defaultPadding

        segmentControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(padding)
            make.leading.trailing.bottom.equalToSuperview()
        }

        boardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(padding)
            make.width.equalTo(scrollView).offset(-padding * 2)
            make.height.greaterThanOrEqualTo(400)
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalTo(scrollView)
        }
    }
}
