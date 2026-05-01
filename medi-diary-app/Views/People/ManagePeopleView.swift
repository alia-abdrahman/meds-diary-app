import SwiftUI
import SwiftData

struct ManagePeopleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(PersonContext.self) private var personContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(NotificationManager.self) private var notificationManager

    @Query private var peopleRaw: [Person]

    private var people: [Person] {
        peopleRaw.sorted { lhs, rhs in
            if lhs.isSelf != rhs.isSelf { return lhs.isSelf }
            if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
            return lhs.createdAt < rhs.createdAt
        }
    }

    @Query private var allMedicines: [Medicine]
    @Query private var allSupplements: [Supplement]
    @Query private var allAppointments: [Appointment]
    @Query private var allMoodEntries: [MoodEntry]

    @State private var editing: Person?
    @State private var showAddSheet = false
    @State private var showPaywall = false
    @State private var personToDelete: Person?

    private var recipients: [Person] { people.filter { !$0.isSelf } }

    private var canAddMore: Bool {
        subscriptionManager.canAddRecipient(currentRecipientCount: recipients.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                Text("YOU")
                    .font(.poppins(.medium, size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                if let me = people.first(where: \.isSelf) {
                    personRow(me, canEdit: true, canDelete: false)
                }

                Text("CARE RECIPIENTS")
                    .font(.poppins(.medium, size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                if recipients.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(recipients.enumerated()), id: \.element.id) { index, person in
                            personRow(person, canEdit: true, canDelete: true)
                            if index < recipients.count - 1 {
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                Button {
                    if canAddMore {
                        editing = nil
                        showAddSheet = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(PastelTheme.dark)
                        Text(canAddMore ? "Add Care Recipient" : "Upgrade to add more")
                            .font(.poppins(.medium, size: 15))
                            .foregroundStyle(PastelTheme.dark)
                        Spacer()
                        if !canAddMore {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(PastelTheme.light, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .pressable()

                if !canAddMore {
                    Text("Free plan includes 1 care recipient. Upgrade to manage unlimited people.")
                        .font(.poppins(.regular, size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
            .padding(.bottom, 10)
        }
        .scrollContentBackground(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(PastelTheme.gradient.ignoresSafeArea())
        .navigationDestination(isPresented: $showAddSheet) {
            PersonFormView(person: nil)
        }
        .navigationDestination(item: $editing) { person in
            PersonFormView(person: person)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(
            "Delete \(personToDelete?.displayName ?? "")?",
            isPresented: Binding(
                get: { personToDelete != nil },
                set: { if !$0 { personToDelete = nil } }
            ),
            presenting: personToDelete
        ) { person in
            Button("Delete", role: .destructive) { deletePerson(person) }
            Button("Cancel", role: .cancel) {}
        } message: { person in
            Text(deleteWarning(for: person))
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PastelTheme.dark)
                    .frame(width: 40, height: 40)
                    .background(PastelTheme.light.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Care Recipients")
                .font(.poppins(.bold, size: 20))
                .foregroundStyle(.primary)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 32))
                .foregroundStyle(PastelTheme.primary)
            Text("No care recipients yet")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(PastelTheme.dark)
            Text("Add a loved one to track their\nmeds, appointments, and mood.")
                .font(.poppins(.regular, size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func personRow(_ person: Person, canEdit: Bool, canDelete: Bool) -> some View {
        HStack(spacing: 12) {
            Text(person.avatarEmoji)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(PastelTheme.light.opacity(0.6))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(person.displayName)
                    .font(.poppins(.semiBold, size: 15))
                    .foregroundStyle(.primary)
                if !person.relation.isEmpty {
                    Text(person.relation)
                        .font(.poppins(.regular, size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if person.id == personContext.activePersonID {
                Text("Active")
                    .font(.poppins(.medium, size: 11))
                    .foregroundStyle(PastelTheme.dark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PastelTheme.light.opacity(0.6))
                    .clipShape(Capsule())
            }

            Menu {
                Button {
                    personContext.activePersonID = person.id
                } label: {
                    Label("Set as active", systemImage: "checkmark.circle")
                }
                if canEdit {
                    Button {
                        editing = person
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                if canDelete {
                    Divider()
                    Button(role: .destructive) {
                        personToDelete = person
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(canEdit && canDelete ? .clear : .white)
        .clipShape(RoundedRectangle(cornerRadius: canDelete ? 0 : 12))
        .shadow(color: canDelete ? .clear : .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func ownedCounts(for person: Person) -> (medicines: Int, supplements: Int, appointments: Int, moods: Int) {
        let id = person.id
        return (
            allMedicines.filter { $0.personId == id }.count,
            allSupplements.filter { $0.personId == id }.count,
            allAppointments.filter { $0.personId == id }.count,
            allMoodEntries.filter { $0.personId == id }.count
        )
    }

    private func deleteWarning(for person: Person) -> String {
        let counts = ownedCounts(for: person)
        var parts: [String] = []
        if counts.medicines > 0 { parts.append("\(counts.medicines) medicine\(counts.medicines == 1 ? "" : "s")") }
        if counts.supplements > 0 { parts.append("\(counts.supplements) supplement\(counts.supplements == 1 ? "" : "s")") }
        if counts.appointments > 0 { parts.append("\(counts.appointments) appointment\(counts.appointments == 1 ? "" : "s")") }
        if counts.moods > 0 { parts.append("\(counts.moods) mood entr\(counts.moods == 1 ? "y" : "ies")") }

        if parts.isEmpty {
            return "This will remove \(person.displayName). This cannot be undone."
        }
        let list = parts.joined(separator: ", ")
        return "This will remove \(person.displayName) and \(list). This cannot be undone."
    }

    private func deletePerson(_ person: Person) {
        let id = person.id

        for med in allMedicines where med.personId == id {
            modelContext.delete(med)
        }
        for sup in allSupplements where sup.personId == id {
            modelContext.delete(sup)
        }
        for appt in allAppointments where appt.personId == id {
            modelContext.delete(appt)
        }
        for mood in allMoodEntries where mood.personId == id {
            modelContext.delete(mood)
        }

        modelContext.delete(person)
        try? modelContext.save()

        if personContext.activePersonID == id {
            personContext.activePersonID = people.first(where: \.isSelf)?.id
        }

        Task {
            let allMeds = (try? modelContext.fetch(FetchDescriptor<Medicine>())) ?? []
            let allSupps = (try? modelContext.fetch(FetchDescriptor<Supplement>())) ?? []
            let allPeople = (try? modelContext.fetch(FetchDescriptor<Person>())) ?? []
            await notificationManager.scheduleAllReminders(medicines: allMeds, supplements: allSupps, people: allPeople)
        }

        personToDelete = nil
    }
}

#Preview {
    NavigationStack {
        ManagePeopleView()
    }
    .modelContainer(for: [Person.self, Medicine.self, Supplement.self, Appointment.self, MoodEntry.self], inMemory: true)
    .environment(PersonContext())
    .environment(SubscriptionManager())
    .environment(NotificationManager())
}
