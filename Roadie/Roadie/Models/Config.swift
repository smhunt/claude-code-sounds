import Foundation
import Security
import AVFoundation

// MARK: - Secure Configuration Storage

class Config {
    static let shared = Config()

    private let keychainService = "com.roadie.app"

    // MARK: - Provider Selection

    var selectedProvider: AIProviderType {
        get {
            let rawValue = UserDefaults.standard.string(forKey: "selected_provider") ?? "claude"
            return AIProviderType(rawValue: rawValue) ?? .claude
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selected_provider")
        }
    }

    // MARK: - API Keys (stored in Keychain)

    // Claude API Key
    var claudeApiKey: String? {
        get { getKeychainValue(key: "anthropic_api_key") }
        set {
            if let value = newValue {
                setKeychainValue(key: "anthropic_api_key", value: value)
            } else {
                deleteKeychainValue(key: "anthropic_api_key")
            }
        }
    }

    // Grok API Key
    var grokApiKey: String? {
        get { getKeychainValue(key: "grok_api_key") }
        set {
            if let value = newValue {
                setKeychainValue(key: "grok_api_key", value: value)
            } else {
                deleteKeychainValue(key: "grok_api_key")
            }
        }
    }

    // OpenAI API Key
    var openaiApiKey: String? {
        get { getKeychainValue(key: "openai_api_key") }
        set {
            if let value = newValue {
                setKeychainValue(key: "openai_api_key", value: value)
            } else {
                deleteKeychainValue(key: "openai_api_key")
            }
        }
    }

    // Legacy compatibility
    var apiKey: String? {
        get { claudeApiKey }
        set { claudeApiKey = newValue }
    }

    var hasValidApiKey: Bool {
        let provider = AIProviderFactory.createCurrentProvider()
        return provider.isConfigured()
    }

    func apiKey(for provider: AIProviderType) -> String? {
        switch provider {
        case .claude: return claudeApiKey
        case .grok: return grokApiKey
        case .openai: return openaiApiKey
        }
    }

    func setApiKey(_ key: String?, for provider: AIProviderType) {
        switch provider {
        case .claude: claudeApiKey = key
        case .grok: grokApiKey = key
        case .openai: openaiApiKey = key
        }
    }

    // MARK: - User Preferences

    var voiceEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "voice_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "voice_enabled") }
    }

    var speechRate: Float {
        get {
            let rate = UserDefaults.standard.float(forKey: "speech_rate")
            return rate > 0 ? rate : 0.52
        }
        set { UserDefaults.standard.set(newValue, forKey: "speech_rate") }
    }

    var autoListen: Bool {
        get {
            if UserDefaults.standard.object(forKey: "auto_listen") == nil {
                return true // default on
            }
            return UserDefaults.standard.bool(forKey: "auto_listen")
        }
        set { UserDefaults.standard.set(newValue, forKey: "auto_listen") }
    }

    var hapticFeedback: Bool {
        get {
            if UserDefaults.standard.object(forKey: "haptic_feedback") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "haptic_feedback")
        }
        set { UserDefaults.standard.set(newValue, forKey: "haptic_feedback") }
    }

    var selectedVoiceIndex: Int {
        get { UserDefaults.standard.integer(forKey: "selected_voice_index") }
        set { UserDefaults.standard.set(newValue, forKey: "selected_voice_index") }
    }

    // Discover available English voices at runtime
    static var availableVoices: [(name: String, identifier: String, sampleText: String)] = {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // Filter for English voices and sort by quality
        let englishVoices = allVoices
            .filter { $0.language.hasPrefix("en") }
            .sorted { v1, v2 in
                // Sort by quality (higher is better), then by name
                if v1.quality.rawValue != v2.quality.rawValue {
                    return v1.quality.rawValue > v2.quality.rawValue
                }
                return v1.name < v2.name
            }

        // Take top voices, avoiding duplicates by name
        var seen = Set<String>()
        var result: [(String, String, String)] = []

        for voice in englishVoices {
            let baseName = voice.name.replacingOccurrences(of: " (Enhanced)", with: "")
                                     .replacingOccurrences(of: " (Premium)", with: "")

            // Skip if we already have this voice name
            guard !seen.contains(baseName) else { continue }
            seen.insert(baseName)

            // Determine quality label
            let qualityLabel: String
            switch voice.quality {
            case .premium: qualityLabel = "Premium"
            case .enhanced: qualityLabel = "Enhanced"
            default: qualityLabel = "Standard"
            }

            // Get language region
            let region = voice.language.contains("GB") ? "UK" :
                        voice.language.contains("AU") ? "AU" :
                        voice.language.contains("IE") ? "IE" :
                        voice.language.contains("ZA") ? "ZA" :
                        voice.language.contains("IN") ? "IN" : "US"

            let displayName = "\(voice.name) (\(region), \(qualityLabel))"
            let sampleText = "Hi! I'm \(voice.name). I'll be your AI driving companion."

            result.append((displayName, voice.identifier, sampleText))

            // Limit to 12 voices max
            if result.count >= 12 { break }
        }

        // Fallback if no voices found
        if result.isEmpty {
            result.append(("Default Voice", "", "Hello, I'm your AI assistant."))
        }

        return result
    }()

    // Audio input source - phone or CarPlay, never both
    var activeAudioSource: AudioSource {
        get {
            let raw = UserDefaults.standard.string(forKey: "active_audio_source") ?? "phone"
            return AudioSource(rawValue: raw) ?? .phone
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "active_audio_source")
        }
    }

    enum AudioSource: String {
        case phone
        case carplay
    }

    var selectedVoiceIdentifier: String {
        let index = selectedVoiceIndex
        if index >= 0 && index < Config.availableVoices.count {
            return Config.availableVoices[index].1
        }
        return Config.availableVoices[0].1
    }

    var selectedVoiceSampleText: String {
        let index = selectedVoiceIndex
        if index >= 0 && index < Config.availableVoices.count {
            return Config.availableVoices[index].2
        }
        return Config.availableVoices[0].2
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "onboarding_complete") }
        set { UserDefaults.standard.set(newValue, forKey: "onboarding_complete") }
    }

    // MARK: - Keychain Helpers

    private func setKeychainValue(key: String, value: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        var newItem = query
        newItem[kSecValueData as String] = data

        SecItemAdd(newItem as CFDictionary, nil)
    }

    private func getKeychainValue(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func deleteKeychainValue(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Reset

    func resetAll() {
        apiKey = nil
        hasCompletedOnboarding = false
        voiceEnabled = true
        autoListen = true
        speechRate = 0.52
    }
}
