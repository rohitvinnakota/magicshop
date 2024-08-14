import AmazonIVSPlayer

class PlaybackModel: ObservableObject {
    let playbackDelegate: IVSPlayer.Delegate?

    @Published var playerView: IVSPlayerView?
    @Published var player: IVSPlayer?
    @Published var isPlaying = false {
        didSet {
            print(isPlaying)
        }
    }
    @Published var url: String {
        didSet {
            if oldValue != url, let _ = player {
                play(url)
            }
        }
    }

    init() {
        self.url = ""
        self.playbackDelegate = PlaybackDelegate()
        self.playerView = IVSPlayerView(frame: CGRect(x: 0,
                                                      y: 0,
                                                      width: UIScreen.main.bounds.width,
                                                      height: UIScreen.main.bounds.height))

        if let delegate = playbackDelegate as? PlaybackDelegate {
            delegate.playbackModel = self
        }
    }

    func play(_ playbackUrl: String) {
        url = playbackUrl
        player = IVSPlayer()

        player?.delegate = playbackDelegate
        player?.muted = false // Control whether player starts muted
        playerView?.player = player
        playerView?.videoGravity = .resizeAspectFill
        if let url = URL(string: playbackUrl) {
            print("ℹ loading playback url \(playbackUrl)")
            player?.load(url)
        }
    }
}

class PlaybackDelegate: UIViewController, IVSPlayer.Delegate {
    var playbackModel: PlaybackModel?

    func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
        switch state {
        case .idle:
            print("ℹ IVSPlayer state IDLE")
        case .ready:
            print("ℹ IVSPlayer state READY")
            player.play()
        case .buffering:
            print("ℹ IVSPlayer state BUFFERING")
        case .playing:
            print("ℹ IVSPlayer state PLAYING")
            self.playbackModel?.isPlaying = true
        case .ended:
            print("ℹ IVSPlayer state ENDED")
        @unknown default:
            print("❌ Unknown IVSPlayer state '\(state)'")
        }
    }
}
