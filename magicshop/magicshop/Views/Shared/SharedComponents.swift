import SwiftUI

struct ExitButtonView: View {
    var body: some View {
        NavigationLink(destination: ContentView()) {
            Button(action: {}) {
                Image(systemName: "x.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(Constants.crayolaRedColor)
            }

        }
    }
}

struct ExitButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ExitButtonView()
    }
}

// Custom function to use hex codes because Apple thinks there is no need for in-built support for this
// in 2023
func hexStringToColor(hex: String) -> Color {
    var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if cString.hasPrefix("#") {
        cString.remove(at: cString.startIndex)
    }

    if cString.count != 6 {
        return Color.gray
    }

    var rgbValue: UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return Color(UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    ))
}
