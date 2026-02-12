import UIKit

/// Глобальные константы для UI и прочих слоёв приложения.
enum Constants {

    // MARK: - Размеры

    enum Layout {
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let cardShadowRadius: CGFloat = 8
        static let cardShadowOpacity: Float = 0.12
    }

    // MARK: - Вкладки TabBar

    enum Tab {
        static let dashboardTitle = "Dashboard"
        static let searchTitle = "Search"
        static let favoritesTitle = "Favorites"
        static let settingsTitle = "Settings"

        static let dashboardIcon = "airplane.circle"
        static let searchIcon = "magnifyingglass"
        static let favoritesIcon = "heart"
        static let settingsIcon = "gearshape"
    }

    // MARK: - Accessibility-идентификаторы для UI-тестов

    enum AccessibilityID {
        static let flightCard = "flightCard"
        static let searchBar = "searchBar"
        static let favoriteButton = "favoriteButton"
        static let offlineBanner = "offlineBanner"
        static let boardSegment = "boardSegment"
    }

    // MARK: - Категории уведомлений

    enum NotificationCategory {
        static let flightStatus = "FLIGHT_STATUS"
        static let departureReminder = "DEPARTURE_REMINDER"
    }
}
