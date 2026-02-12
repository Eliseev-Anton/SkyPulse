import Foundation
import RxSwift

/// Реализация `AirportRepositoryProtocol`.
///
/// Предоставляет методы для получения вылетов/прилётов и поиска аэропортов.
/// Использует как callback‑, так и `async/await`‑подходы для работы с API.
final class AirportRepository: AirportRepositoryProtocol {

    /// Клиент для работы с API `AviationStack`.
    private let aviationAPI: AviationStackAPI

    /// Менеджер доступа к данным в локальной базе Realm.
    private let realmManager: RealmManager

    /// Сервис, отслеживающий текущее состояние сети.
    private let reachability: ReachabilityServiceProtocol

    /// Провайдер мок‑данных на случай офлайн‑режима или тестов.
    private let mockProvider: MockDataProvider

    /// Создаёт репозиторий аэропортов.
    ///
    /// - Parameters:
    ///   - aviationAPI: Клиент `AviationStack` для запросов об аэропортах и рейсах.
    ///   - realmManager: Менеджер базы данных Realm.
    ///   - reachability: Сервис проверки сети.
    ///   - mockProvider: Провайдер мок‑данных.
    init(
        aviationAPI: AviationStackAPI,
        realmManager: RealmManager,
        reachability: ReachabilityServiceProtocol,
        mockProvider: MockDataProvider
    ) {
        self.aviationAPI = aviationAPI
        self.realmManager = realmManager
        self.reachability = reachability
        self.mockProvider = mockProvider
    }

    /// Возвращает вылеты из указанного аэропорта.
    ///
    /// - Parameter airportCode: IATA‑код аэропорта (например, `"SVO"`).
    /// - Returns: Observable с массивом рейсов, отсортированных по времени вылета.
    func fetchDepartures(airportCode: String) -> Observable<[Flight]> {
        Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let params = FlightSearchParams(
                flightNumber: nil, departureIata: airportCode,
                arrivalIata: nil, airlineIata: nil,
                flightDate: Date(), status: nil
            )

            // В офлайн‑режиме используем кэш или мок‑данные.
            if !self.reachability.isReachable || AppConfiguration.useMockData {
                let flights = AppConfiguration.useMockData
                    ? self.mockProvider.loadFlights().filter { $0.departure.airport.iataCode == airportCode }
                    : self.realmManager.getCachedFlights(params: params)
                observer.onNext(flights)
                observer.onCompleted()
                return Disposables.create()
            }

            self.aviationAPI.fetchFlights(params: params) { result in
                switch result {
                case .success(let dtos):
                    let flights = dtos.compactMap { $0.toDomain() }
                    observer.onNext(flights)
                case .failure:
                    observer.onNext(self.realmManager.getCachedFlights(params: params))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    /// Возвращает прилёты в указанный аэропорт.
    ///
    /// - Parameter airportCode: IATA‑код аэропорта назначения.
    /// - Returns: Observable с массивом рейсов.
    func fetchArrivals(airportCode: String) -> Observable<[Flight]> {
        Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let params = FlightSearchParams(
                flightNumber: nil, departureIata: nil,
                arrivalIata: airportCode, airlineIata: nil,
                flightDate: Date(), status: nil
            )

            // В офлайн‑режиме используем локальный кэш или мок‑данные.
            if !self.reachability.isReachable || AppConfiguration.useMockData {
                let flights = AppConfiguration.useMockData
                    ? self.mockProvider.loadFlights().filter { $0.arrival.airport.iataCode == airportCode }
                    : self.realmManager.getCachedFlights(params: params)
                observer.onNext(flights)
                observer.onCompleted()
                return Disposables.create()
            }

            self.aviationAPI.fetchFlights(params: params) { result in
                switch result {
                case .success(let dtos):
                    observer.onNext(dtos.compactMap { $0.toDomain() })
                case .failure:
                    observer.onNext(self.realmManager.getCachedFlights(params: params))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    /// Ищет аэропорты по строке запроса (IATA‑код, название или город).
    ///
    /// - Parameter query: Часть кода или названия аэропорта.
    /// - Returns: Observable с найденными аэропортами из кэша и/или API.
    func searchAirports(query: String) -> Observable<[Airport]> {
        Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            // Сначала отдаём результаты из кэша, если они есть.
            let cached = self.realmManager.getCachedAirports(query: query)
            if !cached.isEmpty {
                observer.onNext(cached)
            }

            // Если сеть недоступна или включён мок‑режим, пытаемся подобрать данные локально.
            guard self.reachability.isReachable, !AppConfiguration.useMockData else {
                if cached.isEmpty {
                    let mocked = self.mockProvider.loadAirports().filter {
                        $0.iataCode.localizedCaseInsensitiveContains(query) ||
                        $0.name.localizedCaseInsensitiveContains(query) ||
                        $0.city.localizedCaseInsensitiveContains(query)
                    }
                    observer.onNext(mocked)
                }
                observer.onCompleted()
                return Disposables.create()
            }

            let task = Task {
                do {
                    // Ищем аэропорты в API и кэшируем результат.
                    let dtos = try await self.aviationAPI.fetchAirports(query: query)
                    let airports = dtos.compactMap { $0.toDomain() }
                    self.realmManager.cacheAirports(airports)
                    observer.onNext(airports)
                } catch {
                    Logger.error("Ошибка поиска аэропортов", error: error)
                }
                observer.onCompleted()
            }

            return Disposables.create { task.cancel() }
        }
    }

    /// Возвращает конкретный аэропорт по IATA‑коду.
    ///
    /// - Parameter code: IATA‑код аэропорта (например, `"JFK"`).
    /// - Returns: Найденный аэропорт или `Airport.placeholder`, если ничего не найдено.
    func getAirport(byIataCode code: String) async throws -> Airport {
        // Сначала пробуем получить аэропорт из кэша.
        let cached = realmManager.getCachedAirports(query: code)
        if let found = cached.first(where: { $0.iataCode == code }) {
            return found
        }

        // При отсутствии в кэше — запрашиваем в API и кэшируем.
        let dtos = try await aviationAPI.fetchAirports(query: code)
        let airports = dtos.compactMap { $0.toDomain() }
        realmManager.cacheAirports(airports)

        return airports.first(where: { $0.iataCode == code }) ?? Airport.placeholder
    }
}
