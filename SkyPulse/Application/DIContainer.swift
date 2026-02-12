import Foundation

/// Контейнер зависимостей приложения (Dependency Injection).
///
/// Хранит и лениво инициализирует все основные сервисы, репозитории и use case-ы.
/// Используется как Service Locator для инъекции зависимостей в `Flow`, `ViewModel`
/// и другие слои презентации.
final class DIContainer {

    /// Глобально доступный синглтон контейнера зависимостей.
    static let shared = DIContainer()

    // MARK: - Сервисы

    /// Синхронный сетевой сервис для выполнения HTTP‑запросов.
    lazy var networkService: NetworkServiceProtocol = NetworkService()

    /// Асинхронный сетевой сервис на базе `async/await`.
    lazy var asyncNetworkService: AsyncNetworkServiceProtocol = AsyncNetworkService()

    /// Менеджер работы с локальной базой данных Realm.
    lazy var realmManager: RealmManager = .shared

    /// Сервис мониторинга сетевой доступности.
    lazy var reachabilityService: ReachabilityServiceProtocol = ReachabilityService()

    /// Провайдер мок‑данных, используемый в офлайн‑режиме и UI‑тестах.
    lazy var mockDataProvider: MockDataProvider = .shared

    // MARK: - API-клиенты

    /// Клиент для работы с API `AviationStack`.
    ///
    /// - Returns: Экземпляр `AviationStackAPI`, сконфигурированный с актуальным API‑ключом.
    lazy var aviationStackAPI: AviationStackAPI = {
        // Пытаемся получить API‑ключ из Keychain, при отсутствии используем дефолтный.
        let apiKey = KeychainService.shared.retrieve(
            key: AppConfiguration.aviationStackAPIKeyIdentifier
        ) ?? AppConfiguration.defaultAviationStackAPIKey

        return AviationStackAPI(
            // Сервис для обычных HTTP‑запросов.
            networkService: networkService,
            // Сервис для асинхронных запросов.
            asyncService: asyncNetworkService,
            // Ключ авторизации для AviationStack.
            apiKey: apiKey
        )
    }()

    /// Клиент для работы с API `OpenSky` (онлайн‑позиция самолётов).
    lazy var openSkyAPI: OpenSkyAPI = OpenSkyAPI(asyncService: asyncNetworkService)

    // MARK: - Репозитории

    /// Репозиторий рейсов, объединяющий данные из AviationStack, OpenSky и локального кэша.
    lazy var flightRepository: FlightRepositoryProtocol = FlightRepository(
        // Клиент для поиска рейсов и расписаний.
        aviationAPI: aviationStackAPI,
        // Клиент для получения живой позиции самолётов.
        openSkyAPI: openSkyAPI,
        // Менеджер локальной базы данных.
        realmManager: realmManager,
        // Сервис проверки доступности сети.
        reachability: reachabilityService,
        // Провайдер мок‑данных для офлайн‑режима.
        mockProvider: mockDataProvider
    )

    /// Репозиторий аэропортов с поддержкой кэширования и офлайн‑режима.
    lazy var airportRepository: AirportRepositoryProtocol = AirportRepository(
        aviationAPI: aviationStackAPI,
        realmManager: realmManager,
        reachability: reachabilityService,
        mockProvider: mockDataProvider
    )

    /// Репозиторий избранных рейсов, основанный на локальной базе Realm.
    lazy var favoritesRepository: FavoritesRepositoryProtocol = FavoritesRepository(
        realmManager: realmManager,
        flightRepository: flightRepository
    )

    // MARK: - Фабрики Use Cases

    /// Создаёт use case для получения списка рейсов по параметрам.
    ///
    /// - Returns: Экземпляр `FetchFlightsUseCase` с внедрёнными репозиторием и reachability.
    func makeFetchFlightsUseCase() -> FetchFlightsUseCase {
        FetchFlightsUseCase(flightRepository: flightRepository, reachability: reachabilityService)
    }

    /// Создаёт use case для поиска рейсов и управления историей поиска.
    ///
    /// - Returns: Экземпляр `SearchFlightsUseCase`.
    func makeSearchFlightsUseCase() -> SearchFlightsUseCase {
        SearchFlightsUseCase(flightRepository: flightRepository, realmManager: realmManager)
    }

    /// Создаёт use case для отслеживания конкретного рейса.
    ///
    /// - Returns: Экземпляр `TrackFlightUseCase`.
    func makeTrackFlightUseCase() -> TrackFlightUseCase {
        TrackFlightUseCase(flightRepository: flightRepository)
    }

    /// Создаёт use case для управления списком избранных рейсов.
    ///
    /// - Returns: Экземпляр `ManageFavoritesUseCase`.
    func makeManageFavoritesUseCase() -> ManageFavoritesUseCase {
        ManageFavoritesUseCase(favoritesRepository: favoritesRepository)
    }

    /// Создаёт use case для загрузки табло вылетов и прилётов конкретного аэропорта.
    ///
    /// - Returns: Экземпляр `FetchAirportBoardUseCase`.
    func makeFetchAirportBoardUseCase() -> FetchAirportBoardUseCase {
        FetchAirportBoardUseCase(airportRepository: airportRepository)
    }
}
