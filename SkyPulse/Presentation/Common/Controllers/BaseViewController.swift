import UIKit
import RxSwift

/// Базовый `UIViewController` с общей конфигурацией для всех экранов приложения.
///
/// Содержит стандартный `disposeBag` для Rx‑подписок, базовую настройку
/// внешнего вида и удобный метод показа ошибок.
class BaseViewController: UIViewController {

    /// Контейнер для управления жизненным циклом Rx‑подписок.
    let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    /// Вызывается после загрузки view в память.
    ///
    /// Настраивает цвет фона и параметры навигационной панели.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .skyBackground
        configureNavigationBar()
    }

    // MARK: - Навигация

    /// Настраивает внешний вид `UINavigationBar` для контроллеров.
    private func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .skyPrimaryBlue
    }

    // MARK: - Показ ошибок

    /// Показывает алерт с сообщением об ошибке и опциональной кнопкой «Повторить».
    ///
    /// - Parameters:
    ///   - message: Текст ошибки для отображения пользователю.
    ///   - retryAction: Необязательное замыкание, вызываемое при нажатии на кнопку «Повторить».
    func showError(_ message: String, retryAction: VoidClosure? = nil) {
        let alert = UIAlertController(
            title: NSLocalizedString("common.error", comment: ""),
            message: message,
            preferredStyle: .alert
        )

        if let retryAction = retryAction {
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("common.retry", comment: ""),
                style: .default
            ) { _ in retryAction() })
        }

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.ok", comment: ""),
            style: .cancel
        ))

        present(alert, animated: true)
    }
}
