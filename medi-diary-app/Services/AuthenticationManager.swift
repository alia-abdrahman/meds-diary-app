import AuthenticationServices
import Foundation

@Observable
final class AuthenticationManager {
    private(set) var isSignedIn = false
    private(set) var userName: String?
    private(set) var userEmail: String?

    private static let userIDKey = "appleUserID"
    private static let userNameKey = "appleUserName"
    private static let userEmailKey = "appleUserEmail"

    private static let migrationDoneKey = "keychainMigrationDone"

    init() {
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

        if let email = credential.email {
            KeychainHelper.save(key: Self.userEmailKey, value: email)
            userEmail = email
        }

        isSignedIn = true
    }

    func signOut() {
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
