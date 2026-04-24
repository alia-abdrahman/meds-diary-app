import AuthenticationServices
import Foundation

@Observable
final class AuthenticationManager: NSObject {
    private(set) var isSignedIn = false
    private(set) var userName: String?
    private(set) var userEmail: String?

    private static let userIDKey = "appleUserID"
    private static let userNameKey = "appleUserName"
    private static let userEmailKey = "appleUserEmail"

    private static let migrationDoneKey = "keychainMigrationDone"

    private var emailRecoveryContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        migrateToKeychainIfNeeded()

        if let userID = KeychainHelper.load(key: Self.userIDKey) {
            isSignedIn = true
            userName = KeychainHelper.load(key: Self.userNameKey)
            userEmail = KeychainHelper.load(key: Self.userEmailKey)
            verifyCredential(userID: userID)
        }
    }

    func signIn(with authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        let userID = credential.user
        KeychainHelper.save(key: Self.userIDKey, value: userID)

        // Apple only provides name and email on first sign-in
        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                KeychainHelper.save(key: Self.userNameKey, value: name)
                userName = name
            }
        }

        let email = credential.email ?? emailFromIdentityToken(credential.identityToken)
        if let email {
            KeychainHelper.save(key: Self.userEmailKey, value: email)
            userEmail = email
        }

        isSignedIn = true
    }

    func signOut() {
        KeychainHelper.delete(key: Self.userIDKey)
        KeychainHelper.delete(key: Self.userNameKey)
        // Keep email in Keychain — Apple only provides it on first sign-in
        isSignedIn = false
        userName = nil
        userEmail = nil
    }

    func deleteAccountData() {
        KeychainHelper.delete(key: Self.userIDKey)
        KeychainHelper.delete(key: Self.userNameKey)
        KeychainHelper.delete(key: Self.userEmailKey)
        isSignedIn = false
        userName = nil
        userEmail = nil
    }

    private func verifyCredential(userID: String) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { [weak self] state, _ in
            DispatchQueue.main.async {
                if state == .revoked {
                    self?.signOut()
                }
            }
        }
    }

    /// Silently re-authenticates with Apple to recover email from identity token
    func recoverEmailIfNeeded() async {
        guard isSignedIn, userEmail == nil else { return }

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        // No scopes needed — just need the identity token

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        await withCheckedContinuation { continuation in
            emailRecoveryContinuation = continuation
            controller.performRequests()
        }
    }

    private func emailFromIdentityToken(_ tokenData: Data?) -> String? {
        guard let data = tokenData,
              let jwt = String(data: data, encoding: .utf8) else { return nil }

        let segments = jwt.split(separator: ".")
        guard segments.count == 3 else { return nil }

        // Decode the payload (second segment)
        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Pad to multiple of 4
        while base64.count % 4 != 0 { base64.append("=") }

        guard let payloadData = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let email = json["email"] as? String else { return nil }

        return email
    }

    // MARK: - One-time migration from UserDefaults/iCloud KVS → Keychain

    private func migrateToKeychainIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.migrationDoneKey) else { return }

        let keys = [Self.userIDKey, Self.userNameKey, Self.userEmailKey]

        for key in keys {
            // Prefer iCloud KVS, fall back to UserDefaults
            let value = NSUbiquitousKeyValueStore.default.string(forKey: key)
                ?? UserDefaults.standard.string(forKey: key)

            if let value, !value.isEmpty {
                KeychainHelper.save(key: key, value: value)
            }

            // Clean up old storage
            UserDefaults.standard.removeObject(forKey: key)
            NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
        }

        UserDefaults.standard.set(true, forKey: Self.migrationDoneKey)
    }
}

// MARK: - ASAuthorizationControllerDelegate (email recovery)
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let email = credential.email ?? emailFromIdentityToken(credential.identityToken)
            if let email {
                KeychainHelper.save(key: Self.userEmailKey, value: email)
                userEmail = email
            }
        }
        emailRecoveryContinuation?.resume()
        emailRecoveryContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Email recovery failed: \(error)")
        emailRecoveryContinuation?.resume()
        emailRecoveryContinuation = nil
    }
}
