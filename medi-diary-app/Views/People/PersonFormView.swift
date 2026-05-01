import SwiftUI
import SwiftData

struct PersonFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: Person?

    @State private var name: String
    @State private var relation: String
    @State private var avatarEmoji: String

    private let personEmojis: [String] = [
        "\u{1F9D1}\u{1F3FC}",                         // 🧑🏼
        "\u{1F469}\u{1F3FC}",                         // 👩🏼
        "\u{1F468}\u{1F3FC}",                         // 👨🏼
        "\u{1F475}\u{1F3FC}",                         // 👵🏼
        "\u{1F474}\u{1F3FC}",                         // 👴🏼
        "\u{1F9D3}\u{1F3FC}",                         // 🧓🏼
        "\u{1F9D2}\u{1F3FC}",                         // 🧒🏼
        "\u{1F476}\u{1F3FC}",                         // 👶🏼
        "\u{1F467}\u{1F3FC}",                         // 👧🏼
        "\u{1F466}\u{1F3FC}",                         // 👦🏼
        "\u{1F9D1}\u{1F3FC}\u{200D}\u{1F9B0}",        // 🧑🏼‍🦰
        "\u{1F469}\u{1F3FC}\u{200D}\u{1F9B0}",        // 👩🏼‍🦰
        "\u{1F468}\u{1F3FC}\u{200D}\u{1F9B0}",        // 👨🏼‍🦰
        "\u{1F9D1}\u{1F3FC}\u{200D}\u{1F9B1}",        // 🧑🏼‍🦱
        "\u{1F469}\u{1F3FC}\u{200D}\u{1F9B1}",        // 👩🏼‍🦱
        "\u{1F468}\u{1F3FC}\u{200D}\u{1F9B1}",        // 👨🏼‍🦱
        "\u{1F9D1}\u{1F3FC}\u{200D}\u{1F9B3}",        // 🧑🏼‍🦳
        "\u{1F469}\u{1F3FC}\u{200D}\u{1F9B3}",        // 👩🏼‍🦳
        "\u{1F468}\u{1F3FC}\u{200D}\u{1F9B3}",        // 👨🏼‍🦳
        "\u{1F9D1}\u{1F3FC}\u{200D}\u{1F9B2}",        // 🧑🏼‍🦲
        "\u{1F469}\u{1F3FC}\u{200D}\u{1F9B2}",        // 👩🏼‍🦲
        "\u{1F468}\u{1F3FC}\u{200D}\u{1F9B2}"         // 👨🏼‍🦲
    ]

    private let otherEmojis: [String] = [
        "🙂", "😊", "😎", "🥰", "🤗", "😇",
        "🤓", "🥳", "😴", "🤠",
        "🐶", "🐱", "🐰", "🦊", "🐻", "🐼",
        "🦁", "🐯", "🐸", "🐵",
        "❤️", "⭐", "🌟", "🌈", "🌸", "🌻"
    ]

    private let relationSuggestions = ["Mom", "Dad", "Spouse", "Partner", "Child", "Grandparent", "Sibling", "Friend", "Other"]

    init(person: Person?) {
        self.person = person
        _name = State(initialValue: person?.name ?? "")
        _relation = State(initialValue: person?.relation ?? "")
        _avatarEmoji = State(initialValue: person?.avatarEmoji ?? "🙂")
    }

    private var isEditing: Bool { person != nil }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Required", text: $name)
                    .textInputAutocapitalization(.words)
            }

            if !(person?.isSelf ?? false) {
                Section("Relation") {
                    TextField("e.g. Mom, Dad, Partner", text: $relation)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(relationSuggestions, id: \.self) { suggestion in
                                Button(suggestion) { relation = suggestion }
                                    .buttonStyle(.bordered)
                                    .tint(PastelTheme.dark)
                            }
                        }
                    }
                }
            }

            Section("People") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(personEmojis, id: \.self) { emoji in
                        avatarChoice(displayed: emoji) {
                            avatarEmoji = emoji
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Other") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(otherEmojis, id: \.self) { emoji in
                        avatarChoice(displayed: emoji) {
                            avatarEmoji = emoji
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func avatarChoice(displayed: String, onTap: @escaping () -> Void) -> some View {
        Button {
            onTap()
        } label: {
            Text(displayed)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(avatarEmoji == displayed ? PastelTheme.light.opacity(0.6) : Color.clear)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(avatarEmoji == displayed ? PastelTheme.dark : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    private var navigationTitle: String {
        if person?.isSelf == true { return "Edit Profile" }
        return isEditing ? "Edit Recipient" : "New Recipient"
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedRelation = relation.trimmingCharacters(in: .whitespaces)

        if let person {
            person.name = trimmedName
            if !person.isSelf {
                person.relation = trimmedRelation
            }
            person.avatarEmoji = avatarEmoji
        } else {
            let new = Person(
                name: trimmedName,
                relation: trimmedRelation,
                isSelf: false,
                avatarEmoji: avatarEmoji
            )
            modelContext.insert(new)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PersonFormView(person: nil)
    }
    .modelContainer(for: Person.self, inMemory: true)
}
