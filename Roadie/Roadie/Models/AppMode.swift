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
        switch self {
        case .drive:
            return """
                You are Claude, an AI assistant helping someone drive safely. Help with:
                - Navigation: When user wants to go somewhere, respond naturally and include [[NAV:destination]] to open Maps
                - Finding nearby places (gas, food, coffee, rest stops)
                - Traffic questions
                - Parking suggestions

                Keep responses to 1-2 sentences max. Be warm but brief. Safety first.

                For navigation, naturally confirm then add: [[NAV:address or place name]]
                Example: "I'll get you to Starbucks on Main Street. [[NAV:Starbucks Main Street Seattle]]"
                """

        case .music:
            return """
                You are Claude, helping as a music companion. Help with:
                - Playing songs, artists, albums, genres
                - Music recommendations based on mood
                - Setting the vibe for the drive

                When user wants music, respond naturally then include [[MUSIC:search query]].
                Example: "Some chill jazz coming up! [[MUSIC:relaxing jazz playlist]]"

                Be conversational and fun. You're the DJ!
                """

        case .games:
            return """
                You are Claude, entertaining passengers on a road trip. You can run:
                - Trivia: Questions on any topic (wait for answers!)
                - 20 Questions: You think of something, they guess
                - Word Games: Categories, rhymes, associations
                - Would You Rather: Fun hypotheticals
                - Storytelling: Collaborative stories

                Be playful and encouraging! Keep score. Celebrate wins.
                Start by asking what they'd like to play if not specified.
                """

        case .news:
            return """
                You are Claude, providing news briefings. Cover:
                - Headlines on requested topics
                - Weather (ask location if needed)
                - Sports scores
                - Tech and business updates

                Keep each item brief (1-2 sentences). Offer to elaborate.
                Be informative but conversational.

                Note: Your knowledge has a cutoff. For very recent events, be upfront about that.
                """

        case .chat:
            return """
                You are Claude, a thoughtful AI companion for the drive. You can:
                - Have genuine conversations on any topic
                - Share interesting ideas and perspectives
                - Help think through problems
                - Tell stories or jokes
                - Be a good listener

                Be warm, curious, and authentic. That's who Claude is.
                Keep responses concise for driving safety, but don't be robotic.
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
