import Foundation

/// Корневой DTO ответа AviationStack API на запрос `/flights`.
///
/// AviationStack всегда возвращает HTTP 200, независимо от результата.
/// При успехе приходят поля `pagination` и `data`; при ошибке — только `error`.
/// Все поля опциональны, чтобы декодер не падал ни в том ни в другом случае.
struct ASFlightResponse: Decodable {
    /// Метаданные страницы: лимит, смещение и общее число записей.
    let pagination: ASPagination?
    /// Массив рейсов, соответствующих параметрам запроса.
    let data: [ASFlightDTO]?
    /// Описание ошибки API. Присутствует, если запрос завершился неудачно.
    let error: ASAPIError?
}

/// Метаданные постраничной навигации в ответе AviationStack.
///
/// Позволяют реализовать подгрузку следующих страниц через параметры `limit` и `offset`.
struct ASPagination: Decodable {
    /// Максимальное количество записей на одной странице (по умолчанию 100).
    let limit: Int
    /// Смещение от начала результирующей выборки (для постраничной навигации).
    let offset: Int
    /// Количество записей, фактически возвращённых в текущем ответе.
    let count: Int
    /// Общее число записей, соответствующих запросу (без учёта пагинации).
    let total: Int
}

/// Описание ошибки, которую возвращает AviationStack при неудачном запросе.
///
/// Пример JSON: `{"error": {"code": 101, "type": "invalid_access_key", "info": "..."}}`
///
/// Коды ошибок:
/// - `101` / `102` — невалидный или отсутствующий API-ключ → маппируется в `.unauthorized`
/// - `104` — исчерпан лимит запросов тарифного плана → маппируется в `.rateLimited`
/// - прочие — серверная ошибка → маппируется в `.serverError(statusCode:)`
struct ASAPIError: Decodable {
    /// Числовой код ошибки AviationStack (например, 101, 104).
    let code: Int?
    /// Машиночитаемый тип ошибки (например, `"invalid_access_key"`).
    let type: String?
    /// Человекочитаемое описание ошибки на английском языке.
    let info: String?
}

/// DTO одного рейса из ответа AviationStack.
///
/// Объединяет всю информацию о конкретном рейсе: маршрут, авиакомпанию,
/// воздушное судно и live-данные о позиции. Все поля опциональны —
/// API не гарантирует наличие каждого из них для любого рейса.
struct ASFlightDTO: Decodable {
    /// Дата выполнения рейса в формате `yyyy-MM-dd` (например, `"2026-02-11"`).
    let flightDate: String?
    /// Текущий статус рейса в виде строки (например, `"active"`, `"landed"`, `"scheduled"`).
    let flightStatus: String?
    /// Данные о точке вылета (аэропорт, терминал, время).
    let departure: ASEndpointDTO?
    /// Данные о точке прилёта (аэропорт, терминал, время).
    let arrival: ASEndpointDTO?
    /// Информация об авиакомпании, выполняющей рейс.
    let airline: ASAirlineDTO?
    /// Идентификационные данные рейса (номер, коды IATA/ICAO).
    let flight: ASFlightInfoDTO?
    /// Технические данные о воздушном судне (регистрация, тип).
    let aircraft: ASAircraftDTO?
    /// Live-данные о текущей позиции самолёта. Присутствуют только для активных рейсов.
    let live: ASLiveDTO?
}

/// DTO точки маршрута — вылета или прилёта.
///
/// Содержит идентификаторы аэропорта, информацию о терминале/гейте
/// и три варианта времени: плановое, расчётное и фактическое.
struct ASEndpointDTO: Decodable {
    /// Полное название аэропорта (например, `"John F Kennedy International"`).
    let airport: String?
    /// Часовой пояс аэропорта в формате IANA (например, `"America/New_York"`).
    let timezone: String?
    /// Код аэропорта IATA из трёх букв (например, `"JFK"`).
    let iata: String?
    /// Код аэропорта ICAO из четырёх букв (например, `"KJFK"`).
    let icao: String?
    /// Терминал вылета или прилёта (например, `"4"`).
    let terminal: String?
    /// Гейт посадки или выхода (например, `"B12"`).
    let gate: String?
    /// Задержка рейса в минутах относительно планового времени. `nil` — без задержки.
    let delay: Int?
    /// Плановое время вылета/прилёта в формате ISO 8601.
    let scheduled: String?
    /// Расчётное (уточнённое) время вылета/прилёта в формате ISO 8601.
    let estimated: String?
    /// Фактическое время вылета/прилёта в формате ISO 8601. Появляется после события.
    let actual: String?
}

/// DTO авиакомпании, выполняющей рейс.
struct ASAirlineDTO: Decodable {
    /// Полное коммерческое название авиакомпании (например, `"American Airlines"`).
    let name: String?
    /// Двухбуквенный код IATA авиакомпании (например, `"AA"`).
    let iata: String?
    /// Трёхбуквенный код ICAO авиакомпании (например, `"AAL"`).
    let icao: String?
}

/// DTO идентификационных данных рейса.
///
/// Отличается от `ASAirlineDTO`: здесь хранятся коды самого рейса,
/// а не авиакомпании (например, `"AA1234"` vs `"AA"`).
struct ASFlightInfoDTO: Decodable {
    /// Числовая часть номера рейса (например, `"1234"` для рейса AA1234).
    let number: String?
    /// Полный номер рейса в формате IATA (например, `"AA1234"`).
    let iata: String?
    /// Полный номер рейса в формате ICAO (например, `"AAL1234"`).
    let icao: String?
}

/// DTO воздушного судна, выполняющего рейс.
struct ASAircraftDTO: Decodable {
    /// Регистрационный номер воздушного судна (например, `"N12345"`).
    let registration: String?
    /// Код типа воздушного судна IATA (например, `"738"` для Boeing 737-800).
    let iata: String?
    /// Код типа воздушного судна ICAO (например, `"B738"`).
    let icao: String?
    /// 24-битный ICAO-адрес транспондера (например, `"a1b2c3"`).
    /// Используется для запросов к OpenSky Network для получения live-позиции.
    let icao24: String?
}

/// DTO live-данных о текущем положении воздушного судна.
///
/// Заполняется только для рейсов со статусом `active`.
/// Данные обновляются с интервалом, определяемым тарифным планом AviationStack.
struct ASLiveDTO: Decodable {
    /// Время последнего обновления позиции в формате ISO 8601.
    let updated: String?
    /// Географическая широта самолёта в градусах (от −90 до +90).
    let latitude: Double?
    /// Географическая долгота самолёта в градусах (от −180 до +180).
    let longitude: Double?
    /// Высота полёта над уровнем моря в метрах.
    let altitude: Double?
    /// Курс (направление движения) в градусах по часовой стрелке от севера (0–360).
    let direction: Double?
    /// Горизонтальная скорость в км/ч.
    let speedHorizontal: Double?
    /// Вертикальная скорость в км/ч. Положительная — набор высоты, отрицательная — снижение.
    let speedVertical: Double?
    /// `true`, если самолёт находится на земле; `false` — в воздухе.
    let isGround: Bool?
}

// MARK: - Маппинг DTO → Domain

extension ASFlightDTO {

    /// Преобразование AviationStack DTO в доменную модель Flight
    func toDomain() -> Flight? {
        guard let flightInfo = flight,
              let flightIata = flightInfo.iata else { return nil }

        let id = "\(flightIata)-\(flightDate ?? DateFormatters.apiDate.string(from: Date()))"

        let depAirport = Airport(
            icaoCode: departure?.icao ?? "",
            iataCode: departure?.iata ?? "",
            name: departure?.airport ?? "",
            city: "", country: "",
            latitude: 0,
            longitude: 0,
            timezone: departure?.timezone ?? "UTC"
        )

        let arrAirport = Airport(
            icaoCode: arrival?.icao ?? "",
            iataCode: arrival?.iata ?? "",
            name: arrival?.airport ?? "",
            city: "", country: "",
            latitude: 0,
            longitude: 0,
            timezone: arrival?.timezone ?? "UTC"
        )

        return Flight(
            id: id,
            flightNumber: flightIata,
            airline: Airline(
                iataCode: airline?.iata ?? "",
                icaoCode: airline?.icao ?? "",
                name: airline?.name ?? ""
            ),
            departure: FlightEndpoint(
                airport: depAirport,
                terminal: departure?.terminal,
                gate: departure?.gate,
                scheduledTime: parseDate(departure?.scheduled),
                estimatedTime: parseDate(departure?.estimated),
                actualTime: parseDate(departure?.actual),
                delay: departure?.delay
            ),
            arrival: FlightEndpoint(
                airport: arrAirport,
                terminal: arrival?.terminal,
                gate: arrival?.gate,
                scheduledTime: parseDate(arrival?.scheduled),
                estimatedTime: parseDate(arrival?.estimated),
                actualTime: parseDate(arrival?.actual),
                delay: arrival?.delay
            ),
            status: FlightStatus(apiString: flightStatus),
            aircraft: aircraft.map {
                Aircraft(registration: $0.registration, icao24: $0.icao24, model: $0.iata)
            },
            liveData: live.flatMap { $0.toDomain() }
        )
    }

    private func parseDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        return DateFormatters.iso8601.date(from: string)
            ?? DateFormatters.iso8601NoFraction.date(from: string)
    }
}

extension ASLiveDTO {
    func toDomain() -> FlightLiveData? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return FlightLiveData(
            latitude: lat,
            longitude: lon,
            altitude: altitude ?? 0,
            speed: speedHorizontal ?? 0,
            heading: direction ?? 0,
            verticalRate: speedVertical ?? 0,
            isOnGround: isGround ?? false,
            lastUpdated: DateFormatters.iso8601NoFraction.date(from: updated ?? "") ?? Date()
        )
    }
}

