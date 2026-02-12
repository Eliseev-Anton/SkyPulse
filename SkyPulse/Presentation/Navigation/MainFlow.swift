import UIKit
import RxFlow
import RxSwift

/// Основной `Flow` приложения: TabBar с четырьмя вкладками и push‑переходами.
///
/// Управляет жизненным циклом корневого `UITabBarController`, создаёт
/// навигационные стеки для Dashboard, Search, Favorites и Settings,
/// а также обрабатывает переходы на экран деталей рейса, табло аэропорта и карту.
final class MainFlow: Flow {

    /// Корневой `Presentable`, управляемый flow (TabBarController).
    var root: Presentable { rootViewController }

    /// Корневой TabBar‑контроллер с вкладками приложения.
    private lazy var rootViewController: UITabBarController = {
        let tab = UITabBarController()
        tab.tabBar.tintColor = .skyPrimaryBlue
        return tab
    }()

    /// Контейнер зависимостей, используемый для создания view model-ей и use case-ов.
    private let services: DIContainer

    /// Инициализирует основной flow.
    ///
    /// - Parameter services: Контейнер зависимостей приложения.
    init(services: DIContainer) {
        self.services = services
    }

    /// Обрабатывает шаги навигации основного потока (`MainStep`).
    ///
    /// - Parameter step: Навигационный шаг.
    /// - Returns: Конфигурация вкладчиков навигации.
    func navigate(to step: Step) -> FlowContributors {
        guard let step = step as? MainStep else { return .none }

        switch step {
        case .dashboardIsRequired:
            return setupTabs()
        case .flightDetailIsRequired(let id, let icao24):
            return navigateToFlightDetail(flightId: id, icao24: icao24)
        case .airportBoardIsRequired(let code):
            return navigateToAirportBoard(airportCode: code)
        case .mapIsRequired(let flights):
            return navigateToMap(flights: flights)
        case .popScreen:
            currentNavigationController?.popViewController(animated: true)
            return .none
        case .dismissModal:
            rootViewController.dismiss(animated: true)
            return .none
        default:
            return .none
        }
    }

    // MARK: - Текущий UINavigationController

    /// Текущий выбранный `UINavigationController` во вкладке TabBar.
    private var currentNavigationController: UINavigationController? {
        rootViewController.selectedViewController as? UINavigationController
    }

    // MARK: - Настройка вкладок

    /// Создаёт все вкладки TabBar и инициализирует их корневыми экранами.
    ///
    /// - Returns: Набор вкладчиков для RxFlow.
    private func setupTabs() -> FlowContributors {
        let dashboardNav = createTab(
            title: Constants.Tab.dashboardTitle,
            icon: Constants.Tab.dashboardIcon,
            tag: 0
        )
        let searchNav = createTab(
            title: Constants.Tab.searchTitle,
            icon: Constants.Tab.searchIcon,
            tag: 1
        )
        let favoritesNav = createTab(
            title: Constants.Tab.favoritesTitle,
            icon: Constants.Tab.favoritesIcon,
            tag: 2
        )
        let settingsNav = createTab(
            title: Constants.Tab.settingsTitle,
            icon: Constants.Tab.settingsIcon,
            tag: 3
        )

        rootViewController.viewControllers = [dashboardNav, searchNav, favoritesNav, settingsNav]

        // Dashboard
        let dashboardVM = DashboardViewModel(
            fetchFlightsUseCase: services.makeFetchFlightsUseCase(),
            reachability: services.reachabilityService
        )
        let dashboardVC = DashboardViewController(viewModel: dashboardVM)
        dashboardNav.viewControllers = [dashboardVC]

        // Search
        let searchVM = FlightSearchViewModel(
            searchFlightsUseCase: services.makeSearchFlightsUseCase(),
            realmManager: services.realmManager
        )
        let searchVC = FlightSearchViewController(viewModel: searchVM)
        searchNav.viewControllers = [searchVC]

        // Favorites
        let favVM = FavoritesViewModel(
            manageFavoritesUseCase: services.makeManageFavoritesUseCase()
        )
        let favVC = FavoritesViewController(viewModel: favVM)
        favoritesNav.viewControllers = [favVC]

        // Settings
        let settingsVM = SettingsViewModel(realmManager: services.realmManager)
        let settingsVC = SettingsViewController(viewModel: settingsVM)
        settingsNav.viewControllers = [settingsVC]

        return .multiple(flowContributors: [
            .contribute(withNextPresentable: dashboardVC, withNextStepper: dashboardVM),
            .contribute(withNextPresentable: searchVC, withNextStepper: searchVM),
            .contribute(withNextPresentable: favVC, withNextStepper: favVM),
            .contribute(withNextPresentable: settingsVC, withNextStepper: settingsVM),
        ])
    }

    // MARK: - Push-навигация

    /// Открывает экран деталей рейса.
    ///
    /// - Parameters:
    ///   - flightId: Идентификатор рейса.
    ///   - icao24: ICAO24‑идентификатор самолёта (для live‑позиции).
    /// - Returns: Вкладчик навигации к `FlightDetailViewController`.
    private func navigateToFlightDetail(flightId: String, icao24: String?) -> FlowContributors {
        let vm = FlightDetailViewModel(
            flightId: flightId,
            icao24: icao24,
            trackFlightUseCase: services.makeTrackFlightUseCase(),
            manageFavoritesUseCase: services.makeManageFavoritesUseCase()
        )
        let vc = FlightDetailViewController(viewModel: vm)
        currentNavigationController?.pushViewController(vc, animated: true)
        return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vm))
    }

    /// Открывает экран табло аэропорта (вылеты/прилёты).
    ///
    /// - Parameter airportCode: IATA‑код аэропорта.
    private func navigateToAirportBoard(airportCode: String) -> FlowContributors {
        let vm = AirportBoardViewModel(
            airportCode: airportCode,
            fetchAirportBoardUseCase: services.makeFetchAirportBoardUseCase()
        )
        let vc = AirportBoardViewController(viewModel: vm)
        currentNavigationController?.pushViewController(vc, animated: true)
        return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vm))
    }

    /// Открывает модальный экран карты с выбранными рейсами.
    ///
    /// - Parameter flights: Массив рейсов, которые должны быть показаны на карте.
    private func navigateToMap(flights: [Flight]) -> FlowContributors {
        let vm = MapViewModel(flights: flights)
        let vc = MapViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        rootViewController.present(nav, animated: true)
        return .none
    }

    // MARK: - Вспомогательные

    /// Создаёт пустой `UINavigationController` для вкладки TabBar.
    ///
    /// - Parameters:
    ///   - title: Заголовок вкладки.
    ///   - icon: Имя системной иконки SF Symbols.
    ///   - tag: Индекс вкладки.
    /// - Returns: Сконфигурированный `UINavigationController`.
    private func createTab(title: String, icon: String, tag: Int) -> UINavigationController {
        let nav = UINavigationController()
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: icon),
            tag: tag
        )
        return nav
    }
}
