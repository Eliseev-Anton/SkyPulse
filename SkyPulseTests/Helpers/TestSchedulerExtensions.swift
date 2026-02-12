import Foundation
import RxTest
import RxSwift

/// Вспомогательные расширения для тестового планировщика RxTest.
extension TestScheduler {

    /// Создаёт hot Observable с единственным событием .next
    func just<T>(_ element: T, at time: TestTime = 210) -> Observable<T> {
        createHotObservable([.next(time, element)]).asObservable()
    }
}
