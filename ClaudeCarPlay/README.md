# Claude for CarPlay

Your AI copilot for the road. Voice-powered. Hands-free. Thoughtful.

## Modes

| Mode | What It Does |
|------|--------------|
| **Drive** | Navigation, nearby places, traffic. Says "Take me to..." and opens Maps |
| **Music** | DJ mode. Request songs, genres, vibes. Opens Apple Music/Spotify |
| **Games** | Road trip entertainment. Trivia, 20 Questions, Would You Rather |
| **News** | Briefings on topics you care about. Headlines, weather, sports |
| **Chat** | Just talk. Claude as your thoughtful conversation companion |

## Features

- **Voice-First**: Continuous listening with smart silence detection
- **Live Streaming**: Watch responses appear word by word
- **Action Triggers**: "Navigate to X" actually opens Maps
- **Waveform Visualizer**: See when Claude is listening/thinking/speaking
- **Claude Aesthetic**: Warm orange tones, clean dark UI
- **CarPlay Native**: Tab bar with all modes on your car display

## Quick Start

```bash
open ClaudeCarPlay.xcodeproj
```

1. Build and run on your iPhone
2. Complete onboarding (permissions + API key)
3. Start talking

## Project Structure

```
ClaudeCarPlay/
├── Models/
│   ├── AppMode.swift           # Mode definitions, prompts, colors
│   ├── Config.swift            # Keychain + UserDefaults
│   └── ConversationStore.swift # CoreData persistence
├── Views/
│   ├── MainViewController.swift    # Primary UI
│   ├── WaveformView.swift          # Audio visualizer
│   ├── ModePickerView.swift        # Mode selector
│   ├── OnboardingViewController.swift
│   └── SettingsViewController.swift
├── Services/
│   ├── SpeechRecognitionService.swift
│   ├── TextToSpeechService.swift
│   ├── ClaudeAPIService.swift
│   └── ConversationManager.swift
└── CarPlay/
    └── CarPlaySceneDelegate.swift  # Tab bar UI
```

## How Actions Work

Claude's responses can trigger real actions:

```
User: "Take me to the nearest Starbucks"
Claude: "I'll get you to Starbucks. [[NAV:Starbucks near me]]"
→ App opens Apple Maps with that search
```

```
User: "Play some jazz"
Claude: "Let's get some jazz going! [[MUSIC:jazz playlist]]"
→ App opens Apple Music with that search
```

## API Costs

Using `claude-sonnet-4-20250514`:
- ~$0.003 per input 1K tokens
- ~$0.015 per output 1K tokens
- Typical conversation: < $0.01

## CarPlay Setup

**Simulator**: Run app → I/O → External Displays → CarPlay

**Real Device**: Requires CarPlay entitlement from Apple MFi Program (1-2 weeks approval)

## Multi-AI Provider Support

Choose your preferred AI in Settings:

| Provider | Model | Status |
|----------|-------|--------|
| **Claude** | claude-sonnet-4 | Default |
| **Grok** | grok-3 | Supported |
| **GPT-4** | gpt-4o | Supported |

Each provider needs its own API key:
- Claude: `sk-ant-...` from [console.anthropic.com](https://console.anthropic.com)
- Grok: `xai-...` from [x.ai](https://x.ai)
- GPT-4: `sk-...` from [platform.openai.com](https://platform.openai.com)

Switch providers in Settings. Your API keys are stored securely in the iOS Keychain.

## License

MIT
