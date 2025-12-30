import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = TerminalViewController()
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when scene is released by system
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Resume if needed
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Keep listening in background for CarPlay
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save state if needed
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Prepare UI
    }
}
