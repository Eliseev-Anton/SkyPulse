import UIKit
import SnapKit

/// Ячейка избранного рейса с карточкой.
///
/// Оборачивает `FlightCardView` в таблицу избранных рейсов.
final class FavoriteFlightCell: BaseTableViewCell {

    /// Вложенная карточка рейса.
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

    /// Конфигурирует ячейку данными рейса.
    ///
    /// - Parameter flight: Рейс, который нужно отобразить.
    func configure(with flight: Flight) {
        flightCardView.configure(with: flight)
    }
}
