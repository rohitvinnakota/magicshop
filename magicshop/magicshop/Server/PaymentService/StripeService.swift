import StripePaymentSheet
import SwiftUI
import Foundation
import Amplify

@MainActor
class StripeService: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var currentProduct: ProductCardViewModel?
    @Published var allProducts: [ProductCardViewModel]? = []
    @Published var sellerStripeAccountId = ""
    @Published var shippingInfo: Any? = nil
    @Published var isBuyVisible: Bool = false 
    @Published var shippingInfoPreview: String = ""
    private var customerStripeId = ""
    private let retryDelay: TimeInterval = 5 // the number of seconds to wait before retrying

    let addressConfiguration = AddressViewController.Configuration(
      allowedCountries: ["US", "CA"],
      title: "Shipping Address"
    )

    func preparePaymentSheet(paymentAmount: Int) {
        Task(priority: .background) {
            let authSession = URLSession(configuration: .default)
            var request = URLRequest(url: Constants.backendCheckoutUrl)
            request.httpMethod = "POST"
            request.setValue(self.sellerStripeAccountId, forHTTPHeaderField: "accountId")
            request.setValue(self.customerStripeId, forHTTPHeaderField: "customerId")
            request.setValue("\(paymentAmount)", forHTTPHeaderField: "paymentAmount")
            var data = try await authSession.data(for: request).0
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            let customerId = json?["customer"] as? String
            let customerEphemeralKeySecret = json?["ephemeralKey"] as? String
            let paymentIntentClientSecret = json?["paymentIntent"] as? String
            let publishableKey = json?["publishableKey"] as? String
            STPAPIClient.shared.publishableKey = publishableKey
            // MARK: Create a PaymentSheet instance
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Magicshop marketplace and technologies"
            configuration.customer = .init(id: customerId!, ephemeralKeySecret: customerEphemeralKeySecret!)
            configuration.applePay = .init(
              merchantId: "merchant.com.magicshop",
              merchantCountryCode: "CA"
            )
            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret!, configuration: configuration)
            }
        }
    }

    func fetchProductsAndPrices(accountId: String) {
        self.sellerStripeAccountId = accountId
        let requestUrl = Constants.backendFetchProductsAndPricesUrl
        let headers = ["accountId": accountId]
        Utils.getJSON(from: requestUrl, headers: headers) { (result) in
            switch result {
            case .success(let json):
                if let productAndPricesArray = json["prices"] as? [[String: Any]] {
                    var products = [ProductCardViewModel]()
                    for productPriceObject in productAndPricesArray {
                        let productCardViewModelObject = ProductCardViewModel(
                            id: (productPriceObject["product.id"] as? String)! ?? "",
                            description: productPriceObject["product.description"] as? String ?? "",
                            imageURL: productPriceObject["product.images.0"] as? String ?? "",
                            name: productPriceObject["product.name"] as? String ?? "",
                            unitAmount: Int(productPriceObject["unit_amount"] as? Int ?? 0),
                            currency: productPriceObject["currency"] as? String ?? ""
                        )
                        products.append(productCardViewModelObject)
                    }
                    DispatchQueue.main.async {
                        self.allProducts = products
                        if(!products.isEmpty) {
                            self.currentProduct = products[0]
                        }
                    }
                }
            case .failure(let error):
                print("FAILED")
                print(error)
            }
        }
    }

    func onPaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
    }
    
    // TODO: Combine into one express query if we ever scale LOL
    func fetchProductsAndPricesForChannel(channelArn: String) {
        Task.detached{
            let authSession = URLSession(configuration: .default)
            var request = URLRequest(url: Constants.stripeAccIDURL)
            request.httpMethod = "GET"
            request.setValue(channelArn, forHTTPHeaderField: "channelArn")
            
            do {
                let (data, response) = try await authSession.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let stripeAccId = json["stripeConnectAccountId"] as? String {
                        await self.fetchProductsAndPrices(accountId: stripeAccId)
                    }
                } else {
                    print("Request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                }
            } catch {
                print("An error occurred: \(error)")
            }
        }
    }


    func fetchUserShippingAddresses() {
        Task(priority: .background) {
            let authSession = URLSession(configuration: .default)
            var request = URLRequest(url: Constants.searchCustomerUrl)
            request.httpMethod = "POST"
            request.setValue(UserDefaults.standard.string(forKey: "userIdIdentifier") ?? "", forHTTPHeaderField: "customerAmplifyUserId")
            var data = try await authSession.data(for: request).0
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            let customer = json?["customer"] as? [String: Any]
            let customerId = customer?["id"] as? String
            let shipping = customer?["shipping"] as? [String: Any]
            DispatchQueue.main.async {
                self.shippingInfo = shipping
                self.isBuyVisible = shipping == nil ? false : true
                if let customerId = customerId {
                    self.customerStripeId = customerId
                    self.setShippingInfoPreview(shipping: shipping)
                } else {
                    // customerId is nil, retry after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay) {
                        self.fetchUserShippingAddresses()
                    }
                }
            }
        }
    }

    func setShippingInfoPreview(shipping: [String: Any]?) {
        let name = shipping?["name"] as? String
        let address = shipping? ["address"] as? [String: Any]
        let line1 = address?["line1"] as? String
        self.shippingInfoPreview = "Ships to: " + (name ?? "") + ", " + (line1 ?? "")
    }
    
    func updateCustomerShippingInfo(line1: String, line2: String?, firstName: String,
                                    lastName: String, city: String, stateOrProvince: String, postalCode: String, country: String) {
        Task(priority: .background) {
            let authSession = URLSession(configuration: .default)
            var request = URLRequest(url: Constants.updateCustomerShippingInfoUrl)
            request.httpMethod = "POST"
            request.setValue(customerStripeId, forHTTPHeaderField: "customerStripeId")
            request.setValue(line1, forHTTPHeaderField: "shippingAddressLine1")
            request.setValue(line2, forHTTPHeaderField: "shippingAddressLine2")
            request.setValue(city, forHTTPHeaderField: "shippingAddressCity")
            request.setValue(stateOrProvince, forHTTPHeaderField: "shippingAddressState")
            request.setValue(postalCode, forHTTPHeaderField: "shippingAddressPostalCode")
            request.setValue(country, forHTTPHeaderField: "shippingAddressCountry")
            request.setValue(firstName + " " + lastName, forHTTPHeaderField: "customerFullName")

            var data = try await authSession.data(for: request).0
            DispatchQueue.main.async {
                self.shippingInfo = line1
                self.isBuyVisible = true
            }
        }
    }
}

struct ShippingAddress {
    var city: String // City, district, suburb, town, or village.
    var country: String // Two-letter country code (ISO 3166-1 alpha-2).
    var line1: String // Address line 1 (e.g., street, PO Box, or company name).
    var line2: String? // Address line 2 (e.g., apartment, suite, unit, or building).
    var postalCode: String // ZIP or postal code.
    var state: String? // State, county, province, or region.
}
