import Foundation
import RxSwift
import RxFlow
import RxRelay

/// ViewModel для splash-экрана. Эмитирует переход на main после анимации.
final class SplashViewModel: Stepper {

    let steps = PublishRelay<Step>()
    private let disposeBag = DisposeBag()

    /// Запустить таймер перехода на главный экран
    func startTransitionTimer() {
        Observable<Int>
            .timer(
                .milliseconds(Int(AppConfiguration.splashAnimationDuration * 1000)),
                scheduler: MainScheduler.instance
            )
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.splashIsComplete)
            })
            .disposed(by: disposeBag)
    }
}
