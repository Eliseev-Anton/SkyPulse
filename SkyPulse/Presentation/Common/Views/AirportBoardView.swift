import UIKit
import SnapKit

/// Табло аэропорта с split-flap анимацией обновления данных.
/// Имитирует механическое табло вылетов/прилётов.
final class AirportBoardView: UIView {

    // MARK: - Типы

    enum BoardType: Int {
        case departures = 0
        case arrivals = 1
    }

    // MARK: - UI-элементы

    private let headerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.12, alpha: 1)
        return v
    }()

    private let headerLabels: [UILabel] = {
        let titles = ["TIME", "FLIGHT", "DESTINATION", "STATUS", "GATE"]
        return titles.map { title in
            let l = UILabel()
            l.text = title
            l.font = .skyBoard
            l.textColor = UIColor(white: 0.6, alpha: 1)
            return l
        }
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = UIColor(white: 0.08, alpha: 1)
        tv.separatorColor = UIColor(white: 0.2, alpha: 1)
        tv.rowHeight = 44
        return tv
    }()

    private var flights: [Flight] = []
    private var boardType: BoardType = .departures

    // MARK: - Инициализация

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()

        tableView.dataSource = self
        tableView.register(BoardFlightCell.self, forCellReuseIdentifier: BoardFlightCell.reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    // MARK: - Публичные методы

    /// Обновить данные табло с каскадной flip-анимацией
    func update(flights: [Flight], type: BoardType, animated: Bool = true) {
        self.boardType = type
        let oldFlights = self.flights
        self.flights = flights

        if animated && !oldFlights.isEmpty {
            animateBoardUpdate()
        } else {
            tableView.reloadData()
        }
    }

    // MARK: - Flip-анимация

    /// Каскадная анимация обновления строк табло
    private func animateBoardUpdate() {
        tableView.reloadData()

        for (index, cell) in tableView.visibleCells.enumerated() {
            guard let boardCell = cell as? BoardFlightCell else { continue }
            let delay = Double(index) * 0.08

            // Начальное состояние — повёрнуто на 90° по оси X
            boardCell.contentView.layer.transform = CATransform3DMakeRotation(-.pi / 2, 1, 0, 0)
            boardCell.contentView.alpha = 0

            UIView.animate(
                withDuration: AppConfiguration.boardFlipAnimationDuration,
                delay: delay,
                options: .curveEaseOut
            ) {
                boardCell.contentView.layer.transform = CATransform3DIdentity
                boardCell.contentView.alpha = 1
            }
        }
    }

    // MARK: - Layout

    private func setupUI() {
        backgroundColor = UIColor(white: 0.08, alpha: 1)
        layer.cornerRadius = Constants.Layout.cornerRadius
        clipsToBounds = true

        addSubview(headerView)
        addSubview(tableView)

        let headerStack = UIStackView(arrangedSubviews: headerLabels)
        headerStack.distribution = .fillProportionally
        headerStack.spacing = 8
        headerView.addSubview(headerStack)

        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }
    }

    private func setupConstraints() {
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource

extension AirportBoardView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        flights.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BoardFlightCell.reuseIdentifier, for: indexPath
        ) as? BoardFlightCell else {
            return UITableViewCell()
        }
        cell.configure(with: flights[indexPath.row], type: boardType)
        return cell
    }
}

// MARK: - BoardFlightCell (строка табло)

/// Ячейка строки табло аэропорта с моноширинным шрифтом.
final class BoardFlightCell: BaseTableViewCell {

    private let timeLabel = UILabel()
    private let flightLabel = UILabel()
    private let destinationLabel = UILabel()
    private let statusLabel = UILabel()
    private let gateLabel = UILabel()

    override func setupUI() {
        backgroundColor = UIColor(white: 0.1, alpha: 1)

        [timeLabel, flightLabel, destinationLabel, statusLabel, gateLabel].forEach {
            $0.font = .skyBoard
            $0.textColor = UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1) // жёлтый цвет табло
        }

        let stack = UIStackView(arrangedSubviews: [timeLabel, flightLabel, destinationLabel, statusLabel, gateLabel])
        stack.distribution = .fillProportionally
        stack.spacing = 8
        contentView.addSubview(stack)

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12))
        }
    }

    func configure(with flight: Flight, type: AirportBoardView.BoardType) {
        let endpoint = type == .departures ? flight.departure : flight.arrival
        let destination = type == .departures ? flight.arrival : flight.departure

        timeLabel.text = endpoint.bestAvailableTime?.displayTime ?? "--:--"
        flightLabel.text = flight.flightNumber
        destinationLabel.text = destination.airport.iataCode
        statusLabel.text = flight.status.displayName
        gateLabel.text = endpoint.gate ?? "-"

        // Красный цвет для отменённых рейсов
        let textColor: UIColor = flight.status == .cancelled
            ? .skyStatusRed
            : UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)

        [timeLabel, flightLabel, destinationLabel, statusLabel, gateLabel].forEach {
            $0.textColor = textColor
        }
    }
}
