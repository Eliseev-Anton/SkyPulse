import Foundation
import os.log

/// Обёртка над os_log для структурированного логирования.
/// Избегаем тяжёлых зависимостей — используем нативный os.log.
enum Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.skypulse"

    private static let generalLog = OSLog(subsystem: subsystem, category: "General")
    private static let networkLog = OSLog(subsystem: subsystem, category: "Network")
    private static let dataLog = OSLog(subsystem: subsystem, category: "Data")

    // MARK: - Общие

    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        os_log(.debug, log: generalLog, "[%{public}@:%{public}d] %{public}@", filename, line, message)
        #endif
    }

    static func info(_ message: String) {
        os_log(.info, log: generalLog, "%{public}@", message)
    }

    static func warning(_ message: String) {
        os_log(.default, log: generalLog, "%{public}@", message)
    }

    static func error(_ message: String, error: Error? = nil) {
        if let error = error {
            os_log(.error, log: generalLog, "%{public}@ | Error: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.error, log: generalLog, "%{public}@", message)
        }
    }

    // MARK: - Сеть

    static func network(_ message: String) {
        #if DEBUG
        os_log(.debug, log: networkLog, "%{public}@", message)
        #endif
    }

    // MARK: - Данные

    static func data(_ message: String) {
        #if DEBUG
        os_log(.debug, log: dataLog, "%{public}@", message)
        #endif
    }
}
