import Foundation

// MARK: - AI Provider Protocol

protocol AIProviderDelegate: AnyObject {
    func didReceiveStreamChunk(_ text: String)
    func didCompleteStream(fullResponse: String)
    func didFailWithError(_ error: Error)
}

protocol AIProvider: AnyObject {
    var delegate: AIProviderDelegate? { get set }
    var name: String { get }
    var icon: String { get }

    func sendMessage(_ userMessage: String, conversationHistory: [[String: Any]], systemPrompt: String?)
    func cancel()
    func isConfigured() -> Bool
}

// MARK: - Provider Type Enum

enum AIProviderType: String, CaseIterable {
    case claude = "claude"
    case grok = "grok"
    case openai = "openai"

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .grok: return "Grok"
        case .openai: return "GPT-4"
        }
    }

    var icon: String {
        switch self {
        case .claude: return "brain.head.profile"
        case .grok: return "sparkle"
        case .openai: return "bolt.fill"
        }
    }

    var accentColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .claude: return (0.90, 0.50, 0.30)  // Claude orange
        case .grok: return (0.10, 0.10, 0.10)    // Grok black/white
        case .openai: return (0.16, 0.65, 0.53)  // OpenAI green
        }
    }

    var apiKeyPrefix: String {
        switch self {
        case .claude: return "sk-ant-"
        case .grok: return "xai-"
        case .openai: return "sk-"
        }
    }

    var apiKeyPlaceholder: String {
        switch self {
        case .claude: return "sk-ant-..."
        case .grok: return "xai-..."
        case .openai: return "sk-..."
        }
    }
}

// MARK: - Provider Factory

class AIProviderFactory {

    static func createProvider(type: AIProviderType) -> AIProvider {
        switch type {
        case .claude:
            return ClaudeProvider()
        case .grok:
            return GrokProvider()
        case .openai:
            return OpenAIProvider()
        }
    }

    static func createCurrentProvider() -> AIProvider {
        let type = Config.shared.selectedProvider
        return createProvider(type: type)
    }
}
