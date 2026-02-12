import UIKit
import SnapKit

/// Ячейка истории поиска с иконкой типа запроса.
final class SearchHistoryCell: BaseTableViewCell {

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .skyTextSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let queryLabel: UILabel = {
        let l = UILabel()
        l.font = .skyBody
        l.textColor = .skyTextPrimary
        return l
    }()

    private let typeLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .skyCaption
        l.textColor = .skyTextSecondary
        l.textAlignment = .right
        return l
    }()

    override func setupUI() {
        backgroundColor = .clear
        selectionStyle = .default
        [iconImageView, queryLabel, typeLabel, timeLabel].forEach {
            contentView.addSubview($0)
        }
    }

    override func setupConstraints() {
        let padding = Constants.Layout.defaultPadding

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        queryLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.top.equalToSuperview().inset(10)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
        }

        typeLabel.snp.makeConstraints { make in
            make.leading.equalTo(queryLabel)
            make.top.equalTo(queryLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().inset(10)
        }

        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(60)
        }
    }

    func configure(with query: SearchQuery) {
        queryLabel.text = query.text
        timeLabel.text = query.timestamp.relativeDescription

        // Иконка и подпись в зависимости от типа запроса
        switch query.type {
        case .flightNumber:
            iconImageView.image = UIImage(systemName: "airplane")
            typeLabel.text = NSLocalizedString("search.type.flight", comment: "")
        case .route:
            iconImageView.image = UIImage(systemName: "arrow.right")
            typeLabel.text = NSLocalizedString("search.type.route", comment: "")
        case .airport:
            iconImageView.image = UIImage(systemName: "building.2")
            typeLabel.text = NSLocalizedString("search.type.airport", comment: "")
        }
    }
}
