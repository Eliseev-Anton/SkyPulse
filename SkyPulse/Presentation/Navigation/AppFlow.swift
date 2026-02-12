import UIKit
import RxFlow
import RxSwift

/// Корневой `Flow` приложения: последовательность экранов `splash → main`.
///
/// Отвечает за выбор стартового экрана, а также за плавный переход
/// от заставки к основному TabBar‑интерфейсу.
final class AppFlow: Flow {

    /// Корневой `Presentable`, которым управляет flow (главное окно приложения).
    var root: Presentable { rootWindow }

    /// Окно, в котором отображается UI приложения.
    private let rootWindow: UIWindow

    /// Контейнер зависимостей, передаваемый в дочерние flow и экраны.
    private let services: DIContainer

    /// Инициализирует корневой flow.
    ///
    /// - Parameters:
    ///   - window: Окно, в которое будет установлен корневой контроллер.
    ///   - services: Общий контейнер зависимостей приложения.
    init(window: UIWindow, services: DIContainer) {
        self.rootWindow = window
        self.services = services
    }

    /// Обрабатывает шаг навигации и возвращает соответствующие `FlowContributors`.
    ///
    /// - Parameter step: Текущий шаг навигации уровня приложения.
    /// - Returns: Набор вкладчиков в навигационный поток.
    func navigate(to step: Step) -> FlowContributors {
        guard let step = step as? AppStep else { return .none }

        switch step {
        case .splashIsRequired:
            return navigateToSplash()
        case .splashIsComplete, .dashboardIsRequired:
            return navigateToMain()
        }
    }

    // MARK: - Навигация

    /// Переходит на экран заставки (`SplashViewController`).
    ///
    /// - Returns: `FlowContributors` для `SplashViewController` и его степпера.
    private func navigateToSplash() -> FlowContributors {
        let viewModel = SplashViewModel()
        let viewController = SplashViewController(viewModel: viewModel)

        rootWindow.rootViewController = viewController
        UIView.transition(with: rootWindow, duration: 0.3, options: .transitionCrossDissolve, animations: nil)

        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }

    /// Переходит к основному потоку (`MainFlow`) с TabBar‑интерфейсом.
    ///
    /// - Returns: `FlowContributors` с `MainFlow` и стартовым шагом `dashboardIsRequired`.
    private func navigateToMain() -> FlowContributors {
        let mainFlow = MainFlow(services: services)

        Flows.use(mainFlow, when: .created) { [weak self] root in
            guard let self = self else { return }
            self.rootWindow.rootViewController = root
            UIView.transition(with: self.rootWindow, duration: 0.5, options: .transitionCrossDissolve, animations: nil)
        }

        return .one(flowContributor: .contribute(
            withNextPresentable: mainFlow,
            withNextStepper: OneStepper(withSingleStep: MainStep.dashboardIsRequired)
        ))
    }
}
