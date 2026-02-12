import UIKit

/// Базовая ячейка таблицы с автоматическим `reuseIdentifier`.
///
/// Упрощает регистрацию/переиспользование и предоставляет хуки `setupUI` и
/// `setupConstraints` для настройки интерфейса и лэйаута в подклассах.
class BaseTableViewCell: UITableViewCell {

    /// Идентификатор для регистрации и переиспользования — имя класса.
    static var reuseIdentifier: String {
        String(describing: self)
    }

    /// Базовый инициализатор, вызывающий методы конфигурации UI и constraints.
    ///
    /// - Parameters:
    ///   - style: Стиль ячейки.
    ///   - reuseIdentifier: Идентификатор переиспользования.
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    /// Переопределить в подклассе для добавления `subview` и базовой конфигурации.
    func setupUI() {}

    /// Переопределить в подклассе для настройки SnapKit‑constraints.
    func setupConstraints() {}
}
