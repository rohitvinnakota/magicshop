import SwiftUI
import AVKit

struct PlaybackView: View {
    @ObservedObject var playbackManager = PlaybackManager()
    @StateObject var stripeService = StripeService()

    let previewPlayer = AVPlayer(url: Constants.slimePreviewURL)

    @EnvironmentObject var sessionManager: SessionManager
    @State var channelArn: String
    @State var chatRoomArn: String
    @State var showCurrentProduct = false
    @State private var settingsDetent = PresentationDetent.medium
    @State private var keyboardHeight: CGFloat = 0.0
    @State private var isReportingStream = false
    @State private var isBlockingStream = false
    @State private var showActionSheet = false

    var isPresented: Bool {
        return showCurrentProduct && stripeService.currentProduct != nil
    }

    var body: some View {
        // Here we either play a static video as a placeholder(for testing or otherwise) or the livestream URL if the seller is live
        ZStack {
            if (!playbackManager.isPlaying) {
                RemoteVideoPlayerView(videoURL: Constants.slimePreviewURL)
            } else {
                IVSPlayerViewWrapper(playerView: playbackManager.playbackModel.playerView)
                    .background(Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1))
            }

            Button(action: { showActionSheet = true }) {
                Image(systemName: "flag")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .position(x: UIScreen.main.bounds.width - 30, y: 30)
            .padding(.trailing, 20)
            .padding(.top, 20)
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Report Stream"),
                    buttons: [
                        .default(Text("Report")
                            .font(Font.custom("Avenir", size: 18)))
                        { isReportingStream = true },
                        .destructive(Text("Block")
                            .font(Font.custom("Avenir", size: 18))
                        ) { isBlockingStream = true },
                        .cancel()
                    ]
                )
            }

            StripeCheckoutView(channelArn: channelArn, showCurrentProduct: $showCurrentProduct)
                .offset(x: 0, y: UIScreen.main.bounds.width / 1.5)
                .zIndex(2)
                .environmentObject(stripeService)
                .backgroundStyle(Constants.crayolaRedColor)

            Button(action: { AppState.shared.appId = UUID() }) {
                Image(systemName: "chevron.backward")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .position(x: 20, y: 30)
            .padding(.leading, 20)
            .padding(.top, 20)

            ChatView(chatRoomArn: chatRoomArn)
                .alert(isPresented: $isReportingStream) {
                    Alert(
                        title: Text("Report Stream"),
                        message: Text("Are you sure you want to report this stream? You will no longer be able to view the stream and our team will investigate the issue." +
                                      " To specify more details, you may reach out to us via the Settings tab"),
                        primaryButton: .default(
                            Text("Report")
                                .foregroundColor(.red)
                        ) {
                            blockStream()
                        },
                        secondaryButton: .cancel()
                    )
                }
                .alert(isPresented: $isBlockingStream) {
                    Alert(
                        title: Text("Block Stream"),
                        message: Text("Are you sure you want to block this stream? You will no longer be able to view the stream and our team will investigate the issue." +
                                      " To specify more details, you may reach out to us via the Settings tab"),
                        primaryButton: .default(
                            Text("Block")
                                .foregroundColor(.red)
                        ) {
                            blockStream()
                        },
                        secondaryButton: .cancel()
                    )
                }
        }
        .sheet(isPresented: $showCurrentProduct) {
            VStack(alignment: .center) {
                ProductCardView(viewModels: stripeService.allProducts!, showCurrentProduct: $showCurrentProduct)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .environmentObject(stripeService)
                    .transition(.move(edge: .top))
                    .zIndex(5)
                    .presentationDetents(
                        [.medium, .large],
                        selection: $settingsDetent
                    )
            }
            .padding(.top, 40)
            .background(hexStringToColor(hex: "161618"))
        }


        .onAppear {
            playbackManager.fetchPlaybackUrlAndStartPlayback(channelArn: channelArn)
            stripeService.fetchUserShippingAddresses()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
    }

    private func blockStream() {
        var blockedStreams = UserDefaultsManager.shared.getBlockedStreams()
        blockedStreams.append(channelArn)
        UserDefaultsManager.shared.setBlockedStreams(blockedStreams)
        AppState.shared.appId = UUID()
    }
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView(channelArn: "test", chatRoomArn: "test").environmentObject(SessionManager())
    }
}
