# Roadie

Your AI copilot for the road. Voice-powered. Hands-free. Multi-AI.

## Modes

| Mode | What It Does |
|------|--------------|
| **Drive** | Navigation, nearby places, traffic. Says "Take me to..." and opens Maps |
| **Music** | DJ mode. Request songs, genres, vibes. Opens Apple Music/Spotify |
| **Games** | Road trip entertainment. Trivia, 20 Questions, Would You Rather |
| **News** | Briefings on topics you care about. Headlines, weather, sports |
| **Chat** | Just talk. Your AI as a thoughtful conversation companion |

## Features

- **Voice-First**: Continuous listening with smart silence detection
- **Live Streaming**: Watch responses appear word by word
- **Action Triggers**: "Navigate to X" actually opens Maps
- **Waveform Visualizer**: See when AI is listening/thinking/speaking
- **Multi-AI**: Choose Claude, Grok, or GPT-4
- **CarPlay Native**: Tab bar with all modes on your car display

## Quick Start

```bash
open Roadie.xcodeproj
```

1. Build and run on your iPhone
2. Complete onboarding (permissions + API key)
3. Start talking

## Project Structure

```
Roadie/
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
│   ├── AIProvider.swift            # Provider protocol
│   ├── ClaudeProvider.swift        # Anthropic integration
│   ├── GrokProvider.swift          # xAI integration
│   ├── OpenAIProvider.swift        # OpenAI integration
│   ├── SpeechRecognitionService.swift
│   ├── TextToSpeechService.swift
│   └── ConversationManager.swift
└── CarPlay/
    └── CarPlaySceneDelegate.swift  # Tab bar UI
```

## How Actions Work

AI responses can trigger real actions:

```
User: "Take me to the nearest Starbucks"
AI: "I'll get you to Starbucks. [[NAV:Starbucks near me]]"
→ App opens Apple Maps with that search
```

```
User: "Play some jazz"
AI: "Let's get some jazz going! [[MUSIC:jazz playlist]]"
→ App opens Apple Music with that search
```

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

## CarPlay Setup

**Simulator**: Run app → I/O → External Displays → CarPlay

**Real Device**: Requires CarPlay entitlement from Apple MFi Program (1-2 weeks approval)

## License

MIT
