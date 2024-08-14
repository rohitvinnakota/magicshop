import SwiftUI

@main
struct magicshopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var sessionManager = SessionManager()
    @StateObject var appState = AppState.shared

    init() {
        configureAmplify()
        congigureStripe()
        sessionManager.getCurrentAuthUser()
        setupUserDefaults()
    }

    var body: some Scene {
        WindowGroup {
            switch sessionManager.authState {
            case .login:
                LoginView().environmentObject(sessionManager)
            case .signUp:
                SignupView().environmentObject(sessionManager)
            case .confirmCode(let userEmail):
                ConfirmUserView(userEmail: userEmail).environmentObject(sessionManager)
            case .session:
                ContentView().environmentObject(sessionManager).id(appState.appId)
            }
        }
    }

    private func congigureStripe() {
        StripeAPI.defaultPublishableKey = Bundle.main.object(forInfoDictionaryKey: "stripePublishableKey") as? String
    }

    private func setupUserDefaults() {
        let userDefaultsManager = UserDefaultsManager.shared
        if userDefaultsManager.getMutedUsers().isEmpty {
            userDefaultsManager.setMutedUsers([])
        }
    }

    private func startDataStore() {
        let semaphore = DispatchSemaphore(value: 0)
        Amplify.DataStore.start { result in
            switch result {
            case .success:
                print("DataStore started")
                semaphore.signal()
            case .failure(let error):
                print("Error starting DataStore: \(error)")
                semaphore.signal()
            }
        }

        semaphore.wait()
        print("DataStore start completed")
    }

    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure()
            // FOR DEV ONLY, do not clear if running live
            try Amplify.DataStore.clear()
            self.startDataStore()
            print("AMPLIFY CONFIGURED")
        } catch {
            print("FAILED TO SETUP AMPLIFY", error)
        }
    }
}
