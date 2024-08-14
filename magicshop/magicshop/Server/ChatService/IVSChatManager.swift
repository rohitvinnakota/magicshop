import Amplify
import Foundation
import SwiftUI
import AmazonIVSChatMessaging

class IVSChatManager: ObservableObject {
    // IVS Object
    private var room: ChatRoom?
    private var chatToken: ChatToken?
    private var tokenRequest: TokenRequest?
    private var retrievedUser: String?
    // All messages in room
    @Published var messages: [MessageViewModel] = []
    @Published var isConnected: Bool = false
    init() {
        self.tokenRequest = TokenRequest()
        UserDBGateway.getUserFromAmplifyId(userId: UserDefaults.standard.string(forKey: "userIdIdentifier") ?? ""
) { result in
            switch result {
            case .success(let user):
                self.retrievedUser = user.userName
            case .failure(let error):
                print("Failed to retrieve user with error: \(error)")
            }
        }
    }

    // Fetches chat token from server for a user with SEND MESSAGE capability. Lasts for 180 minutes.
    func getUserChatToken(chatRoomArn: String) {
        Task(priority: .background) {
            if room?.state != .disconnected {
                room?.disconnect()
            }

            if room != nil {
                room?.delegate = nil
                room = nil
            }
            self.room = ChatRoom(awsRegion: "us-east-1") {
                let data = try await self.tokenRequest?.fetchChatTokenForUser(chatRoomArn: chatRoomArn)
                let authToken = try JSONDecoder().decode(TokenResponse.self, from: data!)
                return ChatToken(token: authToken.token)
            }
            room?.delegate = self
            try await room?.connect()
        }
    }

    func sendMessage(messageText: String) async {
        room?.sendMessage(with: SendMessageRequest(
            content: messageText,
            attributes: ["username": self.retrievedUser ?? "Anonymous"]),
                          onSuccess: { _ in },
                          onFailure: { error in
            print("❌ error sending message: \(error)")
        })
    }
}

// Setup to read events from room once it is connected
extension IVSChatManager: ChatRoomDelegate {
    // TODO: Add support once user is kicked
    func roomDidConnect(_ room: ChatRoom) {
    }

    // CREATE A MESSAGE MODEL, READS ONCE A MESSAGE IS RECIEVED, YOU PROBABLY WANT THE DISPLAY NAME, and maybe a picture
    func room(_ room: ChatRoom, didReceive message: ChatMessage) {
        print(message.attributes)
        DispatchQueue.main.async {
            let viewModel = MessageViewModel(
                id: message.id,
                content: message.content,
                username: message.attributes!["username"] ?? "Anonymous"
            )
            self.messages.append(viewModel)
        }
    }

    func roomDidDisconnect(_ room: ChatRoom) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
}

struct TokenResponse: Decodable {
    let sessionExpirationTime: String
    let token: String
    let tokenExpirationTime: String
}

struct TokenRequest: Codable {
    enum UserCapability: String, Codable {
        case deleteMessage = "DELETE_MESSAGE"
        case disconnectUser = "DISCONNECT_USER"
        case sendMessage = "SEND_MESSAGE"
    }

    func fetchChatTokenForUser(chatRoomArn: String) async throws -> Data {
        let authSession = URLSession(configuration: .default)
        let requestUrl = Constants.createChatTokenUrl
        var request = URLRequest(url: requestUrl)
        let headers = ["roomId": chatRoomArn, "userId": UserDefaults.standard.string(forKey: "userIdIdentifier") ?? "", "capabilities": "user"]
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        return try await authSession.data(for: request).0
    }
}
