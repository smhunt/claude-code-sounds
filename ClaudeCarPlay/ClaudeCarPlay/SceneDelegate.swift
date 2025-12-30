import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var conversationManager: ConversationManager?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        let terminalVC = TerminalViewController()
        conversationManager = ConversationManager(terminalView: terminalVC.terminalView)
        terminalVC.conversationManager = conversationManager

        window?.rootViewController = terminalVC
        window?.makeKeyAndVisible()

        // Start listening
        conversationManager?.startListening()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        conversationManager?.stopListening()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        conversationManager?.startListening()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Keep listening in background for CarPlay
    }
}
