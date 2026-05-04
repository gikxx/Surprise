import XCTest
@testable import SurpriseApp

// MARK: - PersonsServiceTests

@MainActor
final class PersonsServiceTests: XCTestCase {

    private var network: MockNetworkService!
    private var sut: PersonsService!

    override func setUp() {
        super.setUp()
        network = MockNetworkService()
        sut = PersonsService(networkService: network)
    }

    override func tearDown() {
        sut = nil
        network = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func personJSON(
        id: Int = 1,
        name: String = "Карина",
        eventDay: Int = 15,
        eventMonth: Int = 6,
        eventYear: Int? = nil,
        eventType: String = "birthday",
        notes: String? = nil
    ) -> Data {
        var json = """
        {
            "id": \(id),
            "user_id": 1,
            "name": "\(name)",
            "event_day": \(eventDay),
            "event_month": \(eventMonth),
            "event_type": "\(eventType)"
        """
        if let year = eventYear { json += ",\n    \"event_year\": \(year)" }
        if let notes = notes    { json += ",\n    \"notes\": \"\(notes)\"" }
        json += "\n}"
        return json.data(using: .utf8)!
    }

    private func personsArrayJSON(_ persons: [(id: Int, name: String)] = [(1, "Карина")]) -> Data {
        let items = persons.map { p in
            """
            {"id": \(p.id), "user_id": 1, "name": "\(p.name)", "event_day": 10, "event_month": 5, "event_type": "birthday"}
            """
        }.joined(separator: ",\n")
        return "[\(items)]".data(using: .utf8)!
    }

    // MARK: - fetchPersons — успех

    func test_fetchPersons_callsCorrectEndpoint() async throws {
        // Arrange
        network.stubbedData = personsArrayJSON()

        // Act
        _ = try await sut.fetchPersons()

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/persons")
        XCTAssertEqual(network.lastEndpoint?.method, .get)
    }

    func test_fetchPersons_returnsDecodedPersons() async throws {
        // Arrange
        network.stubbedData = personsArrayJSON([(1, "Карина"), (2, "Иван")])

        // Act
        let persons = try await sut.fetchPersons()

        // Assert
        XCTAssertEqual(persons.count, 2)
        XCTAssertEqual(persons[0].id, 1)
        XCTAssertEqual(persons[1].id, 2)
    }

    func test_fetchPersons_withEmptyArray_returnsEmptyList() async throws {
        // Arrange
        network.stubbedData = "[]".data(using: .utf8)!

        // Act
        let persons = try await sut.fetchPersons()

        // Assert
        XCTAssertTrue(persons.isEmpty)
    }

    func test_fetchPersons_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.fetchPersons()
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_fetchPersons_decodesName() async throws {
        // Arrange
        network.stubbedData = personsArrayJSON([(42, "Тест Имя")])

        // Act
        let persons = try await sut.fetchPersons()

        // Assert
        XCTAssertEqual(persons.first?.name, "Тест Имя")
    }

    // MARK: - createPerson — успех

    func test_createPerson_callsPostPersons() async throws {
        // Arrange
        network.stubbedData = personJSON()

        // Act
        _ = try await sut.createPerson(
            name: "Карина",
            eventDay: 15, eventMonth: 6,
            eventYear: nil, eventType: .birthday,
            notes: nil
        )

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/persons")
        XCTAssertEqual(network.lastEndpoint?.method, .post)
    }

    func test_createPerson_returnsDecodedPerson() async throws {
        // Arrange
        network.stubbedData = personJSON(id: 99, name: "Новый")

        // Act
        let person = try await sut.createPerson(
            name: "Новый",
            eventDay: 1, eventMonth: 1,
            eventYear: nil, eventType: .birthday,
            notes: nil
        )

        // Assert
        XCTAssertEqual(person.id, 99)
        XCTAssertEqual(person.name, "Новый")
    }

    func test_createPerson_withYear_includesYearInParams() async throws {
        // Arrange
        network.stubbedData = personJSON(eventYear: 1995)

        // Act
        let person = try await sut.createPerson(
            name: "Карина",
            eventDay: 15, eventMonth: 6,
            eventYear: 1995, eventType: .birthday,
            notes: nil
        )

        // Assert
        XCTAssertEqual(person.eventYear, 1995)
    }

    func test_createPerson_withNotes_includesNotesInResponse() async throws {
        // Arrange
        network.stubbedData = personJSON(notes: "Любит цветы")

        // Act
        let person = try await sut.createPerson(
            name: "Карина",
            eventDay: 1, eventMonth: 1,
            eventYear: nil, eventType: .birthday,
            notes: "Любит цветы"
        )

        // Assert
        XCTAssertEqual(person.notes, "Любит цветы")
    }

    func test_createPerson_withAnniversaryType_encodesCorrectEventType() async throws {
        // Arrange
        network.stubbedData = personJSON(eventType: "anniversary")

        // Act
        let person = try await sut.createPerson(
            name: "Тест",
            eventDay: 1, eventMonth: 3,
            eventYear: nil, eventType: .anniversary,
            notes: nil
        )

        // Assert
        XCTAssertEqual(person.eventType, .anniversary)
    }

    func test_createPerson_withCustomType_encodesCorrectEventType() async throws {
        // Arrange
        network.stubbedData = personJSON(eventType: "custom")

        // Act
        let person = try await sut.createPerson(
            name: "Тест",
            eventDay: 5, eventMonth: 9,
            eventYear: nil, eventType: .custom,
            notes: nil
        )

        // Assert
        XCTAssertEqual(person.eventType, .custom)
    }

    func test_createPerson_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.createPerson(
                name: "Test",
                eventDay: 1, eventMonth: 1,
                eventYear: nil, eventType: .birthday,
                notes: nil
            )
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - updatePerson — успех

    func test_updatePerson_callsPatchPersonsId() async throws {
        // Arrange
        network.stubbedData = personJSON(id: 7)

        // Act
        _ = try await sut.updatePerson(
            id: 7,
            name: "Изменённое",
            eventDay: nil, eventMonth: nil,
            eventYear: nil, eventType: nil,
            notes: nil
        )

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/persons/7")
        XCTAssertEqual(network.lastEndpoint?.method, .patch)
    }

    func test_updatePerson_withName_returnsUpdatedPerson() async throws {
        // Arrange
        network.stubbedData = personJSON(id: 1, name: "Обновлённое")

        // Act
        let person = try await sut.updatePerson(
            id: 1,
            name: "Обновлённое",
            eventDay: nil, eventMonth: nil,
            eventYear: nil, eventType: nil,
            notes: nil
        )

        // Assert
        XCTAssertEqual(person.name, "Обновлённое")
    }

    func test_updatePerson_withAllNilParams_callsNetwork() async throws {
        // Arrange
        network.stubbedData = personJSON(id: 5)

        // Act
        _ = try await sut.updatePerson(
            id: 5,
            name: nil, eventDay: nil, eventMonth: nil,
            eventYear: nil, eventType: nil, notes: nil
        )

        // Assert — сеть всё равно вызывалась
        XCTAssertEqual(network.lastEndpoint?.path, "/persons/5")
    }

    func test_updatePerson_withEventDate_decodesCorrectly() async throws {
        // Arrange
        network.stubbedData = personJSON(id: 3, eventDay: 20, eventMonth: 12)

        // Act
        let person = try await sut.updatePerson(
            id: 3,
            name: nil, eventDay: 20, eventMonth: 12,
            eventYear: nil, eventType: nil, notes: nil
        )

        // Assert
        XCTAssertEqual(person.eventDay, 20)
        XCTAssertEqual(person.eventMonth, 12)
    }

    func test_updatePerson_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.updatePerson(
                id: 1,
                name: "Test", eventDay: nil, eventMonth: nil,
                eventYear: nil, eventType: nil, notes: nil
            )
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - deletePerson — успех

    func test_deletePerson_callsDeletePersonsId() async throws {
        // Act
        try await sut.deletePerson(id: 42)

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/persons/42")
        XCTAssertEqual(network.lastEndpoint?.method, .delete)
        XCTAssertTrue(network.requestVoidCalled)
    }

    func test_deletePerson_callsRequestVoidOnce() async throws {
        // Act
        try await sut.deletePerson(id: 1)

        // Assert
        XCTAssertEqual(network.requestVoidCalledCount, 1)
    }

    func test_deletePerson_differentIds_callsCorrectPath() async throws {
        // Act
        try await sut.deletePerson(id: 123)

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/persons/123")
    }

    func test_deletePerson_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            try await sut.deletePerson(id: 1)
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
