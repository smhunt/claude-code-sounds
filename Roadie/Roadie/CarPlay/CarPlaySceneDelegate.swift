import CarPlay
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?
    var conversationManager: ConversationManager?

    private var tabTemplate: CPTabBarTemplate?
    private var modeTemplates: [AppMode: CPListTemplate] = [:]
    private var currentMode: AppMode = .drive

    // MARK: - Scene Lifecycle

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController

        guard Config.shared.hasValidApiKey else {
            showSetupRequired()
            return
        }

        setupTabBar()
        setupConversationManager()
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        conversationManager?.stopListening()
        self.interfaceController = nil
    }

    // MARK: - Setup

    private func showSetupRequired() {
        let item = CPListItem(text: "Setup Required", detailText: "Open Claude on your iPhone to get started")
        item.handler = { _, completion in completion() }

        let section = CPListSection(items: [item])
        let template = CPListTemplate(title: "Claude", sections: [section])

        interfaceController?.setRootTemplate(template, animated: true, completion: nil)
    }

    private func setupTabBar() {
        var templates: [CPListTemplate] = []

        for mode in [AppMode.drive, .music, .games, .chat] {
            let template = createModeTemplate(mode: mode)
            modeTemplates[mode] = template
            templates.append(template)
        }

        tabTemplate = CPTabBarTemplate(templates: templates)
        tabTemplate?.delegate = self

        interfaceController?.setRootTemplate(tabTemplate!, animated: true, completion: nil)
    }

    private func createModeTemplate(mode: AppMode) -> CPListTemplate {
        let listenItem = CPListItem(text: "Tap to Speak", detailText: mode.welcomeMessage)
        listenItem.handler = { [weak self] _, completion in
            self?.conversationManager?.currentMode = mode
            self?.conversationManager?.toggleListening()
            completion()
        }

        // Sample prompts for this mode
        let hints = mode.placeholderHints.prefix(2).map { hint -> CPListItem in
            let item = CPListItem(text: hint, detailText: nil)
            item.handler = { _, completion in completion() }
            return item
        }

        let section = CPListSection(items: [listenItem] + hints)
        let template = CPListTemplate(title: mode.displayName, sections: [section])
        template.tabTitle = mode.displayName
        template.tabImage = UIImage(systemName: mode.icon)

        return template
    }

    private func setupConversationManager() {
        conversationManager = ConversationManager(carPlayDelegate: self)
        conversationManager?.currentMode = currentMode
        conversationManager?.onStatusChange = { [weak self] status in
            self?.updateCurrentModeStatus(status)
        }
        conversationManager?.onMessageReceived = { [weak self] role, content in
            if role == "assistant" {
                self?.updateLastResponse(content)
            }
        }
        conversationManager?.onStreamChunk = { [weak self] _ in
            // Could update in real-time but CarPlay updates are expensive
        }
        conversationManager?.startListening()
    }

    // MARK: - Updates

    private func updateCurrentModeStatus(_ status: String) {
        guard let template = modeTemplates[currentMode] else { return }

        DispatchQueue.main.async {
            let listenItem = CPListItem(text: status, detailText: "Tap to speak")
            listenItem.handler = { [weak self] _, completion in
                self?.conversationManager?.toggleListening()
                completion()
            }

            let section = CPListSection(items: [listenItem])
            template.updateSections([section])
        }
    }

    private func updateLastResponse(_ content: String) {
        guard let template = modeTemplates[currentMode] else { return }

        // Truncate for CarPlay
        let truncated = String(content.prefix(100)) + (content.count > 100 ? "..." : "")

        DispatchQueue.main.async {
            let responseItem = CPListItem(text: "Claude", detailText: truncated)
            responseItem.handler = { _, completion in completion() }

            let listenItem = CPListItem(text: "Tap to Speak", detailText: nil)
            listenItem.handler = { [weak self] _, completion in
                self?.conversationManager?.toggleListening()
                completion()
            }

            let section = CPListSection(items: [responseItem, listenItem])
            template.updateSections([section])
        }
    }

    func updateTerminal(text: String) {
        // Legacy support - not used with new UI
    }
}

// MARK: - Tab Bar Delegate

extension CarPlaySceneDelegate: CPTabBarTemplateDelegate {

    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        guard let listTemplate = selectedTemplate as? CPListTemplate,
              let title = listTemplate.tabTitle,
              let mode = AppMode.allCases.first(where: { $0.displayName == title }) else {
            return
        }

        currentMode = mode
        conversationManager?.currentMode = mode

        // Reset the template for the new mode
        let listenItem = CPListItem(text: "Tap to Speak", detailText: mode.welcomeMessage)
        listenItem.handler = { [weak self] _, completion in
            self?.conversationManager?.toggleListening()
            completion()
        }

        let hints = mode.placeholderHints.prefix(2).map { hint -> CPListItem in
            let item = CPListItem(text: hint, detailText: nil)
            item.handler = { _, completion in completion() }
            return item
        }

        let section = CPListSection(items: [listenItem] + hints)
        listTemplate.updateSections([section])
    }
}
