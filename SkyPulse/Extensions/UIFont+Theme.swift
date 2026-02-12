import UIKit

/// Типографика приложения — единый стиль шрифтов.
extension UIFont {

    static let skyTitle = UIFont.systemFont(ofSize: 24, weight: .bold)
    static let skyHeadline = UIFont.systemFont(ofSize: 20, weight: .semibold)
    static let skySubheadline = UIFont.systemFont(ofSize: 17, weight: .medium)
    static let skySubheadlineBold = UIFont.systemFont(ofSize: 17, weight: .bold)
    static let skyBody = UIFont.systemFont(ofSize: 15, weight: .regular)
    static let skyBodyBold = UIFont.systemFont(ofSize: 15, weight: .semibold)
    static let skyCaption = UIFont.systemFont(ofSize: 13, weight: .regular)
    static let skyCaptionBold = UIFont.systemFont(ofSize: 13, weight: .semibold)

    /// Крупный код аэропорта на карточке рейса (например, "SVO")
    static let skyAirportCode = UIFont.systemFont(ofSize: 28, weight: .bold)

    /// Шрифт для табло аэропорта (моноширинный)
    static let skyBoard = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
    static let skyBoardLarge = UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
}
