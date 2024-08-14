import AmazonIVSBroadcast

class BroadcastDelagate: UIViewController, IVSBroadcastSession.Delegate {
    var broadcastManager: BroadcastManager?
    var sessionState: IVSBroadcastSession.State = .disconnected

    func broadcastSession(_ session: IVSBroadcastSession, didChange state: IVSBroadcastSession.State) {
        DispatchQueue.main.async { [weak self] in

            self?.broadcastManager?.sessionIsRunning = false

            switch state {
            case .invalid:
                print("ℹ️ IVSBroadcastSession state is invalid")
                self?.sessionState = .invalid
            case .connecting:
                print("ℹ️ IVSBroadcastSession state is connecting")
                self?.sessionState = .connecting
            case .connected:
                print("ℹ️ IVSBroadcastSession state is connected")
                self?.broadcastManager?.sessionIsRunning = true
                self?.broadcastManager?.isReconnecting = false
                self?.sessionState = .connected
            case .disconnected:
                print("ℹ️ IVSBroadcastSession state is disconnected")
                self?.sessionState = .disconnected
            case .error:
                print("ℹ️ IVSBroadcastSession state is error")
                self?.sessionState = .error
            @unknown default:
                print("ℹ️ IVSBroadcastSession state is unknown")
            }
        }
    }

    func broadcastSession(_ session: IVSBroadcastSession, didEmitError error: Error) {
        print("❌ IVSBroadcastSession did emit error \(error)")
        DispatchQueue.main.async { [weak self] in
            self?.broadcastManager?.errorMessage = error.localizedDescription
            if (error as NSError).code == 10405 {
                self?.broadcastManager?.reconnectOnceNetworkIsAvailable()
            } else if (error as NSError).code == 0 {
                self?.broadcastManager?.reconnect()
            }
        }
    }

    func broadcastSession(_ session: IVSBroadcastSession, didAddDevice descriptor: IVSDeviceDescriptor) {
        print("📲 IVSBroadcastSession did discover device \(descriptor)")
    }

    func broadcastSession(_ session: IVSBroadcastSession, didRemoveDevice descriptor: IVSDeviceDescriptor) {
        print("📱 IVSBroadcastSession did lose device \(descriptor)")
    }

    func broadcastSession(_ session: IVSBroadcastSession, audioStatsUpdatedWithPeak peak: Double, rms: Double) {
        // This fires frequently, so we don't log it here.
    }
}
