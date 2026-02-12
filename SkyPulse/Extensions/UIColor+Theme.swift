import UIKit

/// Цветовая палитра приложения через именованные цвета из Assets.
extension UIColor {

    static let skyPrimaryBlue = UIColor(named: "PrimaryBlue") ?? .systemBlue
    static let skyBackground = UIColor.systemBackground
    static let skySecondaryBackground = UIColor.secondarySystemBackground

    static let skyTextPrimary = UIColor.label
    static let skyTextSecondary = UIColor.secondaryLabel

    static let skyStatusGreen = UIColor.systemGreen
    static let skyStatusRed = UIColor.systemRed
    static let skyStatusOrange = UIColor.systemOrange
    static let skyStatusGray = UIColor.systemGray

    /// Цвет для статуса рейса
    static func flightStatusColor(_ status: FlightStatus) -> UIColor {
        switch status {
        case .active:    return .skyStatusGreen
        case .landed:    return .skyPrimaryBlue
        case .scheduled: return .skyStatusGray
        case .cancelled: return .skyStatusRed
        case .diverted:  return .skyStatusOrange
        case .incident:  return .skyStatusRed
        case .unknown:   return .skyStatusGray
        }
    }
}
