import Foundation

/// DTO для ответа OpenSky /states/all
struct OSStateVectorResponse: Decodable {
    let time: Int
    let states: [[OSAnyCodable]]?
}

/// Обёртка для смешанных типов в массивах OpenSky (строки, числа, bool, null)
enum OSAnyCodable: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var doubleValue: Double? {
        switch self {
        case .double(let v): return v
        case .int(let v): return Double(v)
        default: return nil
        }
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }
}

/// Распарсенный state vector из OpenSky API
struct OSStateVector {
    let icao24: String
    let callsign: String?
    let originCountry: String
    let longitude: Double?
    let latitude: Double?
    let baroAltitude: Double?
    let onGround: Bool
    let velocity: Double?
    let trueTrack: Double?
    let verticalRate: Double?
    let geoAltitude: Double?

    /// Парсинг из массива смешанных типов (формат OpenSky)
    /// Индексы: [0]=icao24, [1]=callsign, [2]=country, [5]=lon, [6]=lat,
    /// [7]=baro_alt, [8]=on_ground, [9]=velocity, [10]=true_track,
    /// [11]=vertical_rate, [13]=geo_alt
    init?(from array: [OSAnyCodable]) {
        guard array.count >= 14,
              let icao = array[0].stringValue else { return nil }

        self.icao24 = icao
        self.callsign = array[1].stringValue?.trimmingCharacters(in: .whitespaces)
        self.originCountry = array[2].stringValue ?? ""
        self.longitude = array[5].doubleValue
        self.latitude = array[6].doubleValue
        self.baroAltitude = array[7].doubleValue
        self.onGround = array[8].boolValue ?? false
        self.velocity = array[9].doubleValue
        self.trueTrack = array[10].doubleValue
        self.verticalRate = array[11].doubleValue
        self.geoAltitude = array[13].doubleValue
    }

    /// Конвертация в доменную модель FlightLiveData
    func toDomain() -> FlightLiveData? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return FlightLiveData(
            latitude: lat,
            longitude: lon,
            altitude: baroAltitude ?? geoAltitude ?? 0,
            speed: velocity ?? 0,
            heading: trueTrack ?? 0,
            verticalRate: verticalRate ?? 0,
            isOnGround: onGround,
            lastUpdated: Date()
        )
    }
}
