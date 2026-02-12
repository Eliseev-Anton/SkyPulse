import Foundation

/// Модель поискового запроса для сохранения в историю.
struct SearchQuery: Equatable {
    let text: String
    let type: SearchType
    let timestamp: Date

    /// Тип поискового запроса — определяет стратегию поиска
    enum SearchType: String, Codable {
        case flightNumber   // поиск по номеру рейса: "SU1234"
        case route          // поиск по маршруту: "SVO-JFK"
        case airport        // поиск по аэропорту: "SVO" или "Sheremetyevo"
    }

    /// Автоматически определяет тип запроса по формату текста
    static func detect(from text: String) -> SearchQuery {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Формат маршрута: "SVO-JFK" или "SVO JFK"
        if trimmed.contains("-") || (trimmed.count >= 7 && trimmed.split(separator: " ").count == 2) {
            return SearchQuery(text: trimmed, type: .route, timestamp: Date())
        }

        // Формат номера рейса: "SU1234", "AA 123"
        let alphanumericPattern = trimmed.replacingOccurrences(of: " ", with: "")
        if alphanumericPattern.count >= 3,
           alphanumericPattern.prefix(2).allSatisfy({ $0.isLetter }),
           alphanumericPattern.dropFirst(2).allSatisfy({ $0.isNumber }) {
            return SearchQuery(text: alphanumericPattern, type: .flightNumber, timestamp: Date())
        }

        // По умолчанию — поиск по аэропорту
        return SearchQuery(text: trimmed, type: .airport, timestamp: Date())
    }
}
