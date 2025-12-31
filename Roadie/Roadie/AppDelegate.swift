import UIKit
import AVFoundation
import Speech

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        requestPermissions()
        setupAudioSession()
        return true
    }

    private func requestPermissions() {
        // Mic permission (iOS 17+)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                print("[AppDelegate] Mic access: \(granted)")
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("[AppDelegate] Mic access: \(granted)")
            }
        }

        // Speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            print("[AppDelegate] Speech recognition: \(status.rawValue)")
        }
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // voiceChat mode optimizes for speech and works well with AirPods
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothA2DP, .allowAirPlay, .mixWithOthers]
            )
            try session.setActive(true)
        } catch {
            print("[AppDelegate] Audio session error: \(error)")
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if connectingSceneSession.role == .carTemplateApplication {
            let config = UISceneConfiguration(name: "CarPlay", sessionRole: .carTemplateApplication)
            config.delegateClass = CarPlaySceneDelegate.self
            return config
        }

        let config = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}
