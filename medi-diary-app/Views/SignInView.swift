import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthenticationManager.self) private var authManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("OnboardingImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 180)

            VStack(spacing: 8) {
                Text("Meds Diary")
                    .font(.poppins(.bold, size: 32))
                    .foregroundStyle(PastelTheme.dark)

                Text("Sign in to keep your health data\nsafe and private.")
                    .font(.poppins(.regular, size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                performSignIn()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 24, weight: .medium))
                    Text("Sign in with Apple")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 32)
        .pastelGradientBackground()
    }

    private func performSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = SignInDelegate(authManager: authManager)
        controller.delegate = delegate
        SignInDelegate.retainedDelegate = delegate
        controller.performRequests()
    }
}

private class SignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    static var retainedDelegate: SignInDelegate?
    let authManager: AuthenticationManager

    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        authManager.signIn(with: authorization)
        Self.retainedDelegate = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Self.retainedDelegate = nil
    }
}

#Preview {
    SignInView()
        .environment(AuthenticationManager())
}
