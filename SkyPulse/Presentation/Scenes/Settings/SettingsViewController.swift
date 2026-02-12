import UIKit
import RxSwift
import RxCocoa
import SnapKit

/// Экран настроек: уведомления, очистка кэша, информация.
final class SettingsViewController: BaseViewController {

    private let viewModel: SettingsViewModel

    // MARK: - UI-элементы

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .skyBackground
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 56
        tv.register(SettingsOptionCell.self, forCellReuseIdentifier: SettingsOptionCell.reuseIdentifier)
        return tv
    }()

    private let itemSelectedRelay = PublishRelay<SettingsViewModel.SettingsItem>()
    private let notificationToggleRelay = PublishRelay<Bool>()

    // MARK: - Инициализация

    init(viewModel: SettingsViewModel) {
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
        title = NSLocalizedString("settings.title", comment: "")
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    // MARK: - Биндинги

    private func bindViewModel() {
        let input = SettingsViewModel.Input(
            viewDidLoad: rx.viewDidLoad,
            itemSelected: itemSelectedRelay.asObservable(),
            notificationToggled: notificationToggleRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        // Секции → таблица
        output.sections
            .drive(onNext: { [weak self] sections in
                self?.sections = sections
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        // Размер кэша
        output.cacheSize
            .drive(onNext: { [weak self] size in
                self?.cacheSizeText = size
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Данные

    private var sections: [[SettingsViewModel.SettingsItem]] = []
    private var cacheSizeText: String = "—"

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingsOptionCell.reuseIdentifier, for: indexPath
        ) as? SettingsOptionCell else {
            return UITableViewCell()
        }

        let item = sections[indexPath.section][indexPath.row]

        switch item.type {
        case .notifications:
            cell.configure(with: item, showToggle: true) { [weak self] isOn in
                self?.notificationToggleRelay.accept(isOn)
            }
        case .clearCache:
            let itemWithSize = SettingsViewModel.SettingsItem(
                title: item.title,
                subtitle: cacheSizeText,
                icon: item.icon,
                type: item.type
            )
            cell.configure(with: itemWithSize)
        default:
            cell.configure(with: item)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section][indexPath.row]
        itemSelectedRelay.accept(item)
    }
}
