import SwiftUI
import SwiftData

struct PersonSwitcherSheet: View {
    @Environment(PersonContext.self) private var personContext
    @Environment(\.dismiss) private var dismiss

    @Query private var peopleRaw: [Person]

    var onManageTapped: () -> Void

    private var people: [Person] {
        peopleRaw.sorted { lhs, rhs in
            if lhs.isSelf != rhs.isSelf { return lhs.isSelf }
            if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
            return lhs.createdAt < rhs.createdAt
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                            personRow(person)
                            if index < people.count - 1 {
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    addRecipientButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PastelTheme.softWhite)
    }

    private func personRow(_ person: Person) -> some View {
        Button {
            personContext.activePersonID = person.id
            dismiss()
        } label: {
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
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PastelTheme.dark)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pressable()
    }

    private var addRecipientButton: some View {
        Button {
            onManageTapped()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(PastelTheme.dark)
                Text("Add Care Recipient")
                    .font(.poppins(.medium, size: 15))
                    .foregroundStyle(PastelTheme.dark)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
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
    }
}

#Preview {
    PersonSwitcherSheet(onManageTapped: {})
        .modelContainer(for: [Person.self], inMemory: true)
        .environment(PersonContext())
}
