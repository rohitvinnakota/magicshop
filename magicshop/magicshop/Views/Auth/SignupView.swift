//
//  LoginView.swift
//  v0marketplace
//
//  Created by DEV on 2022-11-11.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State var userName = ""
    @State var userEmail = ""
    @State var password = ""
    @State var confimPassword = ""
    @State private var isChoosingUserName = false
    @State private var invalidInputs = false
    @State var invalidInputText = "Please fill out all fields"
    @State private var isEULAAccepted = false


    func isValidEmail(email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func isValidPassword(password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9\\W]).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        if passwordPredicate.evaluate(with: password) {
            invalidInputText = ""
            return true
        }
        
        invalidInputText = "Please enter a valid password. Passwords must be at least 8 characters in length and contain an uppercase letter, a lowercase letter, and a number or special character."
        return false
    }

    func doPasswordsMatch() -> Bool {
        if password != confimPassword {
            invalidInputText = "Passwords must be matching"
            return false
        }
        invalidInputText = ""
        return true
    }
    
    func isUserNameValid() -> Bool {
        if userName.isEmpty {
            invalidInputText = "Please choose a username"
            return false
        }
        invalidInputText = ""
        return true
    }

    var body: some View {
        if !isEULAAccepted {
            ScrollView {
                Text(eulaText)
                    .padding()
                Button(action: {
                    UserDefaultsManager.shared.setEULAAccepted()
                    isEULAAccepted = true
                }) {
                    Text("I Accept")
                        .foregroundColor(Color.white)
                        .font(Font.custom("Avenir", size: 18))
                        .frame(width: 200, height: 50)
                        .background(Color.purple) // Replace with your desired background color
                        .cornerRadius(5)
                }
                .padding()
            }
            .toolbar(.hidden, for: .tabBar)
        } else {
            VStack {
                Spacer()
                if invalidInputs {
                    Text(invalidInputText)
                        .font(Font.custom("Avenir", size: 18))
                        .foregroundColor(Constants.nightColor)
                }
                if isChoosingUserName {
                    Text("This will be your display name. It can be changed later.")
                        .font(Font.custom("Avenir", size: 18))
                        .foregroundColor(Constants.silverCreamColor)
                }
                TextField("Username", text: $userName, onEditingChanged: { editing in
                    isChoosingUserName = editing
                    invalidInputs = false // Reset invalidInputs when inputs change
                })
                .disableAutocorrection(true)
                .font(Font.custom("Avenir", size: 18))
                .padding(.vertical, 4)
                TextField("Enter your email", text: $userEmail)
                    .disableAutocorrection(true)
                    .font(Font.custom("Avenir", size: 18))
                    .padding(.vertical, 4)
                    .onChange(of: userEmail) { newValue in
                        if !isValidEmail(email: newValue) {
                            invalidInputText = "Please enter a valid email"
                        } else {
                            invalidInputText = ""
                        }
                        invalidInputs = false // Reset invalidInputs when inputs change
                    }
                SecureField("Password", text: $password)
                    .font(Font.custom("Avenir", size: 18))
                    .padding(.vertical, 4)
                
                SecureField("Confirm password", text: $confimPassword)
                    .font(Font.custom("Avenir", size: 18))
                    .padding(.vertical, 8)
                
                
                Button(action: {
                    Task {
                        if isValidEmail(email: userEmail) && isValidPassword(password: password) && doPasswordsMatch() && isUserNameValid() {
                            do {
                                try await sessionManager.createNewUser(
                                    userName: userName,
                                    email: userEmail,
                                    password: password)
                            } catch let error {
                                DispatchQueue.main.async {
                                    invalidInputs = true
                                    invalidInputText = "You already have an account with us. Please click below to login."
                                }
                                return
                            }
                        } else {
                            invalidInputs = true
                        }
                    }
                }) {
                    Text("Create Account")
                        .foregroundColor(Constants.silverCreamColor)
                        .padding()
                }
                .background(RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                ).fill(Constants.nightColor))
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
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView().environmentObject(SessionManager())
    }
}
