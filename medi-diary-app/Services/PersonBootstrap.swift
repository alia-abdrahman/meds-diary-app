import Foundation
import SwiftData

enum PersonBootstrap {
    /// Ensures a single self Person exists, dedupes any duplicates, and assigns
    /// orphaned (nil personId) entity rows to the self person. Idempotent and safe
    /// to call on every launch — handles late-arriving CloudKit rows from other devices.
    @MainActor
    static func ensureSelfAndBackfill(context: ModelContext, defaultName: String?) -> Person {
        let people = (try? context.fetch(FetchDescriptor<Person>())) ?? []
        let selfPeople = people.filter(\.isSelf).sorted { $0.createdAt < $1.createdAt }

        let selfPerson: Person
        if let oldest = selfPeople.first {
            selfPerson = oldest
            for duplicate in selfPeople.dropFirst() {
                duplicate.isSelf = false
            }
        } else {
            let name = (defaultName?.isEmpty == false ? defaultName : "Me") ?? "Me"
            selfPerson = Person(name: name, relation: "Self", isSelf: true)
            context.insert(selfPerson)
        }

        let selfID = selfPerson.id

        backfillIfNil(Appointment.self, context: context) { $0.personId == nil } assign: { $0.personId = selfID }
        backfillIfNil(Medicine.self, context: context) { $0.personId == nil } assign: { $0.personId = selfID }
        backfillIfNil(Supplement.self, context: context) { $0.personId == nil } assign: { $0.personId = selfID }
        backfillIfNil(MoodEntry.self, context: context) { $0.personId == nil } assign: { $0.personId = selfID }

        try? context.save()
        return selfPerson
    }

    private static func backfillIfNil<T: PersistentModel>(
        _ type: T.Type,
        context: ModelContext,
        predicate: (T) -> Bool,
        assign: (T) -> Void
    ) {
        let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
        for row in all where predicate(row) {
            assign(row)
        }
    }
}
