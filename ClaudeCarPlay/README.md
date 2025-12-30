# Claude CarPlay

AI voice assistant for CarPlay. Talk to Claude while driving.

## Features

- **Voice Input**: Continuous speech recognition with silence detection
- **Live Streaming**: See Claude's response appear character by character
- **Text-to-Speech**: Hear responses through car speakers
- **Persistent Sessions**: Conversations survive app restarts (CoreData)
- **CarPlay Integration**: Works on your car's display
- **Onboarding**: Easy setup wizard for API key
- **Settings**: Voice toggle, speech rate, haptics

## Quick Start

### 1. Open in Xcode

```bash
open ClaudeCarPlay.xcodeproj
```

### 2. Get an API Key

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Create an API key
3. Enter it in the app's onboarding flow

### 3. Run on Device

1. Select your iPhone as target
2. Build and run (Cmd+R)
3. Grant microphone and speech recognition permissions
4. Enter your API key when prompted

### 4. Test CarPlay

**Simulator:**
1. Run the app on iPhone simulator
2. Go to: I/O → External Displays → CarPlay

**Real Device:**
- Requires CarPlay entitlement from Apple (see below)

## Project Structure

```
ClaudeCarPlay/
├── AppDelegate.swift              # App entry, permissions
├── SceneDelegate.swift            # iPhone scene
├── CarPlay/
│   └── CarPlaySceneDelegate.swift # CarPlay scene
├── Services/
│   ├── SpeechRecognitionService.swift  # Speech-to-text
│   ├── TextToSpeechService.swift       # Text-to-speech
│   ├── ClaudeAPIService.swift          # Claude API streaming
│   └── ConversationManager.swift       # Orchestrates everything
├── Models/
│   ├── Config.swift               # Settings (Keychain for API key)
│   └── ConversationStore.swift    # CoreData persistence
├── Views/
│   ├── TerminalView.swift         # Main terminal UI
│   ├── OnboardingViewController.swift  # Setup wizard
│   └── SettingsViewController.swift    # Settings screen
└── Info.plist
```

## CarPlay Entitlement

To run on a real car display:

1. Join Apple Developer Program ($99/year)
2. Request CarPlay entitlement: [Apple MFi Portal](https://mfi.apple.com)
3. Select "CarPlay Audio App" category
4. Wait for approval (usually 1-2 weeks)
5. Add entitlement to your provisioning profile

**For demo videos**, you can use:
- iPhone simulator + CarPlay simulator
- Screen recording of the terminal UI on real device

## Settings

| Setting | Description |
|---------|-------------|
| Voice Output | Enable/disable TTS |
| Auto-Listen | Automatically start listening after response |
| Speech Rate | How fast Claude speaks |
| Haptic Feedback | Vibration on state changes |

## API Usage

The app uses `claude-sonnet-4-20250514` by default. Cost per conversation:
- Input: ~$3/million tokens
- Output: ~$15/million tokens
- Typical chat: <$0.01

## Troubleshooting

**"No API key configured"**
- Open Settings (gear icon) and enter your Anthropic API key

**Speech recognition not working**
- Check Settings → Privacy → Speech Recognition
- Ensure microphone permission granted

**CarPlay not showing app**
- Ensure CarPlay entitlement is configured
- Check Info.plist has `CPTemplateApplicationSceneSessionRoleApplication`

## For Kickstarter Demo

1. Run on real iPhone (better than simulator for videos)
2. Screen record the terminal UI in action
3. Show the onboarding flow
4. Demonstrate voice interaction
5. For CarPlay footage, use simulator or find a friend with CarPlay

## Building for Production

1. Change bundle identifier to your own
2. Add your app icon to Assets.xcassets
3. Request CarPlay entitlement
4. Configure code signing
5. Archive and upload to App Store Connect

## License

MIT
