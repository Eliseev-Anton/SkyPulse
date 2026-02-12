import UIKit
import RealmSwift

/// Точка входа приложения и место для глобальной инициализации инфраструктуры.
///
/// Отвечает за настройку `Realm`, регистрацию сервисов и базовую конфигурацию
/// перед созданием окон и сцен.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Вызывается системой после запуска приложения.
    ///
    /// - Parameters:
    ///   - application: Экземпляр приложения, предоставленный iOS.
    ///   - launchOptions: Параметры, с которыми было запущено приложение
    ///     (push‑уведомление, deep link и т.п.).
    /// - Returns: `true`, если запуск прошёл успешно и приложение готово к показу UI.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Настраиваем базовую конфигурацию хранилища Realm перед работой с данными.
        configureRealm()
        return true
    }

    // MARK: - UISceneSession Lifecycle

    /// Запрашивает конфигурацию сцены (окна) при её создании.
    ///
    /// - Parameters:
    ///   - application: Экземпляр приложения.
    ///   - connectingSceneSession: Сессия, к которой нужно привязать создаваемую сцену.
    ///   - options: Дополнительные параметры подключения сцены.
    /// - Returns: Объект `UISceneConfiguration` c именем и ролью создаваемой сцены.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - Настройка Realm

    /// Конфигурирует глобальные настройки `Realm` для всего приложения.
    ///
    /// Устанавливает версию схемы, миграционный блок и дефолтную конфигурацию.
    /// В случае изменения структуры моделей здесь должна добавляться логика миграции.
    private func configureRealm() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { _, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // Начальная схема — миграция не требуется.
                }
            },
            deleteRealmIfMigrationNeeded: false
        )
        Realm.Configuration.defaultConfiguration = config

        // Логируем путь к файлу базы данных для удобства отладки.
        Logger.info("Realm path: \(config.fileURL?.absoluteString ?? "unknown")")
    }
}
