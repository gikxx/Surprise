import Foundation

extension JSONDecoder {
    /// Кастомный декодер для формата дат сервера.
    static var surpriseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // 1. ISO8601 с фрактальными секундами и Z
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // 2. Микросекунды без смещения
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // 3. Стандарт без фрактальных секунд
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // 4. Альтернатива с пробелом вместо T
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        
        return decoder
    }
}
