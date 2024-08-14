import SwiftUI
import StripePaymentSheet

struct StripeCheckoutView: View {
    @EnvironmentObject var stripeService: StripeService
    @State private var scale: CGFloat = 1.0
    @State var channelArn: String
    @Binding var showCurrentProduct: Bool

    var body: some View {
        ZStack {
            FeaturedItemView(imageUrl: stripeService.currentProduct?.imageURL ?? "")
        }
        .frame(height: 50)
        .onTapGesture {
            withAnimation {
                if (stripeService.currentProduct != nil) {
                    showCurrentProduct.toggle()
                }
            }
        }
        .position(x: UIScreen.main.bounds.width - 50)
        .onAppear {
            stripeService.fetchProductsAndPricesForChannel(channelArn: channelArn)
        }
    }
}
