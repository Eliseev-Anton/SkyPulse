import UIKit
import SnapKit

/// Цветной бейдж-индикатор статуса рейса (pill‑форма).
///
/// Показывает человекочитаемое название статуса и подбирает цветовую схему
/// в зависимости от значения `FlightStatus`.
final class StatusBadgeView: UIView {

    /// Текстовая метка с названием статуса рейса.
    private let label: UILabel = {
        let l = UILabel()
        l.font = .skyCaptionBold
        l.textColor = .white
        l.textAlignment = .center
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

    /// Настраивает бейдж для конкретного статуса рейса.
    ///
    /// - Parameter status: Статус рейса, для которого нужно отобразить бейдж.
    func configure(with status: FlightStatus) {
        label.text = status.displayName.uppercased()
        backgroundColor = UIColor.flightStatusColor(status)
    }

    private func setupUI() {
        layer.cornerRadius = 4
        clipsToBounds = true

        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }
    }
}
