import XCTest
@testable import SurpriseApp

// MARK: - PersonTests

final class PersonTests: XCTestCase {

    // MARK: - daysUntilEvent

    func test_daysUntilEvent_todaysDate_returnsZero() {
        // Arrange
        let calendar = Calendar.current
        let today = Date()
        let day   = calendar.component(.day,   from: today)
        let month = calendar.component(.month, from: today)
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertEqual(person.daysUntilEvent, 0)
    }

    func test_daysUntilEvent_tomorrowsDate_returnsOne() {
        // Arrange
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let day   = calendar.component(.day,   from: tomorrow)
        let month = calendar.component(.month, from: tomorrow)
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertEqual(person.daysUntilEvent, 1)
    }

    func test_daysUntilEvent_pastDateThisYear_returnsNextYearDays() {
        // Arrange — берём вчера, событие уже прошло → следующий год
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let day   = calendar.component(.day,   from: yesterday)
        let month = calendar.component(.month, from: yesterday)
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act
        let days = person.daysUntilEvent

        // Assert — до следующего года: 364 или 365 дней
        XCTAssertGreaterThan(days, 360)
        XCTAssertLessThanOrEqual(days, 366)
    }

    func test_daysUntilEvent_eventIn10Days_returnsTen() {
        // Arrange
        let calendar = Calendar.current
        let future = calendar.date(byAdding: .day, value: 10, to: Date())!
        let day   = calendar.component(.day,   from: future)
        let month = calendar.component(.month, from: future)
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertEqual(person.daysUntilEvent, 10)
    }

    // MARK: - eventDateString

    func test_eventDateString_withoutYear_returnsCorrectFormat() {
        // Arrange
        let person = Person.make(eventDay: 15, eventMonth: 3, eventYear: nil)

        // Act & Assert
        XCTAssertEqual(person.eventDateString, "15 марта")
    }

    func test_eventDateString_withYear_includesYear() {
        // Arrange
        let person = Person.make(eventDay: 7, eventMonth: 11, eventYear: 1990)

        // Act & Assert
        XCTAssertEqual(person.eventDateString, "7 ноября 1990")
    }

    func test_eventDateString_invalidMonth_returnsEmpty() {
        // Arrange
        let person = Person.make(eventDay: 1, eventMonth: 13)

        // Act & Assert
        XCTAssertEqual(person.eventDateString, "")
    }

    func test_eventDateString_zeroMonth_returnsEmpty() {
        // Arrange
        let person = Person.make(eventDay: 1, eventMonth: 0)

        // Act & Assert
        XCTAssertEqual(person.eventDateString, "")
    }

    func test_eventDateString_januaryContainsYanvarya() {
        // Arrange
        let person = Person.make(eventDay: 1, eventMonth: 1)

        // Act & Assert
        XCTAssertTrue(person.eventDateString.contains("января"))
    }

    func test_eventDateString_decemberContainsDekabrya() {
        // Arrange
        let person = Person.make(eventDay: 31, eventMonth: 12)

        // Act & Assert
        XCTAssertTrue(person.eventDateString.contains("декабря"))
    }

    // MARK: - daysLabel

    func test_daysLabel_today_returnsTodayEmoji() {
        // Arrange
        let calendar = Calendar.current
        let day   = calendar.component(.day,   from: Date())
        let month = calendar.component(.month, from: Date())
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertEqual(person.daysLabel, "Сегодня! 🎉")
    }

    func test_daysLabel_tomorrow_returnsTomorrowString() {
        // Arrange
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let day   = calendar.component(.day,   from: tomorrow)
        let month = calendar.component(.month, from: tomorrow)
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertEqual(person.daysLabel, "Завтра")
    }

    func test_daysLabel_moreThanOneDayAway_containsChrezAndDn() {
        // Arrange
        let calendar = Calendar.current
        let future = calendar.date(byAdding: .day, value: 10, to: Date())!
        let day   = calendar.component(.day,   from: future)
        let month = calendar.component(.month, from: future)
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertTrue(person.daysLabel.contains("через"))
        XCTAssertTrue(person.daysLabel.contains("дн."))
    }

    // MARK: - isUpcoming

    func test_isUpcoming_eventToday_returnsTrue() {
        // Arrange
        let calendar = Calendar.current
        let day   = calendar.component(.day,   from: Date())
        let month = calendar.component(.month, from: Date())
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertTrue(person.isUpcoming)
    }

    func test_isUpcoming_eventIn14Days_returnsTrue() {
        // Arrange
        let calendar = Calendar.current
        let boundary = calendar.date(byAdding: .day, value: 14, to: Date())!
        let day   = calendar.component(.day,   from: boundary)
        let month = calendar.component(.month, from: boundary)
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertTrue(person.isUpcoming)
    }

    func test_isUpcoming_eventIn15Days_returnsFalse() {
        // Arrange
        let calendar = Calendar.current
        let over = calendar.date(byAdding: .day, value: 15, to: Date())!
        let day   = calendar.component(.day,   from: over)
        let month = calendar.component(.month, from: over)
        let person = Person.make(eventDay: day, eventMonth: month)

        // Act & Assert
        XCTAssertFalse(person.isUpcoming)
    }

    // MARK: - PersonEventType

    func test_eventType_birthday_displayName() {
        XCTAssertEqual(PersonEventType.birthday.displayName, "День рождения")
    }

    func test_eventType_anniversary_displayName() {
        XCTAssertEqual(PersonEventType.anniversary.displayName, "Годовщина")
    }

    func test_eventType_custom_displayName() {
        XCTAssertEqual(PersonEventType.custom.displayName, "Другое")
    }

    func test_eventType_birthday_emoji() {
        XCTAssertEqual(PersonEventType.birthday.emoji, "🎂")
    }

    func test_eventType_anniversary_emoji() {
        XCTAssertEqual(PersonEventType.anniversary.emoji, "💝")
    }

    func test_eventType_custom_emoji() {
        XCTAssertEqual(PersonEventType.custom.emoji, "🎉")
    }

    func test_eventType_rawValues() {
        XCTAssertEqual(PersonEventType.birthday.rawValue,    "birthday")
        XCTAssertEqual(PersonEventType.anniversary.rawValue, "anniversary")
        XCTAssertEqual(PersonEventType.custom.rawValue,      "custom")
    }
}
