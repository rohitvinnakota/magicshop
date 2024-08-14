import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let mutedUsersKey = "MutedUsers"
    private let EULAKey = "EULA"
    private let blockedStreamsKey = "blockedStreams"

    private init() {}
    
    func getMutedUsers() -> [String] {
        if let mutedUsers = UserDefaults.standard.array(forKey: mutedUsersKey) as? [String] {
            return mutedUsers
        } else {
            return []
        }
    }
    
    
    func setMutedUsers(_ mutedUsers: [String]) {
        UserDefaults.standard.set(mutedUsers, forKey: mutedUsersKey)
    }
    
    func getIsEULAAccepted() -> Bool {
        return UserDefaults.standard.bool(forKey: EULAKey)
    }
    
    func setEULAAccepted() {
        UserDefaults.standard.set(true, forKey: EULAKey)
    }
    
    func setEULAAcceptedFalse() {
        UserDefaults.standard.set(true, forKey: EULAKey)
    }
    
    func getBlockedStreams() -> [String] {
        if let blockedStreams = UserDefaults.standard.array(forKey: blockedStreamsKey) as? [String] {
            return blockedStreams
        } else {
            return []
        }
    }
    
    func setBlockedStreams(_ blockedStreams: [String]) {
        UserDefaults.standard.set(blockedStreams, forKey: blockedStreamsKey)
    }
}
