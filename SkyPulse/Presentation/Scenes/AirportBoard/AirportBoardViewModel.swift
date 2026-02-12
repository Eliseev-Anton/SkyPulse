import Foundation
import RxSwift
import RxCocoa
import RxFlow
import RxRelay

/// ViewModel табло аэропорта: вылеты/прилёты с переключением сегмента.
final class AirportBoardViewModel: ViewModelType, Stepper {

    let steps = PublishRelay<Step>()

    struct Input {
        let viewDidLoad: Observable<Void>
        let segmentChanged: Observable<Int>
        let flightSelected: Observable<Flight>
        let refreshTrigger: Observable<Void>
    }

    struct Output {
        let flights: Driver<[Flight]>
        let boardType: Driver<AirportBoardView.BoardType>
        let airportName: Driver<String>
        let isLoading: Driver<Bool>
        let errorMessage: Driver<String?>
    }

    private let airportCode: String
    private let fetchAirportBoardUseCase: FetchAirportBoardUseCase
    private let disposeBag = DisposeBag()

    init(airportCode: String, fetchAirportBoardUseCase: FetchAirportBoardUseCase) {
        self.airportCode = airportCode
        self.fetchAirportBoardUseCase = fetchAirportBoardUseCase
    }

    func transform(input: Input) -> Output {
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = BehaviorRelay<String?>(value: nil)
        let boardType = BehaviorRelay<AirportBoardView.BoardType>(value: .departures)

        // Отслеживание типа табло
        input.segmentChanged
            .compactMap { AirportBoardView.BoardType(rawValue: $0) }
            .bind(to: boardType)
            .disposed(by: disposeBag)

        // Загрузка данных при viewDidLoad, смене сегмента или pull-to-refresh
        let loadTrigger = Observable.merge(
            input.viewDidLoad,
            input.segmentChanged.mapToVoid(),
            input.refreshTrigger
        )

        let flights = loadTrigger
            .withLatestFrom(boardType)
            .do(onNext: { _ in
                isLoading.accept(true)
                errorMessage.accept(nil)
            })
            .flatMapLatest { [weak self] type -> Observable<[Flight]> in
                guard let self = self else { return .just([]) }
                let request: Observable<[Flight]>
                switch type {
                case .departures:
                    request = self.fetchAirportBoardUseCase.fetchDepartures(airportCode: self.airportCode)
                case .arrivals:
                    request = self.fetchAirportBoardUseCase.fetchArrivals(airportCode: self.airportCode)
                }
                return request.catch { error in
                    errorMessage.accept(error.localizedDescription)
                    return .just([])
                }
            }
            .do(onNext: { _ in isLoading.accept(false) })
            .share(replay: 1)

        // Навигация: выбор рейса → детали
        input.flightSelected
            .subscribe(onNext: { [weak self] flight in
                self?.steps.accept(MainStep.flightDetailIsRequired(
                    flightId: flight.id,
                    icao24: flight.aircraft?.icao24
                ))
            })
            .disposed(by: disposeBag)

        return Output(
            flights: flights.asDriver(onErrorJustReturn: []),
            boardType: boardType.asDriver(),
            airportName: .just(airportCode),
            isLoading: isLoading.asDriver(),
            errorMessage: errorMessage.asDriver()
        )
    }
}
