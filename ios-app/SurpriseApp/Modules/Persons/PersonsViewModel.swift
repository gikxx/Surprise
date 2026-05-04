import Foundation

// MARK: - Protocol

protocol PersonsViewModelProtocol: AnyObject {
    var persons: [Person] { get }
    var onStateChanged: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }

    func loadPersons()
    func deletePerson(at index: Int)
    func createPerson(
        name: String,
        eventDay: Int,
        eventMonth: Int,
        eventYear: Int?,
        eventType: PersonEventType,
        notes: String?
    )
    func updatePerson(
        id: Int,
        name: String,
        eventDay: Int,
        eventMonth: Int,
        eventYear: Int?,
        eventType: PersonEventType,
        notes: String?
    )
}

// MARK: - PersonsViewModel

final class PersonsViewModel: PersonsViewModelProtocol {

    private let service: PersonsServiceProtocol

    private(set) var persons: [Person] = []

    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    init(service: PersonsServiceProtocol = PersonsService()) {
        self.service = service
    }

    // MARK: - Public

    func loadPersons() {
        Task {
            do {
                let loaded = try await service.fetchPersons()
                // Сортируем по ближайшей дате события
                let sorted = loaded.sorted { $0.daysUntilEvent < $1.daysUntilEvent }
                await MainActor.run {
                    self.persons = sorted
                    self.onStateChanged?()
                    WidgetDataService.save(sorted)
                }
            } catch {
                await MainActor.run {
                    self.onError?("Не удалось загрузить список")
                }
            }
        }
    }

    func deletePerson(at index: Int) {
        guard index >= 0, index < persons.count else { return }
        let person = persons[index]

        // Оптимистичное удаление из UI
        persons.remove(at: index)
        onStateChanged?()

        Task {
            do {
                try await service.deletePerson(id: person.id)
            } catch {
                // Если ошибка — возвращаем обратно
                await MainActor.run {
                    self.persons.insert(person, at: min(index, self.persons.count))
                    self.onStateChanged?()
                    self.onError?("Не удалось удалить")
                }
            }
        }
    }

    func createPerson(
        name: String,
        eventDay: Int,
        eventMonth: Int,
        eventYear: Int?,
        eventType: PersonEventType,
        notes: String?
    ) {
        Task {
            do {
                let created = try await service.createPerson(
                    name: name,
                    eventDay: eventDay,
                    eventMonth: eventMonth,
                    eventYear: eventYear,
                    eventType: eventType,
                    notes: notes
                )
                await MainActor.run {
                    self.persons.append(created)
                    self.persons.sort { $0.daysUntilEvent < $1.daysUntilEvent }
                    self.onStateChanged?()
                }
            } catch {
                await MainActor.run {
                    self.onError?("Не удалось добавить")
                }
            }
        }
    }

    func updatePerson(
        id: Int,
        name: String,
        eventDay: Int,
        eventMonth: Int,
        eventYear: Int?,
        eventType: PersonEventType,
        notes: String?
    ) {
        Task {
            do {
                let updated = try await service.updatePerson(
                    id: id,
                    name: name,
                    eventDay: eventDay,
                    eventMonth: eventMonth,
                    eventYear: eventYear,
                    eventType: eventType,
                    notes: notes
                )
                await MainActor.run {
                    if let idx = self.persons.firstIndex(where: { $0.id == id }) {
                        self.persons[idx] = updated
                        self.persons.sort { $0.daysUntilEvent < $1.daysUntilEvent }
                        self.onStateChanged?()
                    }
                }
            } catch {
                await MainActor.run {
                    self.onError?("Не удалось сохранить изменения")
                }
            }
        }
    }
}
