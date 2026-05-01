import Foundation

@Observable
final class PersonContext {
    private static let storageKey = "activePersonID"

    var activePersonID: UUID? {
        didSet {
            if let id = activePersonID {
                UserDefaults.standard.set(id.uuidString, forKey: Self.storageKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.storageKey)
            }
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey) {
            self.activePersonID = UUID(uuidString: raw)
        } else {
            self.activePersonID = nil
        }
    }
}
