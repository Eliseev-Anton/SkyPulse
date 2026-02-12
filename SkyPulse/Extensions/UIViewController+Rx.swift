import UIKit
import RxSwift
import RxCocoa

/// Реактивные расширения жизненного цикла ViewController.
extension Reactive where Base: UIViewController {

    /// Эмитится один раз при viewDidLoad
    var viewDidLoad: Observable<Void> {
        methodInvoked(#selector(UIViewController.viewDidLoad))
            .mapToVoid()
            .take(1)
    }

    /// Эмитится при каждом viewWillAppear
    var viewWillAppear: Observable<Bool> {
        methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
            .map { $0.first as? Bool ?? false }
    }

    /// Эмитится при каждом viewDidDisappear
    var viewDidDisappear: Observable<Bool> {
        methodInvoked(#selector(UIViewController.viewDidDisappear(_:)))
            .map { $0.first as? Bool ?? false }
    }
}
