import SwiftUI

struct MessageRow: View {
    let message: MessageViewModel
    @State private var isShowingPopup = false
    @State private var isMutedAlertPresented = false
    @State private var isUserMuted = false

    var body: some View {
        if !isUserMuted {
            HStack {
                Text(message.username + ": ")
                    .font(Font.custom("Avenir", size: 18))
                    .foregroundColor(Constants.crayolaRedColor)
                    .fontWeight(.bold)
                    .contextMenu {
                        Button(action: {
                            muteUser(username: message.username)
                        }) {
                            Text("Mute")
                            Image(systemName: "volume.slash")
                        }
                        Button(action: {
                            muteUser(username: message.username)
                        }) {
                            Text("Block")
                            Image(systemName: "nosign")
                        }
                    }
                Text(message.content)
                    .font(Font.custom("Avenir", size: 18))
                    .foregroundColor(Constants.silverCreamColor)
                    .fontWeight(.bold)
                    .offset(x: -10)
            }
            .foregroundColor(Color.white)
            .cornerRadius(8)
            .padding(.bottom, 7)
            .frame(maxWidth: UIScreen.main.bounds.size.width / 1.1, alignment: .leading)
            .onAppear {
                checkIfUserIsMuted()
            }
        }
        Text("")
            .alert(isPresented: $isMutedAlertPresented, content: {
                Alert(
                    title: Text("User Muted"),
                    message: Text("You have muted " + message.username + ". Please contact us from the Settings page if you would like to report a user."),
                    dismissButton: .default(Text("OK"))
                )
            })
    }
    
    private func muteUser(username: String) {
        isMutedAlertPresented = true
        var mutedUsers = UserDefaultsManager.shared.getMutedUsers()
        mutedUsers.append(username)
        UserDefaultsManager.shared.setMutedUsers(mutedUsers)
        isUserMuted = true
    }
    
    private func checkIfUserIsMuted() {
        let mutedUsers = UserDefaultsManager.shared.getMutedUsers()
        isUserMuted = mutedUsers.contains(message.username)
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        MessageRow(
            message: MessageViewModel(
                id: UUID().uuidString,
                content: "This is a message",
                username: "Bob"
            )
        )
        .previewLayout(.sizeThatFits)
    }
}
