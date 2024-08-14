import Amplify
import SwiftUI

class UserDBGateway {
    func createUserAfterSignUp(userEmail: String, userName: String, userId: String) {
        let newUser = Users(id: userId, userEmail: userEmail, userName: userName)
        do {
            Amplify.API.mutate(request: .create(newUser)) { result in
                switch result {
                case .success(let newUser):
                    self.createStripeCustomer(userId: userId, userEmail: userEmail)
                case .failure(let graphQLError):
                    print("Failed to create graphQL user \(graphQLError)")
                }
            }
        }
    }
    
    func createStripeCustomer(userId: String, userEmail: String) {
        Task(priority: .background) {
            let authSession = URLSession(configuration: .default)
            var request = URLRequest(url: Constants.createCustomerUrl)
            request.httpMethod = "POST"
            request.setValue(userId, forHTTPHeaderField: "customerAmplifyUserId")
            request.setValue(userEmail, forHTTPHeaderField: "customerEmail")

            var data = try await authSession.data(for: request).0
        }
    }
    
    /// Retrieves a user from the database using the provided user ID.
    /// - Parameters:
    ///   - userId: The ID of the user to retrieve.
    ///   - completion: A closure that takes a `Result` containing either a `Users` object or an error.
    static func getUserFromAmplifyId(userId: String, completion: @escaping (Result<Users, Error>) -> Void) {
        Amplify.API.query(request: .get(Users.self, byId: userId)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let user):
                    guard let user = user else {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find user"])))
                        return
                    }
                    completion(.success(user))
                case .failure(let error):
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
