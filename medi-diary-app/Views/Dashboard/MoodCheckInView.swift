import SwiftUI
import SwiftData

struct MoodCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMood: Int?
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 24) {
            Text("How are you feeling today?")
                .font(.poppins(.semiBold, size: 18))
                .foregroundStyle(PastelTheme.dark)

            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        selectedMood = value
                        saveMood(value)
                    } label: {
                        Text(MoodEntry.emojis[value - 1])
                            .font(.system(size: 40))
                            .scaleEffect(selectedMood == value ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: selectedMood)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Your mood is tracked privately\nand helps you spot patterns.")
                .font(.poppins(.regular, size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 24)
        .scaleEffect(showContent ? 1 : 0.85)
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                showContent = true
            }
        }
    }

    private func saveMood(_ value: Int) {
        let entry = MoodEntry(date: Date(), mood: value)
        modelContext.insert(entry)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            dismiss()
        }
    }
}

#Preview {
    ZStack {
        PastelTheme.gradient.ignoresSafeArea()
        MoodCheckInView()
    }
    .modelContainer(for: MoodEntry.self, inMemory: true)
}
