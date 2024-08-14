import SwiftUI

struct ChatView: View {
    @StateObject var chatManager = IVSChatManager()

    @EnvironmentObject var sessionManager: SessionManager
    @State var chatRoomArn: String
    @State var draft: String = ""
    @State var isSending: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var glowSize: CGFloat = 0.0

    var body: some View {
        ZStack {
            HStack(spacing: .zero) {
                TextField("Send a message", text: $draft)
                    .font(Font.custom("Avenir", size: 18))
                    .padding(.horizontal, 30)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .fontWeight(.bold)
                    .shadow(color: .purple, radius: glowSize)
                    .animation(Animation.easeInOut(duration: 1))
                    .onAppear {
                        self.glowSize = 10
                    }
                    .onDisappear {
                        self.glowSize = 0
                    }
                SendButton() { [message = draft] in
                    draft = ""
                    isSending.toggle()
                    UIApplication.shared.endEditing()

                    Task {
                        try await chatManager.sendMessage(messageText: message)
                        isSending.toggle()
                    }
                }
                .disabled(isSending)
            }
            .padding(.bottom, keyboardHeight / 3) // Adjust the bottom padding based on keyboard height
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .zIndex(3)
            VStack {
                MessageList(messages: $chatManager.messages)
                    .offset(y: 160)
                    .frame(height: UIScreen.main.bounds.height / 2.8)
            }
        }
        .onAppear {
            chatManager.getUserChatToken(chatRoomArn: chatRoomArn)
            UIApplication.shared.isIdleTimerDisabled = true
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }

            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            chatManager.getUserChatToken(chatRoomArn: chatRoomArn)
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

struct SendButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "paperplane.fill")
                .padding()
                .background(Color(.tintColor))
                .foregroundColor(.white)
        }
        .clipShape(Circle())
        .padding()
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct GlowingTextField: View {
    @State private var glowSize: CGFloat = 0.0
    @State var draft: String = ""

    var body: some View {
        TextField("Send a message", text: $draft)
            .font(Font.custom("Avenir", size: 18))
            .padding(.horizontal, 30)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .fontWeight(.bold)
            .shadow(color: .purple, radius: glowSize)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
            .onAppear {
                self.glowSize = 10
            }
            .onDisappear {
                self.glowSize = 0
            }
    }
}
