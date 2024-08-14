import SwiftUI
import MessageUI
import UIKit
import Amplify

struct SettingsView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isPrivacyPolicyViewPresented = false
    @State private var isContactUsViewPresented = false
    @State private var isReportViewPresented = false
    @State private var isDeleteAccountViewPresented = false

    var body: some View {
        NavigationView { // Wrap the entire view in a NavigationView
            VStack(spacing: 0) {
                // Sign out button
                Button(action: {
                    sessionManager.signOut()
                }) {
                    Text("Sign out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .font(Font.custom("Avenir", size: 18))
                }

                NavigationLink(destination: ContactUsView(textToShow: "Please contact us for any inquiries or feedback."), isActive: $isContactUsViewPresented) {
                    EmptyView() // Hidden NavigationLink, only used for navigation
                }
                Button(action: {
                    isContactUsViewPresented = true
                }) {
                    Text("Contact us")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .font(Font.custom("Avenir", size: 18))
                }
                // Report a user button
                NavigationLink(destination: ContactUsView(textToShow: "Please contact us to report harmful behavior. It would be helpful to " +
                    "include as much detail as possible including the store, time, and users participating in any bad practices."), isActive: $isReportViewPresented) {
                    EmptyView() // Hidden NavigationLink, only used for navigation
                }
                Button(action: {
                    isReportViewPresented = true
                }) {
                    Text("⚠️ Report a user")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .font(Font.custom("Avenir", size: 18))
                }

                // Privacy Policy button with NavigationLink
                NavigationLink(destination: PrivacyPolicyView(), isActive: $isPrivacyPolicyViewPresented) {
                    EmptyView() // Hidden NavigationLink, only used for navigation
                }
                Button(action: {
                    isPrivacyPolicyViewPresented = true // Activate the NavigationLink
                }) {
                    Text("Privacy Policy")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .font(Font.custom("Avenir", size: 18))
                }
                Button(action: {
                    isDeleteAccountViewPresented = true // Activate the NavigationLink
                }) {
                    Text("❌ Delete Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(Color.red)
                        .background(Color.clear)
                        .font(Font.custom("Avenir", size: 18))
                }
            }
            .padding(.top, 20) // Add padding at the top
            .alert(isPresented: $isDeleteAccountViewPresented) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account? We will miss you."),
                    primaryButton: .default(
                        Text("Delete")
                            .foregroundColor(.red)
                    ) {
                        Amplify.Auth.deleteUser()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
