import Foundation
import Security

/// Обёртка над Security Framework для безопасного хранения данных в Keychain.
///
/// Используется для хранения API‑ключей, токенов и других чувствительных данных
/// с удобным и типобезопасным интерфейсом.
final class KeychainService {

    /// Синглтон‑экземпляр сервиса работы с Keychain.
    static let shared = KeychainService()

    private init() {}

    // MARK: - Сохранение

    /// Сохраняет строковое значение в Keychain при помощи `SecItemAdd`.
    ///
    /// - Parameters:
    ///   - key: Ключ (имя записи) в Keychain.
    ///   - value: Строковое значение, которое нужно сохранить.
    /// - Returns: `true`, если операция завершилась успешно.
    @discardableResult
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            Logger.error("Keychain: не удалось конвертировать значение в Data")
            return false
        }

        // Удаляем старое значение, если оно существует, чтобы избежать конфликтов.
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            Logger.error("Keychain: ошибка сохранения, код: \(status)")
        }

        return status == errSecSuccess
    }

    // MARK: - Получение

    /// Получает строковое значение из Keychain при помощи `SecItemCopyMatching`.
    ///
    /// - Parameter key: Ключ записи в Keychain.
    /// - Returns: Найденное строковое значение или `nil`, если элемент не найден.
    func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                Logger.error("Keychain: ошибка чтения, код: \(status)")
            }
            return nil
        }

        return value
    }

    // MARK: - Обновление

    /// Обновляет существующее значение в Keychain при помощи `SecItemUpdate`.
    ///
    /// Если элемент не найден, создаёт новую запись.
    ///
    /// - Parameters:
    ///   - key: Ключ записи.
    ///   - newValue: Новое строковое значение.
    /// - Returns: `true`, если обновление или создание прошло успешно.
    @discardableResult
    func update(key: String, newValue: String) -> Bool {
        guard let data = newValue.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            // Если элемент не найден — создаём новый
            return save(key: key, value: newValue)
        }

        if status != errSecSuccess {
            Logger.error("Keychain: ошибка обновления, код: \(status)")
        }

        return status == errSecSuccess
    }

    // MARK: - Удаление

    /// Удаляет значение из Keychain при помощи `SecItemDelete`.
    ///
    /// - Parameter key: Ключ записи, которую нужно удалить.
    /// - Returns: `true`, если элемент удалён или его не было; `false` при ошибке.
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            Logger.error("Keychain: ошибка удаления, код: \(status)")
        }

        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Утилиты

    /// Проверяет наличие значения в Keychain для указанного ключа.
    ///
    /// - Parameter key: Ключ записи.
    /// - Returns: `true`, если значение существует.
    func contains(key: String) -> Bool {
        retrieve(key: key) != nil
    }

    /// Мигрирует дефолтный API‑ключ в Keychain при первом запуске приложения.
    ///
    /// Использует значения из `AppConfiguration`, чтобы не хранить чувствительные
    /// данные в открытом виде в настройках.
    func migrateDefaultAPIKeyIfNeeded() {
        let keychainKey = AppConfiguration.aviationStackAPIKeyIdentifier

        guard !contains(key: keychainKey) else {
            Logger.data("API ключ уже в Keychain")
            return
        }

        let defaultKey = AppConfiguration.defaultAviationStackAPIKey
        if save(key: keychainKey, value: defaultKey) {
            Logger.data("API ключ мигрирован в Keychain")
        }
    }
}
