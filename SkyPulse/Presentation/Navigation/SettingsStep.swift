import RxFlow

/// Шаги навигации во flow настроек.
enum SettingsStep: Step {
    case settingsIsRequired
    case clearCacheConfirmed
}
