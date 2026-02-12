import UIKit
import SnapKit

/// Секция статуса рейса: live‑данные о высоте, скорости, направлении.
///
/// Показывает текущие значения телеметрии, если доступны `FlightLiveData`,
/// либо текст «нет данных» при отсутствии live‑информации.
final class FlightStatusSection: UIView {

    // MARK: - UI-элементы

    /// Заголовок секции.
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("detail.status.title", comment: "")
        l.font = .skySubheadlineBold
        l.textColor = .skyTextPrimary
        return l
    }()

    /// Строка с текущей высотой полёта.
    private let altitudeRow = InfoRowView(
        icon: "arrow.up.to.line",
        title: NSLocalizedString("detail.status.altitude", comment: "")
    )

    /// Строка с текущей скоростью.
    private let speedRow = InfoRowView(
        icon: "speedometer",
        title: NSLocalizedString("detail.status.speed", comment: "")
    )

    /// Строка с текущим курсом.
    private let headingRow = InfoRowView(
        icon: "safari",
        title: NSLocalizedString("detail.status.heading", comment: "")
    )

    /// Строка со скоростью набора/снижения.
    private let verticalRateRow = InfoRowView(
        icon: "arrow.up.arrow.down",
        title: NSLocalizedString("detail.status.verticalRate", comment: "")
    )

    /// Стек со всеми строками live‑показателей.
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()

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

    /// Конфигурирует секцию в соответствии с переданным рейсом.
    ///
    /// - Parameter flight: Рейс, для которого нужно отобразить live‑данные.
    func configure(with flight: Flight) {
        guard let live = flight.liveData else {
            altitudeRow.setValue("--")
            speedRow.setValue("--")
            headingRow.setValue("--")
            verticalRateRow.setValue("--")
            return
        }

        altitudeRow.setValue(live.altitudeFormatted)
        speedRow.setValue(live.speedFormatted)
        headingRow.setValue(String(format: "%.0f°", live.heading))

        let rate = live.verticalRate
        let sign = rate >= 0 ? "+" : ""
        verticalRateRow.setValue("\(sign)\(String(format: "%.0f", rate)) m/s")
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

        [altitudeRow, speedRow, headingRow, verticalRateRow].forEach {
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

// MARK: - InfoRowView (строка с иконкой, заголовком и значением)

/// Строка информации: название + значение (для секций деталей).
private final class InfoRowView: UIView {

    /// Текстовый заголовок параметра.
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .skyBody
        l.textColor = .skyTextSecondary
        return l
    }()

    /// Текстовое значение параметра.
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .skyBodyBold
        l.textColor = .skyTextPrimary
        l.textAlignment = .right
        return l
    }()

    /// Инициализирует строку с заголовком.
    ///
    /// - Parameters:
    ///   - icon: Не используется (оставлен для обратной совместимости).
    ///   - title: Локализованный заголовок параметра.
    init(icon: String, title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    /// Устанавливает текст значения параметра.
    ///
    /// - Parameter text: Значение для правого лейбла.
    func setValue(_ text: String) {
        valueLabel.text = text
    }

    private func setupUI() {
        [titleLabel, valueLabel].forEach { addSubview($0) }
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
    }
}
