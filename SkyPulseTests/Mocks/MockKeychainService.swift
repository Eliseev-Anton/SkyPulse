import Foundation
@testable import SkyPulse

/// Мок Keychain сервиса с in-memory хранением.
final class MockKeychainService {

    private var storage: [String: String] = [:]

    @discardableResult
    func save(key: String, value: String) -> Bool {
        storage[key] = value
        return true
    }

    func retrieve(key: String) -> String? {
        storage[key]
    }

    @discardableResult
    func update(key: String, newValue: String) -> Bool {
        storage[key] = newValue
        return true
    }

    @discardableResult
    func delete(key: String) -> Bool {
        storage.removeValue(forKey: key)
        return true
    }

    func contains(key: String) -> Bool {
        storage[key] != nil
    }

    /// Очистить всё хранилище (для tearDown)
    func clearAll() {
        storage.removeAll()
    }
}
