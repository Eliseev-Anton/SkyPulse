import UIKit
import RxSwift
import RxFlow

/// Делегат сцены, отвечающий за создание окна и запуск корневого навигационного `Flow`.
///
/// Использует `RxFlow` для декларативной навигации и хранит `FlowCoordinator`,
/// который управляет переходами между экранами.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// Главное окно приложения, связанное с текущей сценой.
    var window: UIWindow?

    /// Координатор `RxFlow`, управляющий переходами между `Flow` и `Step`.
    private var coordinator = FlowCoordinator()

    /// Контейнер для управления жизненным циклом Rx‑подписок делегата сцены.
    private let disposeBag = DisposeBag()

    /// Вызывается при создании сцены и связывает её с оконной иерархией.
    ///
    /// - Parameters:
    ///   - scene: Объект сцены, предоставленный системой.
    ///   - session: Сессия сцены, ассоциированная с окном.
    ///   - connectionOptions: Опции подключения сцены (universal links, уведомления и т.п.).
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Создаём и привязываем окно к сцене.
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Стартуем корневой `AppFlow` и настраиваем корневой контроллер навигации.
        coordinateToAppFlow(with: window)

        window.makeKeyAndVisible()
    }

    // MARK: - Инициализация RxFlow навигации

    /// Запускает корневой `AppFlow` и подписывается на события навигации.
    ///
    /// - Parameter window: Окно, которое будет использоваться в качестве контейнера
    ///   для корневого контроллера навигации.
    private func coordinateToAppFlow(with window: UIWindow) {
        let appFlow = AppFlow(window: window, services: DIContainer.shared)

        coordinator.coordinate(flow: appFlow, with: AppStepper())

        coordinator.rx.willNavigate
            .subscribe(onNext: { flow, step in
                // Логируем каждый шаг навигации для упрощения отладки переходов.
                Logger.debug("Навигация: flow=\(flow) step=\(step)")
            })
            .disposed(by: disposeBag)
    }
}
