import UIKit
import SnapKit

/// Секция маршрута: аэропорты вылета и прилёта с визуальной линией прогресса.
///
/// Показывает основные параметры вылета/прилёта и прогресс полёта
/// при помощи `UIProgressView` и иконки самолёта.
final class FlightRouteSection: UIView {

    // MARK: - UI-элементы

    // Вылет
    /// Метка с IATA‑кодом аэропорта вылета.
    private let departureCodeLabel: UILabel = {
        let l = UILabel()
        l.font = .skyAirportCode
        l.textColor = .skyTextPrimary
        return l
    }()

    /// Метка с названием аэропорта/города вылета.
    private let departureNameLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        l.numberOfLines = 2
        return l
    }()

    /// Метка с временем вылета.
    private let departureTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .skyHeadline
        l.textColor = .skyTextPrimary
        return l
    }()

    /// Метка с терминалом/выходом вылета.
    private let departureTerminalLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        return l
    }()

    /// Метка с информацией о задержке вылета.
    private let departureDelayLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaptionBold
        l.textColor = .skyStatusOrange
        return l
    }()

    // Прилёт
    /// Метка с IATA‑кодом аэропорта прилёта.
    private let arrivalCodeLabel: UILabel = {
        let l = UILabel()
        l.font = .skyAirportCode
        l.textColor = .skyTextPrimary
        l.textAlignment = .right
        return l
    }()

    /// Метка с названием аэропорта/города прилёта.
    private let arrivalNameLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        l.textAlignment = .right
        l.numberOfLines = 2
        return l
    }()

    /// Метка с временем прилёта.
    private let arrivalTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .skyHeadline
        l.textColor = .skyTextPrimary
        l.textAlignment = .right
        return l
    }()

    /// Метка с терминалом/выходом прилёта.
    private let arrivalTerminalLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        l.textAlignment = .right
        return l
    }()

    /// Метка с информацией о задержке прилёта.
    private let arrivalDelayLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaptionBold
        l.textColor = .skyStatusOrange
        l.textAlignment = .right
        return l
    }()

    // Центральная часть

    /// Иконка самолёта над линией прогресса.
    private let planeImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "airplane"))
        iv.tintColor = .skyPrimaryBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// Линия прогресса полёта между аэропортами.
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.trackTintColor = .skyTextSecondary.withAlphaComponent(0.2)
        pv.progressTintColor = .skyPrimaryBlue
        return pv
    }()

    /// Бейдж текущего статуса рейса.
    private let statusBadge = StatusBadgeView()

    // MARK: - Инициализация

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    // MARK: - Конфигурация

    /// Конфигурирует секцию данными о вылете, прилёте и прогрессе рейса.
    ///
    /// - Parameter flight: Рейс, данные которого выводятся в секции.
    func configure(with flight: Flight) {
        // Вылет
        departureCodeLabel.text = flight.departure.airport.iataCode
        departureNameLabel.text = flight.departure.airport.name
        departureTimeLabel.text = flight.departure.bestAvailableTime?.displayTime ?? "--:--"
        departureDelayLabel.text = flight.departure.delayDisplayString
        departureDelayLabel.isHidden = flight.departure.delay == nil

        if let terminal = flight.departure.terminal, let gate = flight.departure.gate {
            departureTerminalLabel.text = "T\(terminal) / Gate \(gate)"
        } else if let terminal = flight.departure.terminal {
            departureTerminalLabel.text = "Terminal \(terminal)"
        } else {
            departureTerminalLabel.text = nil
        }

        // Прилёт
        arrivalCodeLabel.text = flight.arrival.airport.iataCode
        arrivalNameLabel.text = flight.arrival.airport.name
        arrivalTimeLabel.text = flight.arrival.bestAvailableTime?.displayTime ?? "--:--"
        arrivalDelayLabel.text = flight.arrival.delayDisplayString
        arrivalDelayLabel.isHidden = flight.arrival.delay == nil

        if let terminal = flight.arrival.terminal, let gate = flight.arrival.gate {
            arrivalTerminalLabel.text = "T\(terminal) / Gate \(gate)"
        } else if let terminal = flight.arrival.terminal {
            arrivalTerminalLabel.text = "Terminal \(terminal)"
        } else {
            arrivalTerminalLabel.text = nil
        }

        // Прогресс и статус
        progressView.setProgress(Float(flight.flightProgress), animated: true)
        statusBadge.configure(with: flight.status)
    }

    // MARK: - Layout

    private func setupUI() {
        backgroundColor = .skyBackground
        layer.cornerRadius = Constants.Layout.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constants.Layout.cardShadowOpacity
        layer.shadowRadius = Constants.Layout.cardShadowRadius
        layer.shadowOffset = CGSize(width: 0, height: 2)

        [departureCodeLabel, departureNameLabel, departureTimeLabel,
         departureTerminalLabel, departureDelayLabel,
         arrivalCodeLabel, arrivalNameLabel, arrivalTimeLabel,
         arrivalTerminalLabel, arrivalDelayLabel,
         planeImageView, progressView, statusBadge].forEach { addSubview($0) }
    }

    private func setupConstraints() {
        let padding = Constants.Layout.defaultPadding

        // Вылет — левая колонка
        departureCodeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(padding)
        }
        departureNameLabel.snp.makeConstraints { make in
            make.top.equalTo(departureCodeLabel.snp.bottom).offset(2)
            make.leading.equalTo(departureCodeLabel)
            make.width.lessThanOrEqualTo(120)
        }
        departureTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(departureNameLabel.snp.bottom).offset(8)
            make.leading.equalTo(departureCodeLabel)
        }
        departureTerminalLabel.snp.makeConstraints { make in
            make.top.equalTo(departureTimeLabel.snp.bottom).offset(4)
            make.leading.equalTo(departureCodeLabel)
        }
        departureDelayLabel.snp.makeConstraints { make in
            make.top.equalTo(departureTerminalLabel.snp.bottom).offset(2)
            make.leading.equalTo(departureCodeLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(padding)
        }

        // Прилёт — правая колонка
        arrivalCodeLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(padding)
        }
        arrivalNameLabel.snp.makeConstraints { make in
            make.top.equalTo(arrivalCodeLabel.snp.bottom).offset(2)
            make.trailing.equalTo(arrivalCodeLabel)
            make.width.lessThanOrEqualTo(120)
        }
        arrivalTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(arrivalNameLabel.snp.bottom).offset(8)
            make.trailing.equalTo(arrivalCodeLabel)
        }
        arrivalTerminalLabel.snp.makeConstraints { make in
            make.top.equalTo(arrivalTimeLabel.snp.bottom).offset(4)
            make.trailing.equalTo(arrivalCodeLabel)
        }
        arrivalDelayLabel.snp.makeConstraints { make in
            make.top.equalTo(arrivalTerminalLabel.snp.bottom).offset(2)
            make.trailing.equalTo(arrivalCodeLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(padding)
        }

        // Центральная линия прогресса
        progressView.snp.makeConstraints { make in
            make.centerY.equalTo(departureCodeLabel)
            make.leading.equalTo(departureCodeLabel.snp.trailing).offset(12)
            make.trailing.equalTo(arrivalCodeLabel.snp.leading).offset(-12)
            make.height.equalTo(4)
        }

        planeImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(progressView.snp.top).offset(-4)
            make.width.height.equalTo(20)
        }

        statusBadge.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
    }
}
