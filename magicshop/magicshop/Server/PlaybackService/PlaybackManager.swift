import AVFoundation
import AmazonIVSPlayer
import SwiftUI
import Amplify
import Combine

class PlaybackManager: ObservableObject {
    @ObservedObject var stripeService = StripeService()
    var cancellables = Set<AnyCancellable>() // declare cancellables

    let playbackModel = PlaybackModel()
    @Published var sellerStripeAccountId = ""
    @Published var isPlaying: Bool = false {
        didSet {
            self.objectWillChange.send()
        }
    }
    var productsAndPrices: Any = {}

    init() {
        self.playbackModel.$isPlaying.sink { [weak self] playing in
            self?.isPlaying = playing
        }.store(in: &cancellables)
        configureAudio()
    }

    func startPlayback(customPlaybackUrl: String) {
        playbackModel.play(customPlaybackUrl)
    }

    private func configureAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            let portOverride = AVAudioSession.PortOverride.speaker
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(portOverride)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    // Fetch playbackUrl from StreamInfo and start the stream
    func fetchPlaybackUrlAndStartPlayback(channelArn: String) {
        let streamInfoKeys = StreamInfo.keys
        Amplify.DataStore.query(StreamInfo.self, where: streamInfoKeys.channelArn == channelArn) {
            switch $0 {
            case .success(let result):
                DispatchQueue.main.async {
                    self.startPlayback(customPlaybackUrl: result.first?.awsIVSPlaybackURL ?? "")
                }
            case.failure(let error):
                print("Error fetching stream - \(error.localizedDescription)")
            }
        }
    }
}

struct IVSPlayerViewWrapper: UIViewRepresentable {
    let playerView: IVSPlayerView?

    func makeUIView(context: Context) -> IVSPlayerView {
        guard let view = playerView else {
            print("ℹ No actual player view passed to wrapper. Returning new IVSPlayerView")
            return IVSPlayerView()
        }
        return view
    }

    func updateUIView(_ uiView: IVSPlayerView, context: Context) {}
}
