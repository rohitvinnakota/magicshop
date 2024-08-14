import SwiftUI
import _AuthenticationServices_SwiftUI

struct LoginView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    @State var userName = ""
    @State var password = ""
    @State private var logoOpacity = 0.0 // Set initial opacity to 0.0
    
    var body: some View {
        VStack {
            Image("magicshopquicklogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.top, 200)
                .padding(.bottom, 30)
                .opacity(logoOpacity) // Apply the opacity animation
                .animation(.easeInOut(duration: 1)) // Set the animation duration and curve
            
            TextField("Email", text: $userName)
                .disableAutocorrection(true)
                .font(Font.custom("Avenir", size: 18))
                .padding(.vertical, 4)
            
            SecureField("Password", text: $password)
                .padding(.vertical, 8)
            
            VStack(spacing: 20) {
                Button(action: { sessionManager.login(userEmail: userName, password: password) }) {
                    Text("Login")
                        .foregroundColor(Color.white) // Adjust text color for visibility
                        .font(Font.custom("Avenir", size: 18))
                        .frame(width: 200, height: 50)
                        .background(Constants.russianVioletColor)
                        .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 20)

                SignInWithAppleButton(.continue, onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        switch authorization.credential {
                        case let cred as ASAuthorizationAppleIDCredential:
                            let email = cred.email
                            let userId = cred.user
                            sessionManager.handleSignInWithApple(userEmail: cred.email ?? nil, userId: userId)
                        default:
                            break
                        }
                    case .failure(let error):
                        // Handle error
                        break
                    }
                })
                .frame(width: 200, height: 50)
                .font(Font.custom("Avenir", size: 18))
                .foregroundColor(Constants.silverCreamColor)
                .signInWithAppleButtonStyle(.black)
            }

            Spacer()
            Button("Click here to create an account", action: sessionManager.showSignUp)
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(Constants.silverCreamColor)
        }
        
        .padding()
        .textFieldStyle(.roundedBorder)
        .background(Constants.crayolaRedColor)
        .buttonStyle(.bordered)
        .onAppear {
            logoOpacity = 1.0 // Trigger the fade in animation when the view appears
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(SessionManager())
    }
}
