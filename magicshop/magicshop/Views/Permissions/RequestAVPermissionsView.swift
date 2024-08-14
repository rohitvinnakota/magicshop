import SwiftUI
import AmazonIVSBroadcast

// When a user tries to broadcast, we want to request their device permissions to record
// audio and video
struct AVPermissionsView: View {
    @State var isLoading: Bool = true
    @State var cameraPermissionGranted: Bool = false
    @State var microphonePermissionGranted: Bool = false
    @State var allPermissionsGranted: Bool = false
    @State var hasUserDeniedPermissions: Bool = false
    @StateObject private var broadcastManager = BroadcastManager()
    @EnvironmentObject var sessionManager: SessionManager
    var spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)

    private func checkPermissionsGranted() {
        cameraPermissionGranted = checkPermission(for: .video)
        microphonePermissionGranted = checkPermission(for: .audio)
        allPermissionsGranted = cameraPermissionGranted && microphonePermissionGranted
        isLoading = false
    }

    private func checkPermission(for mediaType: AVMediaType) -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            return true
        case .denied, .restricted:
            hasUserDeniedPermissions = true
            return false
        case .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    private func getPermission(for mediaType: AVMediaType, _ result: @escaping () -> Void) {
        func mainThreadResult() {
            DispatchQueue.main.async {
                result()
            }
        }
        AVCaptureDevice.requestAccess(for: mediaType) { _ in
            mainThreadResult()
        }
    }

    var body: some View {
        if isLoading {
            ProgressView()
                .onAppear {
                    checkPermissionsGranted()
                }
                .progressViewStyle(CircularProgressViewStyle())
        }
        // TODO: FINISH THIS VIEW
        else if broadcastManager.isNotSeller {
            HStack {
                Text("You are not registered to broadcast yet. Please contact us at admin@magicshophq.com." +
                     "If you have recently registered to broadcast, please allow a few minutes and check back to get selling with Magicshop!")
                    .font(Font.custom("Avenir", size: 18))
            }
        } else {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                if hasUserDeniedPermissions {
                    Text("Please enable camera and microphone in Settings to livestream")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                } else if !allPermissionsGranted {
                    VStack {
                        Text("Please allow the following device permissions to continue")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 20)

                        if !cameraPermissionGranted {
                            PermissionModal(
                                title: "Camera Access",
                                description: "Allow this app to capture device video",
                                isOn: $cameraPermissionGranted
                            ) {
                                getPermission(for: .video) {
                                    checkPermissionsGranted()
                                }
                            }
                            .padding(.top, 10)
                        }
                        if !microphonePermissionGranted {
                            PermissionModal(
                                title: "Microphone Access",
                                description: "Allow this app to capture device audio",
                                isOn: $microphonePermissionGranted
                            ) {
                                getPermission(for: .audio) {
                                    checkPermissionsGranted()
                                }
                            }
                        }
                    }
                } else {
                    BroadcastView(broadcastManager: broadcastManager)
                        .environmentObject(sessionManager)
                }
            }
        }
    }
}

struct AVPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        AVPermissionsView()
    }
}
