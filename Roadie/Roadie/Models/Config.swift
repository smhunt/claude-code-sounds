import Foundation
import Security

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

    // Available voices for TTS - Premium/Enhanced voices for naturalness
    static let availableVoices: [(name: String, identifier: String, sampleText: String)] = [
        ("Zoe (Premium)", "com.apple.voice.premium.en-US.Zoe", "Hey there! I'm Zoe, ready to help you on the road."),
        ("Ava (Premium)", "com.apple.voice.premium.en-US.Ava", "Hi! I'm Ava, your AI driving companion."),
        ("Samantha (Enhanced)", "com.apple.voice.enhanced.en-US.Samantha", "Hello! I'm Samantha, here to assist you."),
        ("Tom (Premium)", "com.apple.voice.premium.en-US.Tom", "Hey! I'm Tom, let's hit the road."),
        ("Evan (Premium)", "com.apple.voice.premium.en-US.Evan", "Hi there! I'm Evan, ready when you are."),
        ("Daniel (UK)", "com.apple.voice.enhanced.en-GB.Daniel", "Hello! I'm Daniel, at your service."),
        ("Karen (AU)", "com.apple.voice.enhanced.en-AU.Karen", "G'day! I'm Karen, happy to help."),
        ("Samantha (Compact)", "com.apple.voice.compact.en-US.Samantha", "Hi! I'm Samantha.")
    ]

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
