import UIKit
import SnapKit

/// Полноэкранный оверлей загрузки с анимацией.
///
/// Затемняет текущий экран при помощи blur‑эффекта и показывает
/// индикатор активности и текст «Загрузка».
final class LoadingView: UIView {

    /// Полноэкранный blur‑эффект под спиннером.
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        return UIVisualEffectView(effect: blur)
    }()

    /// Индикатор активности в центре экрана.
    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.color = .skyPrimaryBlue
        return s
    }()

    /// Текстовое сообщение под индикатором.
    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .skyBody
        l.textColor = .skyTextSecondary
        l.text = NSLocalizedString("common.loading", comment: "")
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

    /// Показывает оверлей поверх указанного view.
    ///
    /// - Parameter view: View, в котором нужно отобразить индикатор.
    func show(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)
        alpha = 0
        spinner.startAnimating()
        fadeIn()
    }

    /// Скрывает оверлей с плавной анимацией и удаляет из супервью.
    func hide() {
        fadeOut { [weak self] in
            self?.spinner.stopAnimating()
            self?.removeFromSuperview()
        }
    }

    private func setupUI() {
        addSubview(blurView)
        addSubview(spinner)
        addSubview(messageLabel)

        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        spinner.snp.makeConstraints { $0.center.equalToSuperview() }
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(spinner.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
    }
}
