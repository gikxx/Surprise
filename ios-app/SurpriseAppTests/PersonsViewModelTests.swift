import XCTest
@testable import SurpriseApp

// MARK: - PersonsViewModelTests

@MainActor
final class PersonsViewModelTests: XCTestCase {

    private var service: MockPersonsService!
    private var sut: PersonsViewModel!

    override func setUp() {
        super.setUp()
        service = MockPersonsService()
        sut = PersonsViewModel(service: service)
    }

    override func tearDown() {
        sut = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Регистрирует onStateChanged ДО вызова action, ждёт первого колбэка.
    private func awaitStateChange(timeout: TimeInterval = 3.0, action: () -> Void) async {
        let exp = expectation(description: "onStateChanged")
        exp.assertForOverFulfill = false
        sut.onStateChanged = { exp.fulfill() }
        action()
        await fulfillment(of: [exp], timeout: timeout)
    }

    /// Регистрирует onError ДО вызова action, ждёт первого колбэка с ошибкой.
    private func awaitError(timeout: TimeInterval = 3.0, action: () -> Void) async {
        let exp = expectation(description: "onError")
        exp.assertForOverFulfill = false
        sut.onError = { _ in exp.fulfill() }
        action()
        await fulfillment(of: [exp], timeout: timeout)
    }

    // MARK: - loadPersons — успех

    func test_loadPersons_withPersons_populatesArray() async {
        // Arrange
        service.stubbedPersons = [Person.make(id: 1), Person.make(id: 2)]

        // Act
        await awaitStateChange { self.sut.loadPersons() }

        // Assert
        XCTAssertEqual(sut.persons.count, 2)
    }

    func test_loadPersons_callsOnStateChanged() async {
        // Arrange
        service.stubbedPersons = []
        var called = false

        // Act
        let exp = expectation(description: "onStateChanged")
        sut.onStateChanged = { called = true; exp.fulfill() }
        sut.loadPersons()
        await fulfillment(of: [exp], timeout: 3.0)

        // Assert
        XCTAssertTrue(called)
    }

    func test_loadPersons_sortsByDaysUntilEvent() async {
        // Arrange — person1 через 100 дней, person2 завтра
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let future   = calendar.date(byAdding: .day, value: 100, to: Date())!

        let tDay = calendar.component(.day,   from: tomorrow)
        let tMon = calendar.component(.month, from: tomorrow)
        let fDay = calendar.component(.day,   from: future)
        let fMon = calendar.component(.month, from: future)

        let person1 = Person.make(id: 1, eventDay: fDay, eventMonth: fMon) // дальше
        let person2 = Person.make(id: 2, eventDay: tDay, eventMonth: tMon) // ближе
        service.stubbedPersons = [person1, person2] // порядок намеренно обратный

        // Act
        await awaitStateChange { self.sut.loadPersons() }

        // Assert — person2 (завтра) должен быть первым
        XCTAssertEqual(sut.persons.first?.id, 2)
        XCTAssertEqual(sut.persons.last?.id, 1)
    }

    func test_loadPersons_withEmptyList_personsIsEmpty() async {
        // Arrange
        service.stubbedPersons = []

        // Act
        await awaitStateChange { self.sut.loadPersons() }

        // Assert
        XCTAssertTrue(sut.persons.isEmpty)
    }

    // MARK: - loadPersons — ошибка

    func test_loadPersons_whenServiceThrows_callsOnError() async {
        // Arrange
        service.shouldThrow = true

        // Act & Assert — awaitError выступает как проверка
        await awaitError { self.sut.loadPersons() }
    }

    func test_loadPersons_whenServiceThrows_personsRemainsEmpty() async {
        // Arrange
        service.shouldThrow = true

        // Act
        await awaitError { self.sut.loadPersons() }

        // Assert
        XCTAssertTrue(sut.persons.isEmpty)
    }

    // MARK: - deletePerson — успех

    func test_deletePerson_removesPersonImmediately() async {
        // Arrange
        service.stubbedPersons = [Person.make(id: 1), Person.make(id: 2)]
        await awaitStateChange { self.sut.loadPersons() }

        // Act — оптимистичное удаление синхронно
        sut.deletePerson(at: 0)

        // Assert
        XCTAssertEqual(sut.persons.count, 1)
    }

    func test_deletePerson_callsOnStateChangedSynchronously() async {
        // Arrange
        service.stubbedPersons = [Person.make(id: 1)]
        await awaitStateChange { self.sut.loadPersons() }
        var stateChangedCalled = false
        sut.onStateChanged = { stateChangedCalled = true }

        // Act
        sut.deletePerson(at: 0)

        // Assert — без ожидания, т.к. вызов синхронный
        XCTAssertTrue(stateChangedCalled)
    }

    func test_deletePerson_withOutOfBoundsIndex_doesNotCrash() async {
        // Arrange
        service.stubbedPersons = [Person.make(id: 1)]
        await awaitStateChange { self.sut.loadPersons() }

        // Act & Assert
        XCTAssertNoThrow(sut.deletePerson(at: 999))
        XCTAssertNoThrow(sut.deletePerson(at: -1))
        XCTAssertEqual(sut.persons.count, 1)
    }

    func test_deletePerson_whenServiceThrows_restoresPersonToArray() async {
        // Arrange
        service.stubbedPersons = [Person.make(id: 1)]
        await awaitStateChange { self.sut.loadPersons() }
        service.shouldThrow = true

        // Act — удаляем, ждём onError (при ошибке персона возвращается обратно)
        let exp = expectation(description: "error on delete")
        exp.assertForOverFulfill = false
        sut.onError = { _ in exp.fulfill() }
        sut.deletePerson(at: 0)
        await fulfillment(of: [exp], timeout: 3.0)

        // Assert — персона должна быть возвращена
        XCTAssertEqual(sut.persons.count, 1)
    }

    // MARK: - createPerson — успех

    func test_createPerson_addsPersonToArray() async {
        // Arrange
        service.stubbedPerson = Person.make(id: 99, name: "Новый")

        // Act
        await awaitStateChange {
            self.sut.createPerson(
                name: "Новый", eventDay: 15, eventMonth: 6,
                eventYear: nil, eventType: .birthday, notes: nil
            )
        }

        // Assert
        XCTAssertEqual(sut.persons.count, 1)
        XCTAssertEqual(sut.persons.first?.id, 99)
    }

    func test_createPerson_callsService() async {
        // Arrange
        service.stubbedPerson = Person.make(id: 1)

        // Act
        await awaitStateChange {
            self.sut.createPerson(
                name: "Test", eventDay: 1, eventMonth: 1,
                eventYear: 1995, eventType: .anniversary, notes: "заметка"
            )
        }

        // Assert
        XCTAssertTrue(service.createCalled)
    }

    // MARK: - createPerson — ошибка

    func test_createPerson_whenServiceThrows_callsOnError() async {
        // Arrange
        service.shouldThrow = true

        // Act & Assert
        await awaitError {
            self.sut.createPerson(
                name: "Test", eventDay: 1, eventMonth: 1,
                eventYear: nil, eventType: .birthday, notes: nil
            )
        }
    }

    func test_createPerson_whenServiceThrows_personsRemainsEmpty() async {
        // Arrange
        service.shouldThrow = true

        // Act
        await awaitError {
            self.sut.createPerson(
                name: "Test", eventDay: 1, eventMonth: 1,
                eventYear: nil, eventType: .birthday, notes: nil
            )
        }

        // Assert
        XCTAssertTrue(sut.persons.isEmpty)
    }

    // MARK: - updatePerson — успех

    func test_updatePerson_updatesPersonInArray() async {
        // Arrange — создаём персону через createPerson
        service.stubbedPerson = Person.make(id: 1, name: "Оригинал")
        await awaitStateChange {
            self.sut.createPerson(
                name: "Оригинал", eventDay: 1, eventMonth: 1,
                eventYear: nil, eventType: .birthday, notes: nil
            )
        }

        // Подменяем stub для update
        service.stubbedPerson = Person.make(id: 1, name: "Обновлённый")

        // Act
        await awaitStateChange {
            self.sut.updatePerson(
                id: 1, name: "Обновлённый", eventDay: 1, eventMonth: 1,
                eventYear: nil, eventType: .birthday, notes: nil
            )
        }

        // Assert
        XCTAssertEqual(sut.persons.first(where: { $0.id == 1 })?.name, "Обновлённый")
    }

    func test_updatePerson_callsServiceWithCorrectId() async {
        // Arrange
        service.stubbedPerson = Person.make(id: 42, name: "Test")
        await awaitStateChange {
            self.sut.createPerson(
                name: "Test", eventDay: 1, eventMonth: 1,
                eventYear: nil, eventType: .birthday, notes: nil
            )
        }
        service.stubbedPerson = Person.make(id: 42, name: "Edited")

        // Act
        await awaitStateChange {
            self.sut.updatePerson(
                id: 42, name: "Edited", eventDay: 1, eventMonth: 1,
                eventYear: nil, eventType: .birthday, notes: nil
            )
        }

        // Assert
        XCTAssertEqual(service.updateCalledWithId, 42)
    }

    // MARK: - updatePerson — ошибка

    func test_updatePerson_whenServiceThrows_callsOnError() async {
        // Arrange
        service.shouldThrow = true

        // Act & Assert
        await awaitError {
            self.sut.updatePerson(
                id: 1, name: "Test", eventDay: 1, eventMonth: 1,
                eventYear: nil, eventType: .birthday, notes: nil
            )
        }
    }
}
