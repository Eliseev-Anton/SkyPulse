import Foundation

/// Протокол для ячеек и view, конфигурируемых моделью данных.
/// Обеспечивает единообразный интерфейс для настройки UI-компонентов.
protocol Configurable {
    associatedtype Model

    /// Настроить view данными модели
    func configure(with model: Model)
}
