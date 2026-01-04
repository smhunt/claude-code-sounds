# Changelog

All notable changes to Roadie will be documented in this file.

## [0.4.0] - 2025-01-04

### Added
- **CarPlay quick-tap suggestions**: Tap suggestion prompts to send directly to AI
- **Simulated location support**: GPX file included for testing location-aware features in simulator
- **Shared Xcode scheme**: Location simulation pre-configured (Vancouver downtown)
- **Microphone configuration in onboarding**: New step with live audio level meter and mic testing
- Real-time visual feedback on mic input levels with color-coded status (green/orange/yellow)

---

## [0.3.2] - 2025-01-04

### Fixed
- **Removed auto-start**: App no longer auto-starts listening on launch - user must tap to begin
- **Stopped mic cycling**: Removed auto-restart logic from SpeechRecognitionService
- **Better error handling**: Mic errors no longer trigger auto-retry loop
- **CarPlay stability**: CarPlay and TerminalView no longer auto-start listening

---

## [0.3.1] - 2025-01-04

### Fixed
- **Feedback loop prevention**: Added 1-second delay before auto-listen resumes after AI finishes speaking
- **Proper pause state**: When user taps to stop, it stays stopped (no more auto-unmuting)
- **User intent tracking**: New `userPaused` flag ensures user control is respected
- Status messages now show "Tap to speak" when paused for clarity

---

## [0.3.0] - 2025-01-04

### Added
- **Tap-to-stop**: Tap the mic button to instantly stop AI speech mid-response
- **Live captions**: Large subtitle display showing what the AI is currently saying
- **Brevity mode**: AI responses are now strictly limited to 1-2 short sentences

### Changed
- System prompts updated to enforce ultra-concise responses for driving safety
- Mic button now has three states: idle (tap to speak), listening (tap to stop), speaking (tap to interrupt)
- Status label shows clearer state indicators

### Fixed
- AI no longer "talks over" the user - responses are interruptible
- Better control flow between listening, thinking, and speaking states

---

## [0.2.0] - 2024-12-30

### Added
- Multi-AI provider support (Claude, Grok, GPT-4)
- Provider selection in Settings
- API key management per provider
- Automatic provider switching

### Changed
- Renamed app from "ClaudeCarPlay" to "Roadie"
- Updated branding and icons

---

## [0.1.0] - 2024-12-29

### Added
- Initial release
- 5 driving modes: Drive, Music, Games, News, Chat
- Voice-first interface with continuous listening
- Real-time streaming responses
- Waveform visualizer
- CarPlay support with tab bar navigation
- Action triggers for navigation (`[[NAV:...]]`) and music (`[[MUSIC:...]]`)
- Onboarding flow with permissions and API key setup
- Settings screen with voice options
- Conversation history with CoreData persistence
