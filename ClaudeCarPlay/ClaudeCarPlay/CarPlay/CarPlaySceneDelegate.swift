import CarPlay
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?
    var conversationManager: ConversationManager?
    private var terminalTemplate: CPInformationTemplate?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController

        // Create terminal-style template
        let items = [
            CPInformationItem(title: "Status", detail: "Listening...")
        ]

        terminalTemplate = CPInformationTemplate(
            title: "Claude Terminal",
            layout: .leading,
            items: items,
            actions: [
                CPTextButton(title: "Clear", textStyle: .cancel) { [weak self] _ in
                    self?.conversationManager?.clearConversation()
                }
            ]
        )

        interfaceController.setRootTemplate(terminalTemplate!, animated: true, completion: nil)

        // Setup conversation manager for CarPlay
        conversationManager = ConversationManager(carPlayDelegate: self)
        conversationManager?.startListening()
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        conversationManager?.stopListening()
        self.interfaceController = nil
    }

    func updateTerminal(text: String) {
        // Truncate for CarPlay display (limited space)
        let lines = text.components(separatedBy: "\n").suffix(10)
        let displayText = lines.joined(separator: "\n")

        let items = [
            CPInformationItem(title: nil, detail: displayText)
        ]

        terminalTemplate?.items = items
    }
}
