import UIKit
import SnapKit

/// Ячейка таблицы Dashboard, оборачивающая FlightCardView.
final class ActiveFlightCell: BaseTableViewCell {

    private let flightCardView = FlightCardView()

    override func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(flightCardView)
    }

    override func setupConstraints() {
        flightCardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with flight: Flight) {
        flightCardView.configure(with: flight)

        // Spring-анимация появления карточки
        flightCardView.alpha = 0
        flightCardView.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: AppConfiguration.cardSpringDamping,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.flightCardView.alpha = 1
            self.flightCardView.transform = .identity
        }
    }
}
