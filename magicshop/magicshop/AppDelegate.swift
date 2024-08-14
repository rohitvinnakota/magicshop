import UIKit
import AVFoundation
import AWSMobileClient

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
        
        AWSMobileClient.default().initialize { (userState, error) in
            if let error = error {
                print("Error initializing AWSMobileClient: \(error.localizedDescription)")
            } else if let userState = userState {
                print("AWSMobileClient initialized with userState: \(userState.rawValue)")
            }
        }

        return true
    }
}
