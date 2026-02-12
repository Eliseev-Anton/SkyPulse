import Foundation
import RxSwift
import RxCocoa

/// Вспомогательные операторы для RxSwift.
extension ObservableType {

    /// Преобразовать в Void (для событий без payload)
    func mapToVoid() -> Observable<Void> {
        map { _ in }
    }
}

/// Разворачивание Optional из Observable
extension ObservableType where Element: OptionalType {

    /// Пропускает nil-значения и разворачивает Optional
    func unwrap() -> Observable<Element.Wrapped> {
        compactMap { $0.optionalValue }
    }
}

/// Протокол для поддержки generic unwrap
protocol OptionalType {
    associatedtype Wrapped
    var optionalValue: Wrapped? { get }
}

extension Optional: OptionalType {
    var optionalValue: Wrapped? { self }
}
