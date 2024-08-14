import SwiftUI

struct ConfirmUserView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State var confirmationCode = ""
    let userEmail: String

    var body: some View {
        VStack {
            Spacer()
            Text("Please enter your confirmation code sent to your email: \(userEmail)")
                .font(Font.custom("Avenir", size: 18))
                .foregroundColor(Constants.silverCreamColor)
            TextField("Confirmation Code", text: $confirmationCode)
                .disableAutocorrection(true)
                .font(Font.custom("Avenir", size: 18))
            Button(action: {sessionManager.confirm(userEmail: userEmail, code: confirmationCode)}) {
                Text("Submit")
                    .foregroundColor(Constants.silverCreamColor)
                    .font(Font.custom("Avenir", size: 18))
                    .padding()
            }
            .background(RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
                .fill(Constants.nightColor))
            Spacer()
            Button("Click here to login", action: sessionManager.showLogin)
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(Constants.silverCreamColor)
        }
        .padding()
        .textFieldStyle(.roundedBorder)
        .background(Constants.crayolaRedColor)
        .buttonStyle(.bordered)
    }
}

struct ConfirmUserView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmUserView(userEmail: "test@gmail.com")
    }
}
