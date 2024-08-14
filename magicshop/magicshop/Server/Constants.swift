import SwiftUI

enum Constants {
    // swiftlint:disable identifier_name
    //Routes
    static let backendCheckoutUrl = URL(string: "YOUR_BACKEND_ROUTE/paymentSheet")! // Your backend endpoint
    static let backendFetchProductsAndPricesUrl = URL(string: "YOUR_BACKEND_ROUTE/prices")! //Fetch produts and prices for merchant
    static let createChatTokenUrl = URL(string: "YOUR_BACKEND_ROUTE/createChatToken")!
    static let createCustomerUrl = URL(string: "YOUR_BACKEND_ROUTE/createCustomer")!
    static let searchCustomerUrl = URL(string: "YOUR_BACKEND_ROUTE/searchCustomer")!
    static let updateCustomerShippingInfoUrl = URL(string: "YOUR_BACKEND_ROUTE/updateCustomerShippingInfo")!
    static let slimePreviewURL = URL(string: "YOUR_")!
    // Persistence keys
    static let kVideoConfigurationOrientation = "video_configuration_orientation"
    static let kVideoConfigurationSizeWidth = "video_configuration_size_width"
    static let kVideoConfigurationSizeHeight = "video_configuration_size_height"
    static let kDefaultCamera = "default_camera"
    static let kReplayKitSessionHasBeenStarted = "replay_kit_session_has_been_started"
    static let broadcastInfoURL = URL(string: "https://YOUR_BACKEND_ROUTE/broadcastInfo")!
    static let stripeAccIDURL = URL(string: "https://YOUR_BACKEND_ROUTE/stripeAccountId")!

    // Colors
    static let crayolaRedColor = hexStringToColor(hex: "EE4266")
    static let russianVioletColor = hexStringToColor(hex: "2A1E5C")
    static let nightColor = hexStringToColor(hex: "0A0F0D")
    static let silverCreamColor = hexStringToColor(hex: "C4CBCA")
    static let verdigrisColor = hexStringToColor(hex: "3CBBB1")
    static let yellow = Color(.sRGB, red: 0.973, green: 0.843, blue: 0.29)
    static let red = Color(.sRGB, red: 0.92, green: 0.31, blue: 0.24, opacity: 1)
    static let gray = Color(.sRGB, red: 0.922, green: 0.922, blue: 0.961)
    static let lightGray = Color(.sRGB, red: 0.692, green: 0.692, blue: 0.692)
    static let backgroundGrayLight = Color(.sRGB, red: 0.167, green: 0.167, blue: 0.167)
    static let backgroundGrayDark = Color(.sRGB, red: 0.087, green: 0.087, blue: 0.087)
    static let background = Color(.sRGB, red: 0.13, green: 0.13, blue: 0.13)
    static let backgroundButton = Color(.sRGB, red: 0.46, green: 0.46, blue: 0.46, opacity: 0.45)
    static let secondaryText = Color(.sRGB, red: 0.47, green: 0.47, blue: 0.47, opacity: 0.45)
    static let borderColor = Color(.sRGB, red: 0.22, green: 0.22, blue: 0.23)
    static let error = Color(.sRGB, red: 0.8, green: 0.257, blue: 0.183)
    static let warning = Color(.sRGB, red: 1, green: 0.814, blue: 0.337)
    static let success = Color(.sRGB, red: 0.206, green: 0.554, blue: 0.261)

    // Other
    static let cameraOffSlotName = "camera_off"
    static let cameraSlotName = "camera"
}

enum Resolution: Int, CaseIterable {
    case fullHd
    case hd
    case sd

    var width: Int {
        switch self {
        case .fullHd:
            return 1920
        case .hd:
            return 1280
        case .sd:
            return 768
        }
    }

    var height: Int {
        switch self {
        case .fullHd:
            return 1080
        case .hd:
            return 720
        case .sd:
            return 480
        }
    }

    // swiftlint:disable identifier_name
    static func sizeFor(_ orientation: Orientation, a: Int, b: Int) -> CGSize {
        var width = a
        var height = b

        switch orientation {
        case .portrait:
            width = min(a, b)
            height = max(a, b)
        case .auto, .landscape:
            width = max(a, b)
            height = min(a, b)
        case .square:
            width = min(a, b)
            height = width
        }

        return CGSize(width: width, height: height)
    }
}

enum Framerate: Int {
    case max = 60
    case mid = 30
    case low = 15
}

enum Orientation: String, CaseIterable {
    case auto, portrait, landscape, square
}
