import SwiftUI

struct ContactUsView: View {
    let textToShow: String

    var body: some View {
        ScrollView {
            Text(textToShow)
                .padding()
                .font(Font.custom("Avenir", size: 18)) // Set the font to the body style
                .multilineTextAlignment(.leading) // Adjust alignment if needed
            Link("Reach out to us at admin@magicshophq.com", destination: URL(string: "mailto:admin@magicshophq.com")!)
        }
        .navigationBarTitle("Contact us")
    }
}

