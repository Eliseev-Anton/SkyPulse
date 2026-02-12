import Foundation
import RxSwift
import RxRelay
@testable import SkyPulse

/// Мок сервиса проверки сетевого подключения.
final class MockReachabilityService: ReachabilityServiceProtocol {

    private let isReachableRelay: BehaviorRelay<Bool>

    var isReachableObservable: Observable<Bool> {
        isReachableRelay.asObservable()
    }

    var isReachable: Bool {
        isReachableRelay.value
    }

    init(isReachable: Bool = true) {
        self.isReachableRelay = BehaviorRelay(value: isReachable)
    }

    /// Изменить состояние сети в тесте
    func setReachable(_ reachable: Bool) {
        isReachableRelay.accept(reachable)
    }
}
