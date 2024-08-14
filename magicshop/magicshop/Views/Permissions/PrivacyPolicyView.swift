import SwiftUI

// THIS IS AN EXAMPLE. PLEASE UPDATE AS NEEDED FOR YOUR USE CASE.

struct PrivacyPolicyView: View {
    let privacyPolicy: LocalizedStringKey = """
    **Privacy Policy for Magicshop**

    **Last updated: September 8, 2023**

    This Privacy Policy describes how "Magicshop" ("we," "our," or "us") collects, uses, and protects user data. By using our iOS app, you agree to the terms outlined in this policy.

    **1. Data Collection**

    Magicshop collects the following user data:

    - Email address: We collect your email address to create and manage your account.

    - Credit card and Apple Pay information: We securely save this data for the purpose of processing purchases and providing a seamless user experience.

    **2. Purpose of Data Collection**

    We collect and use your data for the sole purpose of enhancing your experience within the Magicshop app, including:

    - Processing payments for products and services.

    - Providing customer support.

    - Sending important account-related information.

    **3. Data Sharing**

    Magicshop does not share your data with any third parties. Your data is used exclusively for app-related purposes.

    **4. User Rights**

    - You have the right to access, update, or delete your account information. Please contact us through [contact information] to exercise these rights.

    **5. Children's Privacy**

    Magicshop is not intended for children under the age of 13. We do not knowingly collect data from children.

    **6. Data Security**

    We take data security seriously. We implement industry-standard security measures to protect your data from unauthorized access, loss, or breaches.

    **7. Data Retention**

    We retain your data only for as long as necessary to fulfill the purposes outlined in this policy or as required by law.

    **8. Contact Us**

    If you have any questions or concerns about your data, this Privacy Policy, or if you wish to exercise your rights, please contact us at admin@magicshophq.com.

    **9. Policy Updates**

    We may update this Privacy Policy from time to time. Any changes will be posted here, and the date of the last update will be revised accordingly.
    """

    var body: some View {
        ScrollView {
            Text(privacyPolicy)
                .padding()
                .font(.body) // Set the font to the body style
                .multilineTextAlignment(.leading) // Adjust alignment if needed
        }
        .navigationBarTitle("Privacy Policy")
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}
