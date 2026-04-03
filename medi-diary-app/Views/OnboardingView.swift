import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("OnboardingImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 220)

            Spacer()
                .frame(height: 8)

            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.poppins(.regular, size: 20))
                    .foregroundStyle(.secondary)

                Text("Meds Diary")
                    .font(.poppins(.bold, size: 32))
                    .foregroundStyle(PastelTheme.dark)
            }

            Text("Track your medicines, supplements\n& appointments all in one place.")
                .font(.poppins(.regular, size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                hasSeenOnboarding = true
            } label: {
                Text("Get Started")
                    .font(.poppins(.semiBold, size: 18))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PastelTheme.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 32)
        .pastelGradientBackground()
    }
}

#Preview {
    OnboardingView()
}
