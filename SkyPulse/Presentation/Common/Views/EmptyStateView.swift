import UIKit
import SnapKit

/// View для пустого состояния (нет данных, нет результатов поиска).
///
/// Используется на экранах дашборда, избранного и поиска, чтобы
/// показывать понятное сообщение вместо пустого списка.
final class EmptyStateView: UIView {

    /// Иконка, иллюстрирующая пустое состояние.
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .skyTextSecondary
        return iv
    }()

    /// Заголовок пустого состояния.
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .skyHeadline
        l.textColor = .skyTextPrimary
        l.textAlignment = .center
        return l
    }()

    /// Дополнительное текстовое пояснение (может занимать несколько строк).
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .skyBody
        l.textColor = .skyTextSecondary
        l.textAlignment = .center
        l.numberOfLines = 0
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

    /// Настраивает содержимое empty state.
    ///
    /// - Parameters:
    ///   - image: Иконка, отображаемая над текстом (по умолчанию `airplane.circle`).
    ///   - title: Заголовок пустого состояния.
    ///   - subtitle: Дополнительное описание/подсказка.
    func configure(
        image: UIImage? = UIImage(systemName: "airplane.circle"),
        title: String,
        subtitle: String
    ) {
        imageView.image = image
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center

        addSubview(stack)

        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(64)
        }

        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Constants.Layout.largePadding)
        }
    }
}
