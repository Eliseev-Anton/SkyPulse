import Foundation

/// Централизованная конфигурация приложения.
///
/// Содержит константы для работы с сетью, кэшированием, анимациями и feature-флагами.
/// Секретные значения (API‑ключи) фактически хранятся в `KeychainService`,
/// здесь определяются только идентификаторы и значения по умолчанию для первого запуска.
enum AppConfiguration {

    // MARK: - Базовые URL API

    /// Базовый URL публичного API `AviationStack` для поиска рейсов и аэропортов.
    static let aviationStackBaseURL = "https://api.aviationstack.com/v1"

    /// Базовый URL API `OpenSky` для получения онлайн‑позиции самолётов.
    static let openSkyBaseURL = "https://opensky-network.org/api"

    // MARK: - Идентификаторы Keychain

    /// Идентификатор записи в Keychain, под которым хранится ключ `AviationStack`.
    static let aviationStackAPIKeyIdentifier = "com.skypulse.aviationstack.apikey"

    /// Дефолтное значение ключа `AviationStack`, используемое при первом запуске.
    ///
    /// При старте приложения значение переносится в Keychain, а далее читается только оттуда.
    static let defaultAviationStackAPIKey = "62d724b46db004ba8fcb5df2120c0765"

    // MARK: - Таймауты

    /// Таймаут ожидания ответа от сервера для обычных сетевых запросов (в секундах).
    static let networkTimeoutInterval: TimeInterval = 30

    /// Максимальное время жизни сетевого ресурса (в секундах), после которого запрос прерывается.
    static let networkResourceTimeout: TimeInterval = 60

    // MARK: - Кэширование

    /// Количество часов, в течение которых данные о рейсах считаются актуальными в кэше.
    static let flightCacheExpirationHours: Int = 24

    /// Количество часов, в течение которых данные об аэропортах считаются актуальными в кэше.
    /// Эквивалентно одной неделе.
    static let airportCacheExpirationHours: Int = 168

    /// Максимальное количество записей в истории поиска рейсов.
    static let maxSearchHistoryEntries: Int = 20

    // MARK: - Feature Flags

    /// Флаг использования мок‑данных вместо реальных сетевых запросов.
    ///
    /// Включается при наличии аргумента командной строки `--use-mock-data`,
    /// как правило, в UI‑тестах или при офлайн‑разработке.
    static let useMockData: Bool = {
        CommandLine.arguments.contains("--use-mock-data")
    }()

    /// Флаг, указывающий, что приложение запущено в режиме UI‑тестирования.
    ///
    /// Используется для отключения анимаций, уведомлений и других нефункциональных эффектов.
    static let isUITesting: Bool = {
        CommandLine.arguments.contains("--uitesting")
    }()

    // MARK: - Интервалы опроса

    /// Интервал (в секундах) опроса статуса отслеживаемых рейсов в `FlightMonitorService`.
    static let flightMonitorPollingInterval: TimeInterval = 60

    /// Интервал (в секундах) обновления живого положения самолёта на карте.
    static let livePositionUpdateInterval: TimeInterval = 10

    // MARK: - Анимации

    /// Длительность анимации заставки при старте приложения.
    static let splashAnimationDuration: TimeInterval = 2.5

    /// Длительность анимации переворота табло аэропорта.
    static let boardFlipAnimationDuration: TimeInterval = 0.3

    /// Коэффициент демпфирования пружинных анимаций карточек рейсов.
    static let cardSpringDamping: CGFloat = 0.75
}
