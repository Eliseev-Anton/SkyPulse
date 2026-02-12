import UIKit
import SnapKit

/// Ячейка настроек с иконкой, заголовком, подзаголовком и опциональным переключателем.
final class SettingsOptionCell: BaseTableViewCell {

    private let iconContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 6
        v.backgroundColor = .skyPrimaryBlue.withAlphaComponent(0.1)
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .skyPrimaryBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .skyBody
        l.textColor = .skyTextPrimary
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        return l
    }()

    private let toggleSwitch: UISwitch = {
        let s = UISwitch()
        s.onTintColor = .skyPrimaryBlue
        s.isHidden = true
        return s
    }()

    private var toggleCallback: ((Bool) -> Void)?

    override func setupUI() {
        backgroundColor = .skyBackground
        selectionStyle = .default

        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(toggleSwitch)

        toggleSwitch.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    }

    override func setupConstraints() {
        let padding = Constants.Layout.defaultPadding

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.top.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualTo(toggleSwitch.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(12)
        }

        toggleSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
        }
    }

    func configure(
        with item: SettingsViewModel.SettingsItem,
        showToggle: Bool = false,
        toggleAction: ((Bool) -> Void)? = nil
    ) {
        iconImageView.image = UIImage(systemName: item.icon)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle == nil
        toggleSwitch.isHidden = !showToggle
        toggleCallback = toggleAction
        selectionStyle = showToggle ? .none : .default
    }

    @objc private func toggleChanged() {
        toggleCallback?(toggleSwitch.isOn)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        toggleSwitch.isHidden = true
        toggleCallback = nil
        subtitleLabel.isHidden = false
    }
}
