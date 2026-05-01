import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @Environment(PersonContext.self) private var personContext
    @Environment(SubscriptionManager.self) private var subscriptionManager

    enum CareMode: String {
        case justMe, lovedOne, both
    }

    enum Step: Hashable {
        case intro(Int)
        case audience
        case recipient
        case finish
    }

    private let introPages: [(icon: String, title: String, subtitle: String)] = [
        (
            "AppLogo",
            "Welcome to\nMeds Diary",
            "Managing medications can be tough.\nWe're here to make it easier."
        ),
        (
            "pill.circle.fill",
            "Track with ease",
            "Add your medicines and supplements\nat your own pace — no rush."
        ),
        (
            "bell.circle.fill",
            "Gentle reminders",
            "We'll send friendly nudges so you\nnever have to worry about forgetting."
        ),
        (
            "face.smiling",
            "Your wellbeing matters",
            "Track your mood and see how\ntaking care of yourself makes a difference."
        ),
    ]

    @State private var step: Step = .intro(0)
    @State private var showContent = false
    @State private var careMode: CareMode = .justMe
    @State private var draftRecipients: [DraftRecipient] = []
    @State private var showRecipientSheet = false
    @State private var editingRecipient: DraftRecipient?
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .pastelGradientBackground()
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) { showContent = true }
        }
        .sheet(isPresented: $showRecipientSheet) {
            RecipientDraftSheet(initial: editingRecipient) { saved in
                if let editing = editingRecipient,
                   let idx = draftRecipients.firstIndex(where: { $0.id == editing.id }) {
                    draftRecipients[idx] = saved
                } else {
                    draftRecipients.append(saved)
                }
                editingRecipient = nil
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .intro(let index):
            introContent(index: index)
        case .audience:
            audienceContent
        case .recipient:
            recipientContent
        case .finish:
            finishContent
        }
    }

    // MARK: - Intro pages

    private func introContent(index: Int) -> some View {
        let page = introPages[index]
        return VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                if page.icon == "AppLogo" {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        .padding(.bottom, 8)
                } else {
                    Image(systemName: page.icon)
                        .font(.system(size: 64))
                        .foregroundStyle(PastelTheme.primary)
                        .padding(.bottom, 8)
                }

                Text(page.title)
                    .font(.poppins(.bold, size: 28))
                    .foregroundStyle(PastelTheme.dark)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.poppins(.regular, size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            indicatorDots(active: index, total: introPages.count + 1)
                .padding(.bottom, 24)

            primaryButton("Continue") {
                advanceFromIntro(currentIndex: index)
            }
            skipButton {
                step = .audience
            }
        }
    }

    private func advanceFromIntro(currentIndex: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentIndex < introPages.count - 1 {
                step = .intro(currentIndex + 1)
            } else {
                step = .audience
            }
        }
    }

    // MARK: - Audience selection

    private var audienceContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            VStack(spacing: 12) {
                Text("Who is this app for?")
                    .font(.poppins(.bold, size: 26))
                    .foregroundStyle(PastelTheme.dark)
                    .multilineTextAlignment(.center)

                Text("You can manage care for yourself,\na loved one, or both.")
                    .font(.poppins(.regular, size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                audienceCard(
                    icon: "person.fill",
                    title: "Just me",
                    subtitle: "Track my own meds and appointments.",
                    mode: .justMe
                )
                audienceCard(
                    icon: "heart.fill",
                    title: "A loved one",
                    subtitle: "Care for someone else (parent, partner, child).",
                    mode: .lovedOne
                )
                audienceCard(
                    icon: "person.2.fill",
                    title: "Both",
                    subtitle: "Manage my care and a loved one's together.",
                    mode: .both
                )
            }

            Spacer()

            indicatorDots(active: introPages.count, total: introPages.count + 1)
                .padding(.bottom, 24)

            primaryButton("Continue") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = (careMode == .justMe) ? .finish : .recipient
                }
            }
        }
    }

    private func audienceCard(icon: String, title: String, subtitle: String, mode: CareMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { careMode = mode }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(PastelTheme.dark)
                    .frame(width: 44, height: 44)
                    .background(PastelTheme.light.opacity(0.6))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.poppins(.semiBold, size: 16))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.poppins(.regular, size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: careMode == mode ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(careMode == mode ? PastelTheme.dark : PastelTheme.light)
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(careMode == mode ? PastelTheme.dark : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .pressable()
    }

    // MARK: - Recipient form

    private var recipientContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            VStack(spacing: 12) {
                Text("Add the person you're caring for")
                    .font(.poppins(.bold, size: 24))
                    .foregroundStyle(PastelTheme.dark)
                    .multilineTextAlignment(.center)

                Text(canAddMoreFreeRecipients
                     ? "You can always add or edit more later in Settings."
                     : "Free plan includes 1 recipient — upgrade for unlimited.")
                    .font(.poppins(.regular, size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(draftRecipients) { recipient in
                        Button {
                            editingRecipient = recipient
                            showRecipientSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Text(recipient.avatarEmoji)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(PastelTheme.light.opacity(0.6))
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recipient.name)
                                        .font(.poppins(.semiBold, size: 15))
                                        .foregroundStyle(.primary)
                                    if !recipient.relation.isEmpty {
                                        Text(recipient.relation)
                                            .font(.poppins(.regular, size: 13))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .pressable()
                    }

                    Button {
                        if canAddMoreFreeRecipients {
                            editingRecipient = nil
                            showRecipientSheet = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(PastelTheme.dark)
                            Text(draftRecipients.isEmpty ? "Add a care recipient" : "Add another")
                                .font(.poppins(.medium, size: 15))
                                .foregroundStyle(PastelTheme.dark)
                            Spacer()
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
            .frame(maxHeight: 320)

            Spacer()

            indicatorDots(active: introPages.count, total: introPages.count + 1)
                .padding(.bottom, 16)

            primaryButton(draftRecipients.isEmpty ? "Skip for now" : "Continue") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = .finish
                }
            }
        }
    }

    private var canAddMoreFreeRecipients: Bool {
        subscriptionManager.canAddRecipient(currentRecipientCount: draftRecipients.count)
    }

    // MARK: - Finish

    private var finishContent: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(PastelTheme.dark)
                    .padding(.bottom, 8)

                Text("You're all set")
                    .font(.poppins(.bold, size: 28))
                    .foregroundStyle(PastelTheme.dark)
                    .multilineTextAlignment(.center)

                Text(finishSubtitle)
                    .font(.poppins(.regular, size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            indicatorDots(active: introPages.count, total: introPages.count + 1)
                .padding(.bottom, 24)

            primaryButton("Get Started") {
                completeOnboarding()
            }
        }
    }

    private var finishSubtitle: String {
        switch careMode {
        case .justMe:
            return "Let's start tracking your meds,\nappointments, and wellbeing."
        case .lovedOne:
            return draftRecipients.isEmpty
                ? "You can add a care recipient anytime\nfrom Settings."
                : "Switch between people anytime from\nthe home screen."
        case .both:
            return draftRecipients.isEmpty
                ? "You can add care recipients anytime\nfrom Settings."
                : "Switch between yourself and your\nloved ones from the home screen."
        }
    }

    // MARK: - Completion

    private func completeOnboarding() {
        let selfPerson = Person(name: "Me", relation: "Self", isSelf: true)
        modelContext.insert(selfPerson)

        var insertedRecipients: [Person] = []
        for draft in draftRecipients {
            let person = Person(
                name: draft.name,
                relation: draft.relation,
                isSelf: false,
                colorHex: draft.colorHex,
                avatarEmoji: draft.avatarEmoji
            )
            modelContext.insert(person)
            insertedRecipients.append(person)
        }

        try? modelContext.save()

        switch careMode {
        case .lovedOne:
            personContext.activePersonID = insertedRecipients.first?.id ?? selfPerson.id
        case .justMe, .both:
            personContext.activePersonID = selfPerson.id
        }

        hasSeenOnboarding = true
    }

    // MARK: - Reusable bits

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.poppins(.semiBold, size: 18))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(PastelTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func skipButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Skip")
                .font(.poppins(.regular, size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private func indicatorDots(active: Int, total: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == active ? PastelTheme.dark : PastelTheme.dark.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Draft recipient model

struct DraftRecipient: Identifiable, Hashable {
    let id: UUID
    var name: String
    var relation: String
    var avatarEmoji: String
    var colorHex: String

    init(id: UUID = UUID(), name: String, relation: String = "", avatarEmoji: String = "🙂", colorHex: String = "#6B9BF2") {
        self.id = id
        self.name = name
        self.relation = relation
        self.avatarEmoji = avatarEmoji
        self.colorHex = colorHex
    }
}

// MARK: - Recipient sheet (used in onboarding)

private struct RecipientDraftSheet: View {
    let initial: DraftRecipient?
    let onSave: (DraftRecipient) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var relation: String = ""
    @State private var avatarEmoji: String = "🙂"

    private let emojiChoices = ["🙂", "👵", "👴", "👩", "👨", "🧒", "👶", "🧑‍🦰", "🧑‍🦱", "🧑‍🦳", "🐶", "🐱"]
    private let relationSuggestions = ["Mom", "Dad", "Spouse", "Partner", "Child", "Grandparent", "Sibling", "Friend", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Required", text: $name)
                        .textInputAutocapitalization(.words)
                }

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

                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiChoices, id: \.self) { emoji in
                            Button {
                                avatarEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(avatarEmoji == emoji ? PastelTheme.light.opacity(0.6) : Color.clear)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(avatarEmoji == emoji ? PastelTheme.dark : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(initial == nil ? "New Recipient" : "Edit Recipient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onSave(DraftRecipient(
                            id: initial?.id ?? UUID(),
                            name: trimmed,
                            relation: relation.trimmingCharacters(in: .whitespaces),
                            avatarEmoji: avatarEmoji,
                            colorHex: initial?.colorHex ?? "#6B9BF2"
                        ))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let initial {
                    name = initial.name
                    relation = initial.relation
                    avatarEmoji = initial.avatarEmoji
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(PersonContext())
        .environment(SubscriptionManager())
        .modelContainer(for: [Person.self, Appointment.self, Medicine.self, Supplement.self, MoodEntry.self], inMemory: true)
}
