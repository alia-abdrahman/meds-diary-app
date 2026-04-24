import SwiftUI

struct MilestoneOverlay: View {
    let milestone: Int
    let onDismiss: () -> Void

    @State private var particles: [ConfettiParticle] = []
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Confetti particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }

            // Main content
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 60))

                Text("\(milestone) Days!")
                    .font(.poppins(.bold, size: 36))
                    .foregroundStyle(PastelTheme.dark)

                Text(milestoneMessage)
                    .font(.poppins(.regular, size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button {
                    onDismiss()
                } label: {
                    Text("Keep Going!")
                        .font(.poppins(.semiBold, size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(PastelTheme.dark)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(32)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            startConfetti()
        }
    }

    private var milestoneMessage: String {
        switch milestone {
        case 7: return "One full week of consistency!\nYou're building a great habit."
        case 14: return "Two weeks straight!\nYour dedication is paying off."
        case 30: return "A whole month!\nYou should be incredibly proud."
        case 60: return "60 days of commitment!\nYou're truly making this a lifestyle."
        case 100: return "Triple digits!\nYour consistency is inspiring."
        case 365: return "An entire year!\nYou're absolutely legendary."
        default: return "What an achievement!\nKeep up the amazing work."
        }
    }

    private func startConfetti() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<40 {
            let particle = ConfettiParticle(
                id: i,
                x: CGFloat.random(in: -screenWidth/2...screenWidth/2),
                y: -screenHeight/2,
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement()!,
                opacity: 1.0
            )
            particles.append(particle)
        }

        // Animate particles falling
        withAnimation(.easeIn(duration: 2.5)) {
            for i in particles.indices {
                particles[i].y = CGFloat.random(in: screenHeight/4...screenHeight/2)
                particles[i].x += CGFloat.random(in: -60...60)
            }
        }

        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 1.0)) {
                for i in particles.indices {
                    particles[i].opacity = 0
                }
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Milestone tracking in UserDefaults

enum MilestoneTracker {
    private static let key = "lastCelebratedMilestone"

    static var lastCelebrated: Int {
        get { UserDefaults.standard.integer(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func shouldCelebrate(streak: Int) -> Int? {
        guard let milestone = StreakManager.milestoneReached(streak: streak),
              milestone > lastCelebrated else { return nil }
        return milestone
    }

    static func markCelebrated(_ milestone: Int) {
        lastCelebrated = milestone
    }
}

#Preview {
    MilestoneOverlay(milestone: 30, onDismiss: {})
}
