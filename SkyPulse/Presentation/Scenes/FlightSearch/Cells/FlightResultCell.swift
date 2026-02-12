import UIKit
import SnapKit

/// Ячейка результата поиска — компактная карточка рейса.
///
/// Показывает основные данные рейса в результатах поиска.
final class FlightResultCell: BaseTableViewCell {

    /// Вложенная карточка рейса.
    private let flightCardView = FlightCardView()

    override func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(flightCardView)
    }

    override func setupConstraints() {
        flightCardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// Конфигурирует ячейку данными рейса.
    ///
    /// - Parameter flight: Рейс для отображения.
    func configure(with flight: Flight) {
        flightCardView.configure(with: flight)
    }
}
