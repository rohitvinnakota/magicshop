import SwiftUI

struct MerchantShopView: View {

    var body: some View {
        VStack {
            Image(systemName: "cart.circle.fill")
                .resizable()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .stroke(LinearGradient(
                            gradient: Gradient(colors: [.red, .blue]),
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .rotationEffect(.degrees(45))
                        .foregroundColor(.blue)
                )
        }
    }
}
