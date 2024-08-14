import SwiftUI
import StripePaymentSheet
import Kingfisher

struct FeaturedItemView: View {
    @ObservedObject var stripeService = StripeService()
    @State private var moveGradient = true
    let imageUrl: String

    var body: some View {
        ZStack {
            VStack {
                Rectangle()
                    .overlay {
                        LinearGradient(
                            colors: [hexStringToColor(hex: "#C01616"), .blue, hexStringToColor(hex: "#C01616")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .offset(x: moveGradient ? 0 : 100)
                    }
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: moveGradient)
                    .mask {
                        Text("FEATURED")
                            .font(.caption)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [hexStringToColor(hex: "#C01616"), .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .background(.clear)
                    }
                    .onAppear {
                        self.moveGradient.toggle()
                    }
                    .background(.clear)
            }
            .offset(y: -40)
            Circle()
                .stroke(LinearGradient(
                  gradient: Gradient(colors: [hexStringToColor(hex: "#C01616"), .blue]),
                  startPoint: .topLeading, endPoint: .bottomTrailing),
                  lineWidth: 4
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(360))
                .foregroundColor(.blue)
                .overlay(
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                )
        }
  }
}
