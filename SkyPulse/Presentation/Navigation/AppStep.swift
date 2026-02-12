import RxFlow
import RxRelay

/// Шаги навигации на уровне приложения (`splash → main`).
///
/// Используются `AppFlow` и `AppStepper` для описания маршрута запуска.
enum AppStep: Step {
    /// Показать экран заставки.
    case splashIsRequired
    /// Завершить показ заставки.
    case splashIsComplete
    /// Показать основной экран (`Dashboard`).
    case dashboardIsRequired
}

/// Начальный степпер приложения — инициирует показ splash-экрана.
final class AppStepper: Stepper {
    /// Поток шагов навигации, публикуемых степпером.
    let steps = PublishRelay<Step>()

    /// Стартовый шаг при запуске приложения.
    var initialStep: Step { AppStep.splashIsRequired }
}
