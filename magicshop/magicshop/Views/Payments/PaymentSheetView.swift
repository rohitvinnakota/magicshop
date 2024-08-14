import SwiftUI
import Kingfisher
import StripePaymentSheet

struct PaymentSheetView: View {
    @Binding var currentPaymentAmount: Int
    @EnvironmentObject var stripeService: StripeService
    @Binding var showCurrentProduct: Bool
    
    var body: some View {
        ZStack {
            if let paymentSheet = stripeService.paymentSheet {
                Button(action: {
                }, label: {
                    PaymentSheet.PaymentButton(
                        paymentSheet: paymentSheet,
                        onCompletion: stripeService.onPaymentCompletion
                    ) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .font(Font.custom("Avenir", size: 24))
                                .foregroundColor(.white)
                                .padding(.trailing, 5)
                            Text("Buy Now")
                                .font(Font.custom("Avenir", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Constants.russianVioletColor)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    }
                })
            }
            if let result = stripeService.paymentResult {
                switch result {
                case .completed:
                    EmptyView()
                        .onAppear {
                            Toggle("Toggle", isOn: $showCurrentProduct)
                        }
                case .failed(let error):
                    EmptyView()
                case .canceled:
                    EmptyView()
                }
            }
        }
        .onAppear {
            stripeService.preparePaymentSheet(paymentAmount: currentPaymentAmount)
            stripeService.fetchUserShippingAddresses()
        }
        .onChange(of: currentPaymentAmount) { newAmount in
            stripeService.preparePaymentSheet(paymentAmount: currentPaymentAmount)
        }
    }
}
