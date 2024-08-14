import Amplify
import SwiftUI
import AWSMobileClient
import Combine

enum AuthState {
    case signUp
    case login
    case confirmCode(userName: String)
    case session
}

enum CustomSignUpErrors: Error {
    case graphQLMutationFailure
}

// ObservableObject publishes a value that can be consumed
// This class configures functionality to handle the sign-up experience including
// logging in, sigining up, confirmation code handling, and signing out
@MainActor
final class SessionManager: ObservableObject {
    @Published var authState: AuthState = .login
    let usersDB = UserDBGateway()
    private var currentUser: String = ""
    private var savedPasswod: String = ""

    func getCurrentAuthUser() {
        if UserDefaults.standard.string(forKey: "userIdIdentifier") ?? "" != "" {
            authState = .session
            return
        }
        if let user = Amplify.Auth.getCurrentUser() {
            authState = .session
            UserDefaults.standard.set(user.userId, forKey: "userIdIdentifier")
        } else {
            showLogin()
        }
    }
    func showSignUp() {
        authState = .signUp
    }

    func showLogin() {
        authState = .login
    }

    func createNewUser(userName: String, email: String, password: String) {
        userSignUp(userName: userName, email: email, password: password)
    }

    // IMPORTANT: Currently doing the rest of this flow manually: v0
    func setupUserAttributesBackgroundThread(userName: String, userEmail: String) {
        let userSetupThread = Thread {
            while UserDefaults.standard.string(forKey: "userIdIdentifier") ?? "" == "" {
                // Wait till user attribs are set
            }
            let currentAmplifyUser = UserDefaults.standard.string(forKey: "userIdIdentifier") ?? ""
            self.usersDB.createUserAfterSignUp(
                userEmail: userEmail, userName: userName, userId: (currentAmplifyUser)
            )
        }
        userSetupThread.qualityOfService = .background
        userSetupThread.start()
    }

    func userSignUp(userName: String, email: String, password: String) {
        let attributes = [AuthUserAttribute(.email, value: email)]
        let options = AuthSignUpRequest.Options(userAttributes: attributes)
        _ = Amplify.Auth.signUp(
            username: email,
            password: password,
            options: options
        ) { result in
            switch result {
            case .success(let result):
                switch result.nextStep {
                case .done:
                    print("Completed sign-up")
                case .confirmUser(let details, _):
                    self.savedPasswod = password
                    self.currentUser = userName
                    // TODO: CLEAN UP INCORRECT VARIABLES
                    DispatchQueue.main.async {
                        self.authState = .confirmCode(userName: email)
                    }
                }
            case .failure(let error):
                print("Failed", error)
            }
        }
    }

    func confirm(userEmail: String, code: String) {
        let userNameToCreate = self.currentUser
        _ = Amplify.Auth.confirmSignUp(
            for: userEmail,
            confirmationCode: code
        ) { result in
            switch result {
            case .success(let confirmResult):
                if confirmResult.isSignupComplete {
                    Task.init {
                        self.setupUserAttributesBackgroundThread(userName: userNameToCreate, userEmail: userEmail)
                    }
                    DispatchQueue.main.async {
                        self.login(userEmail: userEmail, password: self.savedPasswod)
                    }
                }
            case .failure(let error):
                print("failed to confirm code", error)
            }
        }
    }

    func login(userEmail: String, password: String) {
        _ = Amplify.Auth.signIn(
            username: userEmail,
            password: password
        ) {  [weak self] result in
            switch result {
            case .success(let signInResult):
                if signInResult.isSignedIn {
                    DispatchQueue.main.async {
                        self?.getCurrentAuthUser()
                    }
                }
            case .failure(let error):
                print("Login error:", error)
            }
        }
    }

    func signOut() {
        // if user is signed in with Apple
        if (UserDefaults.standard.string(forKey: "userIdIdentifier") ?? "").contains(".") {
            UserDefaults.standard.set("", forKey: "userIdIdentifier")
            self.getCurrentAuthUser()
        } else {
            _ = Amplify.Auth.signOut { [weak self] result in
                switch result {
                case .success:
                    UserDefaults.standard.set("", forKey: "userIdIdentifier")
                    Amplify.DataStore.clear()
                    DispatchQueue.main.async {
                        self?.getCurrentAuthUser()
                    }
                case .failure(let error):
                    print("Login error:", error)
                }
            }
        }
    }

    func handleSignInWithApple(userEmail: String?, userId: String) {
        UserDefaults.standard.set(userId, forKey: "userIdIdentifier")
        if userEmail != nil {
            setupUserAttributesBackgroundThread(userName: generateRandomUsername(),userEmail: userEmail!)
        }
        self.getCurrentAuthUser()
    }

    func generateRandomUsername() -> String {
        let exampleEnglishWords = [
            "Sunny", "Mountain", "Ocean", "Eagle", "Adventure", "Whisper", "Dream", "Harmony",
            "Brilliant", "Moonlight", "Serenity", "Cascade", "Gentle", "Radiant", "Majestic",
            "Tranquil", "Enchanted", "Crisp", "Blossom", "Luminous", "Mystic", "Elegant",
            "Vibrant", "Ripple", "Dazzle", "Journey", "Harbor", "Calm", "Vivid", "Wonder",
            "Sapphire", "Graceful", "Twinkle", "Azure", "Enigma", "Verdant", "Cerulean",
            "Whimsical", "Aurora", "Enchanting", "Zephyr", "Ethereal", "Cascade", "Candor",
            "Lively", "Rhythmic", "Opulent", "Harmonious", "Idyllic"
        ]

        func getRandomWord(from wordList: [String]) -> String {
            let randomIndex = Int.random(in: 0..<wordList.count)
            return wordList[randomIndex]
        }

        let username = "\(getRandomWord(from: exampleEnglishWords))_\(getRandomWord(from: exampleEnglishWords))"
        return username
    }
}
