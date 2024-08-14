import SwiftUI
import Kingfisher
import StripePaymentSheet

struct ProductCardView: View {
    let viewModels: [ProductCardViewModel]
    @Binding var showCurrentProduct: Bool
    @State private var currentIndex = 0
    @State private var currentPaymentAmount = 0
    @State private var showAddressSheet = false
    @State private var isAddingAddress = false
    @State private var isShippingAddressFilled = false
    @State private var settingsDetent = PresentationDetent.medium
    @State private var triggerRefresh = 0
    
    @EnvironmentObject var stripeService: StripeService
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModels.indices, id: \.self) { index in
                                KFImage(URL(string: viewModels[index].imageURL))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                                    .padding(5)
                                    .blur(radius: currentIndex == index ? 0 : 3)
                                    .onTapGesture {
                                        withAnimation {
                                            currentIndex = index
                                            currentPaymentAmount = viewModels[index].unitAmount
                                        }
                                    }
                            }
                        }
                        .refreshable {}
                    }
                    .refreshable {}
                    .frame(height: 120)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .animation(.spring())
                }
                let priceString = "$" + String(format: "%.2f", Double(viewModels[currentIndex].unitAmount) / 100)
                Text("💸 " + priceString)
                    .foregroundColor(Color.cyan)
                    .padding()
                    .font(Font.custom("Avenir", size: 18))
                Text(viewModels[currentIndex].name)
                    .font(Font.custom("Avenir", size: 24))
                    .foregroundColor(Constants.silverCreamColor)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                    .background(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                Text(viewModels[currentIndex].description)
                    .foregroundColor(Constants.silverCreamColor)
                    .padding()
                    .animation(.easeInOut)
                    .font(Font.custom("Avenir", size: 18))
                Spacer()
                VStack {
                    if let address = stripeService.shippingInfo {
                        Text(stripeService.shippingInfoPreview)
                            .foregroundColor(Constants.silverCreamColor)
                            .font(Font.custom("Avenir", size: 18))
                        Button("Change Address") {
                            showAddressSheet = true
                        }
                        .font(Font.custom("Avenir", size: 18))
                    } else {
                        Button("Add Shipping Address") {
                            showAddressSheet = true
                        }
                        .font(Font.custom("Avenir", size: 18))
                    }
                }
                .sheet(isPresented: $showAddressSheet) {
                    ShippingAddressCollectionView(dismissAction: {showAddressSheet = false})
                        .presentationDetents(
                            [.medium],
                            selection: $settingsDetent
                         )
                        .environmentObject(stripeService)
                        .refreshable {}
                        .onDisappear {
                            stripeService.fetchUserShippingAddresses()
                        }
                }
                .background(hexStringToColor(hex: "161618"))
                Spacer()
                if stripeService.isBuyVisible {
                    PaymentSheetView(currentPaymentAmount: $currentPaymentAmount, showCurrentProduct: $showCurrentProduct)
                        .environmentObject(stripeService)
                }
            }
        }.onAppear {
            stripeService.fetchUserShippingAddresses()
            currentPaymentAmount = viewModels[0].unitAmount
        }
    }
}

