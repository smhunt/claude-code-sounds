import CarPlay
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?
    var conversationManager: ConversationManager?

    private var listTemplate: CPListTemplate?
    private var currentTranscript = ""

    // MARK: - Scene Lifecycle

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController

        // Check if configured
        guard Config.shared.hasValidApiKey else {
            showSetupRequired()
            return
        }

        setupMainTemplate()
        setupConversationManager()
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        conversationManager?.stopListening()
        self.interfaceController = nil
    }

    // MARK: - Templates

    private func showSetupRequired() {
        let item = CPListItem(text: "Setup Required", detailText: "Open the app on your iPhone to configure")
        item.handler = { _, completion in completion() }

        let section = CPListSection(items: [item])
        let template = CPListTemplate(title: "Claude CarPlay", sections: [section])

        interfaceController?.setRootTemplate(template, animated: true, completion: nil)
    }

    private func setupMainTemplate() {
        // Create list items for conversation
        let statusItem = CPListItem(text: "Tap to Toggle Mic", detailText: "Ready")
        statusItem.handler = { [weak self] _, completion in
            self?.conversationManager?.toggleListening()
            completion()
        }

        let newSessionItem = CPListItem(text: "New Conversation", detailText: "Start fresh")
        newSessionItem.handler = { [weak self] _, completion in
            self?.conversationManager?.newSession()
            completion()
        }

        let section = CPListSection(items: [statusItem, newSessionItem])
        listTemplate = CPListTemplate(title: "Claude", sections: [section])

        interfaceController?.setRootTemplate(listTemplate!, animated: true, completion: nil)
    }

    private func setupConversationManager() {
        conversationManager = ConversationManager(carPlayDelegate: self)
        conversationManager?.onStatusChange = { [weak self] status in
            self?.updateStatus(status)
        }
        conversationManager?.startListening()
    }

    // MARK: - Updates

    func updateTerminal(text: String) {
        currentTranscript = text

        // CarPlay has limited display - show last few lines
        let lines = text.components(separatedBy: "\n").suffix(5)
        let displayText = lines.joined(separator: "\n")

        // Update the list template with transcript
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            var items: [CPListItem] = []

            // Show transcript if we have content
            if !displayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let transcriptItem = CPListItem(text: "Latest", detailText: displayText)
                transcriptItem.handler = { _, completion in completion() }
                items.append(transcriptItem)
            }

            let statusItem = CPListItem(text: "Tap to Toggle Mic", detailText: nil)
            statusItem.handler = { [weak self] _, completion in
                self?.conversationManager?.toggleListening()
                completion()
            }
            items.append(statusItem)

            let newSessionItem = CPListItem(text: "New Conversation", detailText: nil)
            newSessionItem.handler = { [weak self] _, completion in
                self?.conversationManager?.newSession()
                completion()
            }
            items.append(newSessionItem)

            let section = CPListSection(items: items)
            self.listTemplate?.updateSections([section])
        }
    }

    private func updateStatus(_ status: String) {
        // Status updates handled through updateTerminal
    }
}
