import UIKit
import SnapKit

/// Кастомная карточка рейса — основной визуальный компонент приложения.
///
/// Отображает маршрут (аэропорт вылета → прилёта) с пунктирной линией,
/// иконкой самолёта, временем вылета/прилёта и статусом рейса.
final class FlightCardView: UIView {

    // MARK: - UI-элементы

    /// Контейнер с тенью и скруглёнными краями, в котором размещается содержимое карточки.
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .skyBackground
        v.layer.cornerRadius = Constants.Layout.cornerRadius
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = Constants.Layout.cardShadowOpacity
        v.layer.shadowRadius = Constants.Layout.cardShadowRadius
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    // Вылет

    /// Метка с IATA‑кодом аэропорта вылета.
    private let departureCodeLabel: UILabel = {
        let l = UILabel()
        l.font = .skyAirportCode
        l.textColor = .skyTextPrimary
        return l
    }()

    /// Метка с названием города вылета.
    private let departureCityLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        return l
    }()

    /// Метка с запланированным/оценочным временем вылета.
    private let departureTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .skySubheadline
        l.textColor = .skyTextPrimary
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

    /// Метка с названием города назначения.
    private let arrivalCityLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        l.textAlignment = .right
        return l
    }()

    /// Метка с запланированным/оценочным временем прилёта.
    private let arrivalTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .skySubheadline
        l.textColor = .skyTextPrimary
        l.textAlignment = .right
        return l
    }()

    // Центральная часть (маршрут)

    /// Представление маршрутной линии с иконкой самолёта.
    private let routeLineView = FlightRouteLineView()

    /// Метка с номером рейса (например, `SU100`).
    private let flightNumberLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaptionBold
        l.textColor = .skyPrimaryBlue
        l.textAlignment = .center
        return l
    }()

    /// Бейдж статуса рейса (on time, delayed, cancelled и т.п.).
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

    /// Конфигурирует карточку данными конкретного рейса.
    ///
    /// - Parameter flight: Рейс, информация о котором отображается в карточке.
    func configure(with flight: Flight) {
        departureCodeLabel.text = flight.departure.airport.iataCode
        departureCityLabel.text = flight.departure.airport.city
        departureTimeLabel.text = flight.departure.bestAvailableTime?.displayTime ?? "--:--"

        arrivalCodeLabel.text = flight.arrival.airport.iataCode
        arrivalCityLabel.text = flight.arrival.airport.city
        arrivalTimeLabel.text = flight.arrival.bestAvailableTime?.displayTime ?? "--:--"

        flightNumberLabel.text = flight.flightNumber
        statusBadge.configure(with: flight.status)
        routeLineView.setProgress(CGFloat(flight.flightProgress))

        accessibilityIdentifier = Constants.AccessibilityID.flightCard
    }

    // MARK: - Layout

    private func setupUI() {
        addSubview(containerView)
        [departureCodeLabel, departureCityLabel, departureTimeLabel,
         arrivalCodeLabel, arrivalCityLabel, arrivalTimeLabel,
         routeLineView, flightNumberLabel, statusBadge].forEach {
            containerView.addSubview($0)
        }
    }

    private func setupConstraints() {
        let padding = Constants.Layout.defaultPadding

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: padding, bottom: 6, right: padding))
        }

        // Вылет — левая колонка
        departureCodeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(padding)
        }
        departureCityLabel.snp.makeConstraints { make in
            make.top.equalTo(departureCodeLabel.snp.bottom).offset(2)
            make.leading.equalTo(departureCodeLabel)
        }
        departureTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(departureCityLabel.snp.bottom).offset(8)
            make.leading.equalTo(departureCodeLabel)
            make.bottom.equalToSuperview().inset(padding)
        }

        // Прилёт — правая колонка
        arrivalCodeLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(padding)
        }
        arrivalCityLabel.snp.makeConstraints { make in
            make.top.equalTo(arrivalCodeLabel.snp.bottom).offset(2)
            make.trailing.equalTo(arrivalCodeLabel)
        }
        arrivalTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(arrivalCityLabel.snp.bottom).offset(8)
            make.trailing.equalTo(arrivalCodeLabel)
        }

        // Центральная часть — линия маршрута
        routeLineView.snp.makeConstraints { make in
            make.centerY.equalTo(departureCodeLabel)
            make.leading.equalTo(departureCodeLabel.snp.trailing).offset(12)
            make.trailing.equalTo(arrivalCodeLabel.snp.leading).offset(-12)
            make.height.equalTo(24)
        }

        flightNumberLabel.snp.makeConstraints { make in
            make.top.equalTo(routeLineView.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
        }

        statusBadge.snp.makeConstraints { make in
            make.top.equalTo(flightNumberLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }
    }
}

// MARK: - FlightRouteLineView (пунктирная линия с самолётом)

/// Отрисовка маршрутной линии: пунктир с иконкой самолёта,
/// позиция которого отражает прогресс полёта.
private final class FlightRouteLineView: UIView {

    private let planeImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "airplane"))
        iv.tintColor = .skyPrimaryBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let dashedLayer = CAShapeLayer()
    private var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(dashedLayer)
        addSubview(planeImageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    func setProgress(_ progress: CGFloat) {
        self.progress = min(max(progress, 0), 1)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Пунктирная линия
        let path = UIBezierPath()
        let lineY = bounds.midY
        path.move(to: CGPoint(x: 0, y: lineY))
        path.addLine(to: CGPoint(x: bounds.width, y: lineY))

        dashedLayer.path = path.cgPath
        dashedLayer.strokeColor = UIColor.skyTextSecondary.withAlphaComponent(0.4).cgColor
        dashedLayer.lineWidth = 1.5
        dashedLayer.lineDashPattern = [4, 4]
        dashedLayer.fillColor = nil
        dashedLayer.frame = bounds

        // Позиция самолёта
        let planeSize: CGFloat = 18
        let planeX = bounds.width * progress - planeSize / 2
        planeImageView.frame = CGRect(x: planeX, y: lineY - planeSize / 2, width: planeSize, height: planeSize)
    }
}
