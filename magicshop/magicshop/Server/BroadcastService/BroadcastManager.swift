import AmazonIVSBroadcast
import Amplify
import Combine
import Foundation
import SwiftUI
import Foundation


class BroadcastManager: NSObject, ObservableObject {

    @Published var sessionIsRunning: Bool = false
    @Published var cameraIsOn: Bool = true
    @Published var isMuted: Bool = false
    @Published var activeCameraDescriptor: IVSDeviceDescriptor?
    @Published var settingsOpen = false
    @Published var hasBeenStarted: Bool = false
    @Published var isReconnecting: Bool = false {
        didSet { isReconnectViewVisible = isReconnecting }
    }
    @Published var isReconnectViewVisible: Bool = false
    @Published var shouldReconnect: Bool = false
    @Published var errorMessage: String?
    @Published var ingestServer: String = ""
    @Published var streamKey: String = ""
    @Published var playbackUrl: String = ""
    @Published var defaultCameraUrn: String
    @Published var isScreenSharingActive: Bool = false
    @Published var canFlipCamera: Bool = true
    @Published var canStartSession: Bool = true
    @Published var canToggleCamera: Bool = true
    @Published var isNotSeller: Bool = false
    @Published var chatRoomArn: String = ""

    let broadcastDelegate = BroadcastDelagate()
    var configurations = BroadcastConfiguration.shared
    var broadcastSession: IVSBroadcastSession? // Primary interaction point where you start broadcasting. This should exist to broadcast to
    var previewView: BroadcastPreviewView?
    var sellersSubscription: AnyCancellable?

    var availableCameraDevices: [IVSDeviceDescriptor] {
        return IVSBroadcastSession.listAvailableDevices().filter { $0.type == .camera }
    }

    private var networkMonitor: MonitorNetwork?

    // Custom image-input sources allow an application to provide its own image input to the broadcast SDK,
    // instead of being limited to the preset cameras or screen share.
    // A custom image source can be as simple as a semi-transparent watermark or static "be right back" scene,
    // or it can allow the app to do additional custom processing like adding beauty filters to the camera.
    private var customImageSource: IVSCustomImageSource?
    private var attachedCamera: IVSDevice?
    private var sessionWasRunningBeforeInterruption = false
    private var appBackgroundImageSource: IVSBackgroundImageSource?

    override init() {
        defaultCameraUrn = configurations.userDefaults.string(forKey: Constants.kDefaultCamera) ??
            IVSPresets.devices().frontCamera().first!.urn
        super.init()
        self.setIVSStreamInfo()
    }

    /**
     Fetches IVS info from DB and sets class variables for the stream
     */
    func setIVSStreamInfo() {
        Task.detached {
            let authSession = URLSession(configuration: .default)
            var request = URLRequest(url: Constants.broadcastInfoURL)
            request.httpMethod = "GET"
            request.setValue(UserDefaults.standard.string(forKey: "userIdIdentifier") ?? "", forHTTPHeaderField: "userId")

            let (data, response) = try await authSession.data(for: request)
            // Check if the response is a 404
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                self.isNotSeller = true
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let streamInfo = json["streamInfo"] as? [String: Any] {
                let awsIVSStreamKey = streamInfo["awsIVSStreamKey"] as? String
                let awsIVSPlaybackURL = streamInfo["awsIVSPlaybackURL"] as? String
                let awsIVSIngestServer = streamInfo["awsIVSIngestServer"] as? String
                let chatRoomArn = streamInfo["chatRoomArn"] as? String
                DispatchQueue.main.async {
                    self.ingestServer = awsIVSIngestServer ?? ""
                    self.playbackUrl = awsIVSPlaybackURL ?? ""
                    self.streamKey = awsIVSStreamKey ?? ""
                    self.chatRoomArn = chatRoomArn ?? ""
                }
            }
        }
    }

    /**
     Initializes the broadcast session and sets up the preview view. This should be called before attempting to start a broadcast.
     */
    func initializeBroadcastSession() {
        guard !sessionIsRunning else {
            previewView?.attachCameraPreview()
            return
        }

        if previewView == nil {
            previewView = BroadcastPreviewView(broadcastManager: self)
        }

        if activeCameraDescriptor == nil {
            let defaultCamera = availableCameraDevices.first(where: { $0.urn == defaultCameraUrn })
            activeCameraDescriptor = defaultCamera ?? IVSPresets.devices().frontCamera().first
        }

        do {
            configurations.setupSlots()
            // Create the session with a preset config and camera/microphone combination.
            broadcastSession = try IVSBroadcastSession(configuration: configurations.activeConfiguration,
                   descriptors: nil,
                   delegate: broadcastDelegate)
            broadcastDelegate.broadcastManager = self
            attachedCamera = nil
            attachDeviceCamera()
            attachDeviceMic()
        } catch {
            print("❌ Error initializing IVSBroadcastSession: \(error)")
        }
    }

    /**
     Toggles the live video broadcast. If the broadcast is running, it is stopped. If it is not running,
     it is started with the specified ingest server URL and stream key.
     */
    func toggleBroadcastSession() {
        if let session = broadcastSession, sessionIsRunning {
            session.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        } else {
            initializeBroadcastSession()
            do {
                guard let url = URL(string: ingestServer) else {
                    print("Ingest server not set or invalid")
                    return
                }
                try broadcastSession?.start(with: url, streamKey: streamKey)
                UIApplication.shared.isIdleTimerDisabled = true
            } catch {
                print("❌ Error starting IVSBroadcastSession: \(error)")
            }
        }
    }

    func toggleCamera() {
        canToggleCamera = false
        if cameraIsOn {
            attachCameraOffImage()
        } else {
            attachDeviceCamera { [weak self] in
                self?.customImageSource = nil
                self?.cameraIsOn.toggle()
                self?.canToggleCamera = true
            }
        }
    }

    func flipCamera() {
        canFlipCamera = false
        activeCameraDescriptor = getCameraDescriptor(for: attachedCamera?.descriptor().position == .back ? .front : .back)
        attachDeviceCamera { [weak self] in
            self?.canFlipCamera = true
        }
    }

    func mute() {
        isMuted.toggle()
        toggleMic(!isMuted)
    }

    func reconnectOnceNetworkIsAvailable() {
        isReconnecting = true
        sessionIsRunning = false
        shouldReconnect = true

        networkMonitor = MonitorNetwork(onNetworkAvailable: { [weak self] in
            if self?.shouldReconnect == true {
                self?.toggleBroadcastSession()
                self?.networkMonitor = nil
            }
        })
    }

    func reconnect() {
        isReconnecting = true
        sessionIsRunning = false
        toggleBroadcastSession()
    }

    func cancelAutoReconnect() {
        shouldReconnect = false
        isReconnecting = false
    }

    func deviceOrientationChanged(toLandscape: Bool) {
        if (configurations.customOrientation == .auto) {
            let configWidth = configurations.activeVideoConfiguration.size.width
            let configHeight = configurations.activeVideoConfiguration.size.height

            let width = toLandscape ? max(configWidth, configHeight) : min(configWidth, configHeight)
            let height = toLandscape ? min(configWidth, configHeight) : max(configWidth, configHeight)

            let error = configurations.updateResolution(for: CGSize(width: width, height: height))
            if error == nil {
                initializeBroadcastSession()
            }
        }
    }

    @objc func audioSessionInterrupted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        switch type {
        case .began:
            sessionWasRunningBeforeInterruption = sessionIsRunning
            if sessionIsRunning {
                toggleBroadcastSession()
            }
        case .ended:
            defer {
                sessionWasRunningBeforeInterruption = false
            }
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) && sessionWasRunningBeforeInterruption {
                toggleBroadcastSession()
            }
        @unknown default:
            break
        }
    }

    // Private functions

    private func attachDeviceCamera(_ callback: @escaping () -> Void = {}) {
        guard let activeDescriptor = activeCameraDescriptor,
              let activeCamera = IVSBroadcastSession.listAvailableDevices()
                .first(where: { $0.urn == activeDescriptor.urn }) else { return }

        if let customImageSource = customImageSource {
            broadcastSession?.detach(customImageSource, onComplete: { [weak self] in
                self?.customImageSource = nil
            })
        }

        let onComplete: ((IVSDevice?, Error?) -> Void)? = { [weak self] device, error in
            if let error = error { print("❌ Error attaching/exchanging camera: \(error)") }
            self?.attachedCamera = device
            self?.previewView?.attachCameraPreview()
            callback()
        }

        if let attachedCamera = attachedCamera {
            broadcastSession?.exchangeOldDevice(attachedCamera, withNewDevice: activeCamera, onComplete: onComplete)
        } else {
            broadcastSession?.attach(activeCamera, toSlotWithName: Constants.cameraSlotName, onComplete: onComplete)
        }
    }

    private func attachDeviceMic() {
        guard let mic = IVSBroadcastSession.listAvailableDevices().first(where: { $0.type == .microphone }) else {
            print("Cannot attach microphone - no available device with type microphone found")
            return
        }
        broadcastSession?.attach(mic, toSlotWithName: Constants.cameraSlotName, onComplete: { [weak self] (device, error)  in
            if let error = error {
                print("❌ Error attaching device microphone to session: \(error)")
            }

            self?.toggleMic(!(self?.isMuted ?? false))
        })
    }

    private func attachCameraOffImage() {
        guard let broadcastSession = broadcastSession else { return }
        // Attach custom image source to slot
        if customImageSource == nil {
            customImageSource = broadcastSession.createImageSource(withName: Constants.cameraOffSlotName)
            broadcastSession.attach(customImageSource!, toSlotWithName: Constants.cameraOffSlotName) { [weak self] error in
                if let error = error { print("❌ Error attaching custom image source: \(error)") }
                self?.cameraIsOn.toggle()
                self?.canToggleCamera = true

                if let attachedCamera = self?.attachedCamera {
                    self?.broadcastSession?.detach(attachedCamera, onComplete: { [weak self] in
                        self?.attachedCamera = nil
                    })
                }
            }
        }
    }

    private func toggleMic(_ isOn: Bool) {
        broadcastSession?.awaitDeviceChanges({ [weak self] in
            self?.broadcastSession?.listAttachedDevices()
                .filter({ $0.descriptor().type == .microphone || $0.descriptor().type == .userAudio })
                .forEach({
                    if let microphone = $0 as? IVSAudioDevice {
                        microphone.setGain(isOn ? 2 : 0)
                    }
                })
        })
    }

    private func getCameraDescriptor(for position: IVSDevicePosition) -> IVSDeviceDescriptor? {
        let defaultCamera = IVSBroadcastSession.listAvailableDevices().first(where: { $0.urn == defaultCameraUrn })

        if defaultCamera?.position == position {
            return defaultCamera
        } else {
            return IVSBroadcastSession.listAvailableDevices().last(where: { $0.type == .camera && $0.position == position })
        }
    }
}

import Network

class MonitorNetwork {
    private var networkMonitor = NWPathMonitor()
    private var onNetworkAvailable: () -> Void

    init(onNetworkAvailable: @escaping () -> Void) {
        self.onNetworkAvailable = onNetworkAvailable

        networkMonitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.onNetworkAvailable()
                self?.networkMonitor.cancel()
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}
