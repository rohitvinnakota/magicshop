import AmazonIVSBroadcast
import Amplify

class BroadcastConfiguration {
    // Singleton instance
    static let shared = BroadcastConfiguration()

    var useCustomResolution: Bool = false
    var customResolution: String?
    var customOrientation: Orientation {
        didSet { onCustomOrientationChange() }
    }

    var activeConfiguration: IVSBroadcastConfiguration = IVSPresets.configurations().basicPortrait()
    var activeVideoConfiguration = IVSVideoConfiguration()
    var activeAudioConfiguration = IVSAudioConfiguration()

    let userDefaults = UserDefaults.standard

    init() {
        customOrientation = Orientation(rawValue: userDefaults.string(forKey: Constants.kVideoConfigurationOrientation) ?? "auto") ?? .auto

        activeConfiguration.video = activeVideoConfiguration
        activeConfiguration.audio = activeAudioConfiguration

        // Cleanup if the app was suspended while screen sharing was still active
        userDefaults.setValue(false, forKey: Constants.kReplayKitSessionHasBeenStarted)
    }

    func setupSlots() {
        let cameraSlot = IVSMixerSlotConfiguration()
        do { try cameraSlot.setName(Constants.cameraSlotName) } catch {
            print("❌ Could not set camera slot name: \(error)")
        }
        cameraSlot.preferredAudioInput = .microphone
        cameraSlot.preferredVideoInput = .camera
        cameraSlot.matchCanvasAspectMode = false
        cameraSlot.aspect = customOrientation == .auto ? .fit : .fill
        cameraSlot.zIndex = 0

        let cameraOffSlot = IVSMixerSlotConfiguration()
        do { try cameraOffSlot.setName(Constants.cameraOffSlotName) } catch {
            print("❌ Could not set camera off image slot name: \(error)")
        }
        cameraOffSlot.preferredAudioInput = .unknown
        cameraOffSlot.preferredVideoInput = .userImage
        cameraOffSlot.matchCanvasSize = true
        cameraOffSlot.matchCanvasAspectMode = true
        cameraOffSlot.zIndex = 1

        activeConfiguration.mixer.slots = [cameraSlot, cameraOffSlot]
    }

    func setResolutionTo(to resolution: Resolution) -> Error? {
        let size = Resolution.sizeFor(customOrientation, a: resolution.width, b: resolution.height)
        return updateResolution(for: size)
    }

    @discardableResult
    func updateResolution(for size: CGSize) -> Error? {
        let newSize = Resolution.sizeFor(customOrientation, a: Int(size.width), b: Int(size.height))
        do {
            try activeVideoConfiguration.setSize(newSize)
            customResolution = "\(Int(newSize.width))x\(Int(newSize.height))"
            userDefaults.setValue(newSize.width, forKey: Constants.kVideoConfigurationSizeWidth)
            userDefaults.setValue(newSize.height, forKey: Constants.kVideoConfigurationSizeHeight)
            return nil
        } catch {
            print("❌ Error updating resolution \(error)")
            return error
        }
    }

    // Private

    private func onCustomOrientationChange() {
        updateAndSave(newValue: customOrientation.rawValue, oldValue: "", key: Constants.kVideoConfigurationOrientation) {}
        guard let custom = customResolution,
              let width = custom.split(separator: "x").first as NSString?,
              let height = custom.split(separator: "x").last as NSString? else { return }

        let size = Resolution.sizeFor(customOrientation, a: Int(width.intValue), b: Int(height.intValue))
        let error = updateResolution(for: size)
        if error == nil {
            customResolution = "\(Int(size.width))x\(Int(size.height))"
        }
    }

    @discardableResult
    private func updateAndSave<T: Equatable>(newValue: T, oldValue: T, key: String, updateAction: () throws -> Void) -> Error? {
        guard newValue != oldValue else { return nil }

        do {
            try updateAction()
            userDefaults.setValue(newValue, forKey: key)
        } catch {
            return error
        }

        return nil
    }
}
