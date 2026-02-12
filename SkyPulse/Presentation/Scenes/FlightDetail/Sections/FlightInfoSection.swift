import UIKit
import SnapKit

/// Секция общей информации о рейсе: авиакомпания, самолёт, дата.
///
/// Отображает основные атрибуты рейса, которые не относятся к маршруту или live‑данным.
final class FlightInfoSection: UIView {

    // MARK: - UI-элементы

    /// Заголовок секции.
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("detail.info.title", comment: "")
        l.font = .skySubheadlineBold
        l.textColor = .skyTextPrimary
        return l
    }()

    /// Стек строк с информацией о рейсе.
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 10
        return sv
    }()

    /// Строка с названием авиакомпании.
    private let airlineRow = DetailInfoRow()
    /// Строка с номером рейса.
    private let flightNumberRow = DetailInfoRow()
    /// Строка с моделью самолёта.
    private let aircraftRow = DetailInfoRow()
    /// Строка с датой вылета.
    private let dateRow = DetailInfoRow()
    /// Строка с бортовым номером (регистрацией).
    private let registrationRow = DetailInfoRow()

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

    /// Конфигурирует секцию данными конкретного рейса.
    ///
    /// - Parameter flight: Рейс, информация о котором должна быть показана.
    func configure(with flight: Flight) {
        airlineRow.configure(
            title: NSLocalizedString("detail.info.airline", comment: ""),
            value: flight.airline.name
        )

        flightNumberRow.configure(
            title: NSLocalizedString("detail.info.flightNumber", comment: ""),
            value: flight.flightNumber
        )

        if let model = flight.aircraft?.model {
            aircraftRow.configure(
                title: NSLocalizedString("detail.info.aircraft", comment: ""),
                value: model
            )
            aircraftRow.isHidden = false
        } else {
            aircraftRow.isHidden = true
        }

        if let reg = flight.aircraft?.registration {
            registrationRow.configure(
                title: NSLocalizedString("detail.info.registration", comment: ""),
                value: reg
            )
            registrationRow.isHidden = false
        } else {
            registrationRow.isHidden = true
        }

        if let date = flight.departure.scheduledTime {
            dateRow.configure(
                title: NSLocalizedString("detail.info.date", comment: ""),
                value: date.displayDate
            )
        }
    }

    // MARK: - Layout

    private func setupUI() {
        backgroundColor = .skyBackground
        layer.cornerRadius = Constants.Layout.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constants.Layout.cardShadowOpacity
        layer.shadowRadius = Constants.Layout.cardShadowRadius
        layer.shadowOffset = CGSize(width: 0, height: 2)

        addSubview(titleLabel)
        addSubview(stackView)

        [airlineRow, flightNumberRow, aircraftRow, registrationRow, dateRow].forEach {
            stackView.addArrangedSubview($0)
        }
    }

    private func setupConstraints() {
        let padding = Constants.Layout.defaultPadding

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(padding)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(padding)
        }
    }
}

// MARK: - DetailInfoRow (строка заголовок + значение)

/// Простая строка с заголовком и значением для секции информации.
private final class DetailInfoRow: UIView {

    /// Лейбл заголовка строки.
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        return l
    }()

    /// Лейбл значения строки.
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .skyBody
        l.textColor = .skyTextPrimary
        l.textAlignment = .right
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    /// Настраивает строку заголовком и значением.
    ///
    /// - Parameters:
    ///   - title: Заголовок параметра.
    ///   - value: Значение параметра.
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }

    private func setupUI() {
        [titleLabel, valueLabel].forEach { addSubview($0) }

        titleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
    }
}
