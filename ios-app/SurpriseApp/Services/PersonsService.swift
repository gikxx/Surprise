import Foundation

// MARK: - PersonsServiceProtocol

protocol PersonsServiceProtocol {
    func fetchPersons() async throws -> [Person]
    func createPerson(
        name: String,
        eventDay: Int,
        eventMonth: Int,
        eventYear: Int?,
        eventType: PersonEventType,
        notes: String?
    ) async throws -> Person
    func updatePerson(
        id: Int,
        name: String?,
        eventDay: Int?,
        eventMonth: Int?,
        eventYear: Int?,
        eventType: PersonEventType?,
        notes: String?
    ) async throws -> Person
    func deletePerson(id: Int) async throws
}

// MARK: - PersonsService

final class PersonsService: PersonsServiceProtocol {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func fetchPersons() async throws -> [Person] {
        let endpoint = Endpoint(path: "/persons", method: .get)
        return try await networkService.request(endpoint)
    }

    func createPerson(
        name: String,
        eventDay: Int,
        eventMonth: Int,
        eventYear: Int?,
        eventType: PersonEventType,
        notes: String?
    ) async throws -> Person {
        var params: [String: Any] = [
            "name":        name,
            "event_day":   eventDay,
            "event_month": eventMonth,
            "event_type":  eventType.rawValue,
        ]
        if let year  = eventYear               { params["event_year"] = year }
        if let notes = notes, !notes.isEmpty   { params["notes"]      = notes }

        let endpoint = Endpoint(path: "/persons", method: .post, bodyParameters: params)
        return try await networkService.request(endpoint)
    }

    func updatePerson(
        id: Int,
        name: String?,
        eventDay: Int?,
        eventMonth: Int?,
        eventYear: Int?,
        eventType: PersonEventType?,
        notes: String?
    ) async throws -> Person {
        var params: [String: Any] = [:]
        if let name      = name                { params["name"]        = name }
        if let day       = eventDay            { params["event_day"]   = day }
        if let month     = eventMonth          { params["event_month"] = month }
        if let year      = eventYear           { params["event_year"]  = year }
        if let type      = eventType           { params["event_type"]  = type.rawValue }
        if let notes     = notes               { params["notes"]       = notes }

        let endpoint = Endpoint(path: "/persons/\(id)", method: .patch, bodyParameters: params)
        return try await networkService.request(endpoint)
    }

    func deletePerson(id: Int) async throws {
        let endpoint = Endpoint(path: "/persons/\(id)", method: .delete)
        try await networkService.requestVoid(endpoint)
    }
}
