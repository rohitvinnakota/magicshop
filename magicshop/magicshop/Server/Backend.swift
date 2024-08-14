import UIKit
import Amplify

class Backend {
    static let shared = Backend()
    static func initialize() -> Backend {
        return .shared
    }
    private init() {
      // initialize amplify
      do {
        try Amplify.configure()
        print("Initialized Amplify")
      } catch {
        print("Could not initialize Amplify: \(error)")
      }
    }
}
