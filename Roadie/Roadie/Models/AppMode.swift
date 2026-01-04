import UIKit

enum AppMode: String, CaseIterable {
    case drive = "drive"
    case music = "music"
    case games = "games"
    case news = "news"
    case chat = "chat"

    var displayName: String {
        switch self {
        case .drive: return "Drive"
        case .music: return "Music"
        case .games: return "Games"
        case .news: return "News"
        case .chat: return "Chat"
        }
    }

    var icon: String {
        switch self {
        case .drive: return "location.fill"
        case .music: return "music.note"
        case .games: return "sparkles"
        case .news: return "newspaper.fill"
        case .chat: return "bubble.left.fill"
        }
    }

    // Claude-inspired color palette
    var color: UIColor {
        switch self {
        case .drive: return UIColor(red: 0.90, green: 0.45, blue: 0.30, alpha: 1.0)  // Claude orange
        case .music: return UIColor(red: 0.85, green: 0.55, blue: 0.40, alpha: 1.0)  // Warm peach
        case .games: return UIColor(red: 0.80, green: 0.50, blue: 0.45, alpha: 1.0)  // Dusty rose
        case .news: return UIColor(red: 0.75, green: 0.55, blue: 0.50, alpha: 1.0)   // Muted coral
        case .chat: return UIColor(red: 0.95, green: 0.60, blue: 0.35, alpha: 1.0)   // Bright orange
        }
    }

    static var claudeOrange: UIColor {
        UIColor(red: 0.90, green: 0.50, blue: 0.30, alpha: 1.0)
    }

    static var claudeCream: UIColor {
        UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
    }

    static var claudeDark: UIColor {
        UIColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1.0)
    }

    var systemPrompt: String {
        let brevityRule = """

            CRITICAL: You are being spoken aloud while someone drives. Keep responses EXTREMELY brief:
            - Maximum 1-2 SHORT sentences (under 20 words total)
            - No lists, no elaboration, no "let me know if..."
            - Get to the point immediately
            - The user can ask follow-up questions if they want more
            """

        switch self {
        case .drive:
            return """
                You help drivers navigate. When they want to go somewhere, confirm briefly and add [[NAV:destination]].
                Example: "On it. [[NAV:Starbucks nearby]]"
                \(brevityRule)
                """

        case .music:
            return """
                You're a DJ. When they want music, acknowledge and add [[MUSIC:query]].
                Example: "Jazz it is. [[MUSIC:chill jazz]]"
                \(brevityRule)
                """

        case .games:
            return """
                You run road trip games. Ask ONE question at a time. Wait for answers. Keep score briefly.
                \(brevityRule)
                """

        case .news:
            return """
                You give news briefings. One headline at a time, super brief. Ask if they want more.
                \(brevityRule)
                """

        case .chat:
            return """
                You're a friendly chat companion. Be warm but brief. One thought at a time.
                \(brevityRule)
                """
        }
    }

    var welcomeMessage: String {
        switch self {
        case .drive:
            return "Where are we headed?"
        case .music:
            return "What are we listening to?"
        case .games:
            return "What should we play?"
        case .news:
            return "What would you like to know?"
        case .chat:
            return "Hey, what's on your mind?"
        }
    }

    var placeholderHints: [String] {
        switch self {
        case .drive:
            return ["Take me to the nearest gas station", "Navigate home", "Find coffee nearby", "How long to downtown?"]
        case .music:
            return ["Play something upbeat", "90s hip hop", "Chill vibes", "Play Radiohead"]
        case .games:
            return ["Let's play trivia", "20 questions", "Would you rather", "Tell me a riddle"]
        case .news:
            return ["What's happening today?", "Tech news", "Weather forecast", "Sports scores"]
        case .chat:
            return ["Tell me something interesting", "I've been thinking about...", "What's your take on...", "Make me laugh"]
        }
    }
}
