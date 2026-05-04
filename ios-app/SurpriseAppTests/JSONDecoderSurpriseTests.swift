import XCTest
@testable import SurpriseApp

// MARK: - JSONDecoderSurpriseTests
// Тестируем кастомную стратегию декодирования дат JSONDecoder.surpriseDecoder.
// Сервер присылает даты в 4 форматах — все 4 должны декодироваться корректно.

@MainActor
final class JSONDecoderSurpriseTests: XCTestCase {

    private let sut = JSONDecoder.surpriseDecoder

    // Вспомогательная структура-обёртка для декодирования одной даты
    private struct Wrapper: Decodable {
        let date: Date
    }

    private func json(_ dateString: String) -> Data {
        #"{"date":"\#(dateString)"}"#.data(using: .utf8)!
    }

    // MARK: - Формат 1: ISO8601 с дробными секундами и Z

    func test_surpriseDecoder_iso8601WithFractionalSeconds_decodesSuccessfully() throws {
        // Arrange
        let data = json("2024-03-15T10:30:00.500Z")

        // Act & Assert
        XCTAssertNoThrow(try sut.decode(Wrapper.self, from: data))
    }

    func test_surpriseDecoder_iso8601WithFractionalSeconds_returnsCorrectDate() throws {
        // Arrange
        let data = json("2024-03-15T10:30:00.500Z")

        // Act
        let wrapper = try sut.decode(Wrapper.self, from: data)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: wrapper.date)

        // Assert
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
    }

    func test_surpriseDecoder_iso8601WithMilliseconds_decodesSuccessfully() throws {
        // Arrange — формат с 3 знаками после точки
        let data = json("2024-06-01T08:00:00.123Z")

        // Act & Assert
        XCTAssertNoThrow(try sut.decode(Wrapper.self, from: data))
    }

    // MARK: - Формат 2: микросекунды без смещения (yyyy-MM-dd'T'HH:mm:ss.SSSSSS)

    func test_surpriseDecoder_microsecondsWithoutOffset_decodesSuccessfully() throws {
        // Arrange
        let data = json("2024-03-15T10:30:00.123456")

        // Act & Assert
        XCTAssertNoThrow(try sut.decode(Wrapper.self, from: data))
    }

    func test_surpriseDecoder_microsecondsFormat_returnsDate() throws {
        // Arrange
        let data = json("2023-12-31T23:59:59.999999")

        // Act
        let wrapper = try sut.decode(Wrapper.self, from: data)

        // Assert — дата должна быть не nil
        XCTAssertNotNil(wrapper.date)
    }

    // MARK: - Формат 3: стандартный ISO без дробных секунд (yyyy-MM-dd'T'HH:mm:ss)

    func test_surpriseDecoder_isoWithoutFractionalSeconds_decodesSuccessfully() throws {
        // Arrange
        let data = json("2024-03-15T10:30:00")

        // Act & Assert
        XCTAssertNoThrow(try sut.decode(Wrapper.self, from: data))
    }

    func test_surpriseDecoder_isoWithoutFractional_returnsCorrectYear() throws {
        // Arrange
        let data = json("2025-07-04T12:00:00")

        // Act
        let wrapper = try sut.decode(Wrapper.self, from: data)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year], from: wrapper.date)

        // Assert
        XCTAssertEqual(components.year, 2025)
    }

    // MARK: - Формат 4: пробел вместо T (yyyy-MM-dd HH:mm:ss)

    func test_surpriseDecoder_spaceInsteadOfT_decodesSuccessfully() throws {
        // Arrange
        let data = json("2024-03-15 10:30:00")

        // Act & Assert
        XCTAssertNoThrow(try sut.decode(Wrapper.self, from: data))
    }

    func test_surpriseDecoder_spaceFormat_returnsDate() throws {
        // Arrange
        let data = json("2024-01-01 00:00:00")

        // Act
        let wrapper = try sut.decode(Wrapper.self, from: data)

        // Assert
        XCTAssertNotNil(wrapper.date)
    }

    // MARK: - Неизвестный формат → ошибка декодирования

    func test_surpriseDecoder_invalidDateString_throwsError() {
        // Arrange
        let data = json("not-a-date")

        // Act & Assert
        XCTAssertThrowsError(try sut.decode(Wrapper.self, from: data))
    }

    func test_surpriseDecoder_emptyDateString_throwsError() {
        // Arrange
        let data = json("")

        // Act & Assert
        XCTAssertThrowsError(try sut.decode(Wrapper.self, from: data))
    }

    // MARK: - Возвращает стандартный JSONDecoder

    func test_surpriseDecoder_returnsJSONDecoderInstance() {
        XCTAssertNotNil(JSONDecoder.surpriseDecoder)
    }
}
