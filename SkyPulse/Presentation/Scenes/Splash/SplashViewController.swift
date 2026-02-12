import UIKit
import SnapKit

/// Splash-экран с анимацией полёта самолёта и появления логотипа.
final class SplashViewController: UIViewController {

    private let viewModel: SplashViewModel

    // MARK: - UI-элементы

    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text = "SkyPulse"
        l.font = .systemFont(ofSize: 36, weight: .bold)
        l.textColor = .skyPrimaryBlue
        l.alpha = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Flight Tracker"
        l.font = .skySubheadline
        l.textColor = .skyTextSecondary
        l.alpha = 0
        return l
    }()

    private let planeImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "airplane"))
        iv.tintColor = .skyPrimaryBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // MARK: - Инициализация

    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .skyBackground
        setupUI()
        setupConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runSplashAnimation()
        viewModel.startTransitionTimer()
    }

    // MARK: - Анимация

    /// Анимация splash: самолёт летит по дуге + логотип появляется
    private func runSplashAnimation() {
        // Начальная позиция самолёта — за левым краем экрана
        planeImageView.center = CGPoint(x: -50, y: view.center.y - 60)

        // Анимация полёта по дуге (CAKeyframeAnimation)
        let flightPath = UIBezierPath()
        flightPath.move(to: CGPoint(x: -50, y: view.center.y - 60))
        flightPath.addCurve(
            to: CGPoint(x: view.bounds.width + 50, y: view.center.y - 100),
            controlPoint1: CGPoint(x: view.bounds.width * 0.3, y: view.center.y - 150),
            controlPoint2: CGPoint(x: view.bounds.width * 0.7, y: view.center.y - 40)
        )

        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        pathAnimation.path = flightPath.cgPath
        pathAnimation.duration = 1.8
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pathAnimation.fillMode = .forwards
        pathAnimation.isRemovedOnCompletion = false

        planeImageView.layer.add(pathAnimation, forKey: "flightPath")

        // Появление логотипа с задержкой
        UIView.animate(withDuration: 0.6, delay: 0.8, options: .curveEaseOut) {
            self.logoLabel.alpha = 1
            self.logoLabel.transform = .identity
        }

        UIView.animate(withDuration: 0.6, delay: 1.1, options: .curveEaseOut) {
            self.subtitleLabel.alpha = 1
        }
    }

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(planeImageView)
        view.addSubview(logoLabel)
        view.addSubview(subtitleLabel)

        // Начальное состояние логотипа — смещён вниз
        logoLabel.transform = CGAffineTransform(translationX: 0, y: 20)
    }

    private func setupConstraints() {
        planeImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }

        logoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoLabel.snp.bottom).offset(8)
        }
    }
}
