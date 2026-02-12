import Foundation

/// Текущий операционный статус рейса.
/// Маппится на строковые значения из AviationStack API.
enum FlightStatus: String, CaseIterable, Codable {
    case scheduled
    case active
    case landed
    case cancelled
    case incident
    case diverted
    case unknown

    /// Отображаемое имя для UI
    var displayName: String {
        switch self {
        case .scheduled:  return NSLocalizedString("status.scheduled", comment: "")
        case .active:     return NSLocalizedString("status.active", comment: "")
        case .landed:     return NSLocalizedString("status.landed", comment: "")
        case .cancelled:  return NSLocalizedString("status.cancelled", comment: "")
        case .incident:   return NSLocalizedString("status.incident", comment: "")
        case .diverted:   return NSLocalizedString("status.diverted", comment: "")
        case .unknown:    return NSLocalizedString("status.unknown", comment: "")
        }
    }

    /// Инициализация из строки API с fallback на `.unknown`
    init(apiString: String?) {
        self = FlightStatus(rawValue: apiString?.lowercased() ?? "") ?? .unknown
    }
}
