import Foundation

/// Базовый протокол для всех ViewModel в MVVM-архитектуре.
///
/// Каждый ViewModel определяет свои типы `Input` и `Output`:
/// - `Input` — события от UI (нажатия кнопок, ввод текста, pull-to-refresh)
/// - `Output` — данные для отображения (Driver/Observable для биндинга в VC)
///
/// Пример использования:
/// ```
/// final class DashboardViewModel: ViewModelType {
///     struct Input {
///         let viewDidLoad: Observable<Void>
///         let pullToRefresh: Observable<Void>
///     }
///     struct Output {
///         let flights: Driver<[Flight]>
///         let isLoading: Driver<Bool>
///     }
///     func transform(input: Input) -> Output { ... }
/// }
/// ```
protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}
