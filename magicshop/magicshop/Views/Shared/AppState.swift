import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var appId = UUID()
}
