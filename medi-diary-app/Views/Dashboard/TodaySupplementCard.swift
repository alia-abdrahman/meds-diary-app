import SwiftUI
import SwiftData

struct TodaySupplementCard: View {
    let supplement: Supplement
    var onMarkedTaken: (() -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @State private var checkBounce = false
    @State private var glowPulse = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                let wasTaken = supplement.isTakenToday
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    supplement.toggleTakenToday()
                    checkBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    checkBounce = false
                }
                if !wasTaken { onMarkedTaken?() }
                Task {
                    let allMedicines = (try? modelContext.fetch(FetchDescriptor<Medicine>())) ?? []
                    let allSupplements = (try? modelContext.fetch(FetchDescriptor<Supplement>())) ?? []
                    await notificationManager.scheduleAllReminders(medicines: allMedicines, supplements: allSupplements)
                }
            } label: {
                Image(systemName: supplement.isTakenToday ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(supplement.isTakenToday ? PastelTheme.green : PastelTheme.pinkAccent)
                    .scaleEffect(checkBounce ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: checkBounce)
                    .background {
                        if !supplement.isTakenToday {
                            Circle()
                                .fill(PastelTheme.pinkAccent)
                                .frame(width: 22, height: 22)
                                .scaleEffect(glowPulse ? 1.8 : 1.0)
                                .opacity(glowPulse ? 0 : 0.35)
                                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false), value: glowPulse)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            glowPulse = true
                        }
                    }
            }
            .buttonStyle(.plain)

            Text(supplement.name)
                .font(.poppins(.semiBold, size: 16))
                .strikethrough(supplement.isTakenToday, color: .secondary.opacity(0.4))
                .foregroundStyle(supplement.isTakenToday ? .secondary : .primary)
                .animation(.easeInOut(duration: 0.2), value: supplement.isTakenToday)

            Spacer()

            Text(supplement.frequency)
                .font(.poppins(.regular, size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(PastelTheme.light.opacity(0.5))
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
