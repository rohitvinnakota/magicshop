import SwiftUI
import AmazonIVSBroadcast

struct BroadcastView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @EnvironmentObject var sessionManager: SessionManager
    @ObservedObject private var broadcastManager: BroadcastManager
    @State private var hasUserExited = false
    @State var isControlButtonsPresent: Bool = true
    //@State var chatRoomArn: String
    init(broadcastManager: BroadcastManager) {
        self.broadcastManager = broadcastManager
    }
    var body: some View {
        if broadcastManager.chatRoomArn.isEmpty {
            ProgressView()
        }
        else if hasUserExited {
            ContentView()
        } else {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                broadcastManager.previewView
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: broadcastManager.cameraIsOn ? 0 : 24)
                    .onTapGesture {
                        withAnimation() {
                            isControlButtonsPresent.toggle()
                        }
                    }
                    .onChange(of: broadcastManager.configurations.activeVideoConfiguration) { _ in
                        broadcastManager.deviceOrientationChanged(toLandscape: verticalSizeClass == .compact)
                    }
                    .onChange(of: verticalSizeClass) { vSizeClass in
                        broadcastManager.deviceOrientationChanged(toLandscape: vSizeClass == .compact)
                    }

                if !broadcastManager.cameraIsOn {
                    ZStack {
                        Color.black
                            .edgesIgnoringSafeArea(.all)
                            .opacity(0.5)

                        VStack(spacing: 10) {
                            Image(systemName: "video.slash.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 38))
                            Text("Camera Off")
                                .foregroundColor(.white)
                        }
                    }
                }

                if broadcastManager.isReconnectViewVisible {
                    ZStack {
                        Color.black
                            .edgesIgnoringSafeArea(.all)
                            .opacity(0.7)
                        VStack(spacing: 10) {
                            Text("Reconnecting...")
                                .foregroundColor(.white)
                            Text("The connection to the server was lost. The app will automatically try to reconnect.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .frame(width: 155)
                                .padding(.top, 8)
                        }
                    }
                }
            }
            ChatView(chatRoomArn: broadcastManager.chatRoomArn)
                .opacity(isControlButtonsPresent ? 0: 1)
            Button(action: { AppState.shared.appId = UUID() }) {
                Image(systemName: "x.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Constants.crayolaRedColor)
            }
            .offset(x: 140, y: -300)
            .disabled(broadcastManager.sessionIsRunning)
            .opacity(broadcastManager.sessionIsRunning ? 0 : 1)
            //TODO: Handle Landscape mode
            VStack() {
                Spacer()
                if isControlButtonsPresent {
                    BroadcastControlButtonsView(
                        broadcastManager: broadcastManager,
                        isControlButtonsPresent: $isControlButtonsPresent
                    )
                    .environmentObject(sessionManager)
                    .frame(width: UIScreen.main.bounds.width/10, height: UIScreen.main.bounds.width/5)
                    .offset(y: 400)
                    .transition(.move(edge: .trailing))
                }
            }
            .onAppear {
                broadcastManager.initializeBroadcastSession()
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
                broadcastManager.audioSessionInterrupted(notification)
            }
            .toolbar(.hidden, for: .tabBar)
        }

    }
}
