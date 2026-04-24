import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var showContent = false

    private let pages: [(icon: String, title: String, subtitle: String)] = [
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

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)

            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? PastelTheme.dark : PastelTheme.dark.opacity(0.2))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.top, 16)

            Spacer()

            // Bottom button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                    .font(.poppins(.semiBold, size: 18))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PastelTheme.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if currentPage < pages.count - 1 {
                Button {
                    hasSeenOnboarding = true
                } label: {
                    Text("Skip")
                        .font(.poppins(.regular, size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .pastelGradientBackground()
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                showContent = true
            }
        }
    }

    private func pageView(_ page: (icon: String, title: String, subtitle: String)) -> some View {
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
        .padding(.horizontal, 8)
    }
}

#Preview {
    OnboardingView()
}
