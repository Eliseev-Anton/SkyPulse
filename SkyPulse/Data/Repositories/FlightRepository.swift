import Foundation
import RxSwift

/// Реализация `FlightRepositoryProtocol`.
///
/// Координирует сетевые запросы к `AviationStackAPI` и `OpenSkyAPI`,
/// работу с кэшем в `RealmManager` и использование мок‑данных.
/// Стратегия: онлайн → API + запись в кэш; оффлайн → чтение из кэша,
/// при отсутствии данных — использование мок‑данных.
final class FlightRepository: FlightRepositoryProtocol {

    /// Клиент для работы с API `AviationStack` (поиск рейсов).
    private let aviationAPI: AviationStackAPI

    /// Клиент для работы с API `OpenSky` (live‑позиция самолётов).
    private let openSkyAPI: OpenSkyAPI

    /// Менеджер работы с локальной базой Realm.
    private let realmManager: RealmManager

    /// Сервис проверки сетевой доступности.
    private let reachability: ReachabilityServiceProtocol

    /// Провайдер мок‑данных для офлайн‑режима и UI‑тестов.
    private let mockProvider: MockDataProvider

    /// Кэш координат аэропортов, загруженных из AviationStack `/airports` API.
    private var airportCache: [String: Airport] = [:]
    private let airportCacheLock = NSLock()

    /// Инициализирует репозиторий всеми необходимыми зависимостями.
    ///
    /// - Parameters:
    ///   - aviationAPI: Клиент работы с API `AviationStack`.
    ///   - openSkyAPI: Клиент работы с API `OpenSky`.
    ///   - realmManager: Менеджер локальной базы Realm.
    ///   - reachability: Сервис проверки сети.
    ///   - mockProvider: Провайдер мок‑данных.
    init(
        aviationAPI: AviationStackAPI,
        openSkyAPI: OpenSkyAPI,
        realmManager: RealmManager,
        reachability: ReachabilityServiceProtocol,
        mockProvider: MockDataProvider
    ) {
        self.aviationAPI = aviationAPI
        self.openSkyAPI = openSkyAPI
        self.realmManager = realmManager
        self.reachability = reachability
        self.mockProvider = mockProvider
    }

    // MARK: - Callback-паттерн (@escaping)

    /// Загружает список рейсов с использованием callback‑паттерна.
    ///
    /// - Parameters:
    ///   - params: Параметры поиска рейсов.
    ///   - completion: Замыкание, в которое передаётся результат —
    ///     массив рейсов или ошибка `NetworkError`.
    func fetchFlights(
        params: FlightSearchParams,
        completion: @escaping (Result<[Flight], NetworkError>) -> Void
    ) {
        // Если включён mock‑режим — сразу возвращаем локальные тестовые данные.
        if AppConfiguration.useMockData {
            completion(.success(mockProvider.loadFlights()))
            return
        }

        // В офлайн‑режиме возвращаем данные из кэша или мок‑данные.
        guard reachability.isReachable else {
            let cached = realmManager.getCachedFlights(params: params)
            if cached.isEmpty {
                completion(.success(mockProvider.loadFlights()))
            } else {
                completion(.success(cached))
            }
            return
        }

        // Онлайн — запрос к API
        aviationAPI.fetchFlights(params: params) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let dtos):
                // Маппим DTO → доменные модели и сохраняем в кэш.
                let flights = dtos.compactMap { $0.toDomain() }
                self.realmManager.cacheFlights(flights)
                completion(.success(flights))
            case .failure(let error):
                // При ошибке API пробуем вернуть данные из кэша.
                let cached = self.realmManager.getCachedFlights(params: params)
                if cached.isEmpty {
                    completion(.failure(error))
                } else {
                    Logger.warning("API-ошибка, используем кэш (\(cached.count) рейсов)")
                    completion(.success(cached))
                }
            }
        }
    }

    // MARK: - Async/await-паттерн

    /// Асинхронно загружает список рейсов с использованием `async/await`.
    ///
    /// - Parameter params: Параметры поиска рейсов.
    /// - Returns: Массив найденных рейсов.
    /// - Throws: `NetworkError` при ошибке сети или декодирования.
    func fetchFlights(params: FlightSearchParams) async throws -> [Flight] {
        if AppConfiguration.useMockData {
            return mockProvider.loadFlights()
        }

        guard reachability.isReachable else {
            let cached = realmManager.getCachedFlights(params: params)
            return cached.isEmpty ? mockProvider.loadFlights() : cached
        }

        // Оборачиваем callback‑метод `AviationStackAPI` в async через `withCheckedThrowingContinuation`.
        return try await withCheckedThrowingContinuation { continuation in
            aviationAPI.fetchFlights(params: params) { [weak self] result in
                switch result {
                case .success(let dtos):
                    let flights = dtos.compactMap { $0.toDomain() }
                    self?.realmManager.cacheFlights(flights)
                    continuation.resume(returning: flights)
                case .failure(let error):
                    let cached = self?.realmManager.getCachedFlights(params: params) ?? []
                    if cached.isEmpty {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: cached)
                    }
                }
            }
        }
    }

    // MARK: - Реактивный паттерн (Rx)

    /// Наблюдает список рейсов по параметрам поиска в виде `Observable`.
    ///
    /// - Parameter params: Параметры поиска рейсов.
    /// - Returns: Observable, испускающий массив рейсов или ошибку `NetworkError`.
    func observeFlights(params: FlightSearchParams) -> Observable<[Flight]> {
        Observable.create { [weak self] observer in
            self?.fetchFlights(params: params) { result in
                switch result {
                case .success(let flights):
                    observer.onNext(flights)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    /// Возвращает детальную информацию о рейсе, комбинируя кэш и обновление из API.
    ///
    /// Координаты аэропортов дополнительно загружаются из AviationStack `/airports`,
    /// чтобы `TrackFlightUseCase` мог рассчитать позицию самолёта для активных рейсов.
    ///
    /// - Parameter id: Уникальный идентификатор рейса.
    /// - Returns: Observable, испускающий один или два экземпляра `Flight`
    ///   (сначала кэш, потом при наличии обновления из сети).
    func getFlightDetail(id: String) -> Observable<Flight> {
        Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            // Сначала отдаем данные из локального кэша, если они есть.
            if let cached = self.realmManager.getCachedFlight(id: id) {
                observer.onNext(cached)
            }

            // Затем пытаемся обновить детали рейса из API.
            let parts = id.split(separator: "-")
            guard let flightNumber = parts.first.map(String.init) else {
                observer.onCompleted()
                return Disposables.create()
            }

            let params = FlightSearchParams.byFlightNumber(flightNumber)
            self.fetchFlights(params: params) { [weak self] result in
                if case .success(let flights) = result,
                   let flight = flights.first(where: { $0.id == id }) {
                    // Обогащаем рейс координатами аэропортов из API
                    Task { [weak self] in
                        let enriched: Flight
                        if let self = self {
                            enriched = await self.enrichFlightWithAirportData(flight)
                        } else {
                            enriched = flight
                        }
                        observer.onNext(enriched)
                        observer.onCompleted()
                    }
                } else {
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    /// Получает live‑позицию рейса по ICAO24‑адресу самолёта.
    ///
    /// - Parameter icao24: ICAO24‑идентификатор самолёта.
    /// - Returns: Observable, испускающий `FlightLiveData?` (nil при ошибке).
    func getLivePosition(icao24: String) -> Observable<FlightLiveData?> {
        Observable.create { [weak self] observer in
            let task = Task {
                do {
                    let position = try await self?.openSkyAPI.fetchLiveState(icao24: icao24)
                    observer.onNext(position)
                    observer.onCompleted()
                } catch {
                    Logger.error("Ошибка получения позиции \(icao24)", error: error)
                    observer.onNext(nil)
                    observer.onCompleted()
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    // MARK: - Обогащение рейса координатами аэропортов (через API)

    /// Загружает координаты аэропортов вылета и прилёта из AviationStack `/airports`
    /// и подставляет их в объект рейса. Использует in‑memory кэш для экономии API‑квоты.
    private func enrichFlightWithAirportData(_ flight: Flight) async -> Flight {
        let depAirport = await resolveAirport(
            iata: flight.departure.airport.iataCode,
            fallback: flight.departure.airport
        )
        let arrAirport = await resolveAirport(
            iata: flight.arrival.airport.iataCode,
            fallback: flight.arrival.airport
        )

        // Если координаты не обновились — возвращаем без пересоздания
        guard depAirport.latitude != flight.departure.airport.latitude
                || depAirport.longitude != flight.departure.airport.longitude
                || arrAirport.latitude != flight.arrival.airport.latitude
                || arrAirport.longitude != flight.arrival.airport.longitude
        else {
            return flight
        }

        return Flight(
            id: flight.id,
            flightNumber: flight.flightNumber,
            airline: flight.airline,
            departure: FlightEndpoint(
                airport: depAirport,
                terminal: flight.departure.terminal,
                gate: flight.departure.gate,
                scheduledTime: flight.departure.scheduledTime,
                estimatedTime: flight.departure.estimatedTime,
                actualTime: flight.departure.actualTime,
                delay: flight.departure.delay
            ),
            arrival: FlightEndpoint(
                airport: arrAirport,
                terminal: flight.arrival.terminal,
                gate: flight.arrival.gate,
                scheduledTime: flight.arrival.scheduledTime,
                estimatedTime: flight.arrival.estimatedTime,
                actualTime: flight.arrival.actualTime,
                delay: flight.arrival.delay
            ),
            status: flight.status,
            aircraft: flight.aircraft,
            liveData: flight.liveData
        )
    }

    /// Разрешает аэропорт по IATA‑коду: сначала проверяет кэш, затем запрашивает API.
    private func resolveAirport(iata: String, fallback: Airport) async -> Airport {
        guard !iata.isEmpty else { return fallback }

        // Если координаты уже есть — не нужно ничего запрашивать
        if abs(fallback.latitude) > 0.001 || abs(fallback.longitude) > 0.001 {
            return fallback
        }

        // Проверяем in‑memory кэш
        airportCacheLock.lock()
        if let cached = airportCache[iata] {
            airportCacheLock.unlock()
            return cached
        }
        airportCacheLock.unlock()

        // Запрашиваем из AviationStack /airports
        do {
            let airports = try await aviationAPI.fetchAirports(query: iata)
            if let dto = airports.first(where: { $0.iataCode?.uppercased() == iata.uppercased() }),
               let airport = dto.toDomain(),
               abs(airport.latitude) > 0.001 || abs(airport.longitude) > 0.001 {
                airportCacheLock.lock()
                airportCache[iata] = airport
                airportCacheLock.unlock()
                return airport
            }
        } catch {
            Logger.error("Не удалось загрузить аэропорт \(iata) из API", error: error)
        }

        return fallback
    }
}
