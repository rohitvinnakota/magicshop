import SwiftUI
import AVKit

struct RemoteVideoPlayerView: View {
    let videoURL: URL
    // Replace with your sample URL for testing
    @State private var player = AVPlayer(url: Constants.slimePreviewURL)

    var body: some View {
        VideoPlayer(
            player: player)
        .onAppear {
            // Set the player to autoplay and loop
            player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
            player.play()
            player.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
            }

        }
        .onDisappear {
            player.pause()
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.8)
        .zIndex(-4)
        .allowsHitTesting(false)
    }
}
