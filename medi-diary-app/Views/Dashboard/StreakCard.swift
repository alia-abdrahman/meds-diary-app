import SwiftUI

struct StreakCard: View {
    let streak: Int
    let weeklyPercentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Streak counter
            HStack(spacing: 8) {
                Text(streak > 0 ? "🔥" : "💪")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(streakTitle)
                        .font(.poppins(.bold, size: 20))
                        .foregroundStyle(PastelTheme.dark)

                    Text(StreakManager.encouragementMessage(for: streak))
                        .font(.poppins(.regular, size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Weekly adherence
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("This week")
                        .font(.poppins(.medium, size: 13))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(weeklyPercentage))%")
                        .font(.poppins(.semiBold, size: 13))
                        .foregroundStyle(adherenceColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(PastelTheme.light.opacity(0.5))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(adherenceColor)
                            .frame(width: geometry.size.width * min(weeklyPercentage / 100, 1.0), height: 8)
                    }
                }
                .frame(height: 8)

                Text(weeklyMessage)
                    .font(.poppins(.regular, size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private var streakTitle: String {
        if streak == 0 {
            return "No Streak Yet"
        } else if streak == 1 {
            return "1 Day Streak!"
        } else {
            return "\(streak) Day Streak!"
        }
    }

    private var adherenceColor: Color {
        switch weeklyPercentage {
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    private var weeklyMessage: String {
        switch weeklyPercentage {
        case 100: return "Perfect week! You didn't miss a single dose."
        case 80..<100: return "Almost perfect — you're doing great!"
        case 50..<80: return "Good effort — let's aim higher this week!"
        default: return "Every dose counts — you've got this!"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StreakCard(streak: 12, weeklyPercentage: 95)
        StreakCard(streak: 0, weeklyPercentage: 30)
    }
    .padding()
    .background(PastelTheme.gradient)
}
