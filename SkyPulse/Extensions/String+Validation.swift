import Foundation

/// Валидация авиационных кодов и номеров рейсов.
extension String {

    /// Проверка формата IATA-кода аэропорта (3 латинские буквы)
    var isValidIATACode: Bool {
        let pattern = "^[A-Z]{3}$"
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Проверка формата ICAO-кода аэропорта (4 латинские буквы)
    var isValidICAOCode: Bool {
        let pattern = "^[A-Z]{4}$"
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Проверка формата номера рейса (2 буквы + 1-4 цифры, например "SU1234")
    var isValidFlightNumber: Bool {
        let pattern = "^[A-Z]{2}\\d{1,4}$"
        return uppercased().range(of: pattern, options: .regularExpression) != nil
    }

    /// Нормализация номера рейса: убираем пробелы, приводим к uppercase
    var normalizedFlightNumber: String {
        replacingOccurrences(of: " ", with: "").uppercased()
    }
}
