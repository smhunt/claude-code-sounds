# Claude CarPlay

Minimal iOS CarPlay app with voice-controlled Claude assistant.

## Features

- Voice-to-text via iOS Speech framework
- Live streaming Claude API responses
- Terminal-style UI with character-by-character rendering
- Text-to-speech output through CarPlay
- Persistent conversation via PostgreSQL

## Structure

```
ClaudeCarPlay/
├── AppDelegate.swift           # App entry, permissions
├── SceneDelegate.swift         # iPhone scene
├── CarPlay/
│   └── CarPlaySceneDelegate.swift  # CarPlay scene
├── Services/
│   ├── SpeechRecognitionService.swift  # STT
│   ├── TextToSpeechService.swift       # TTS
│   ├── ClaudeAPIService.swift          # Claude streaming
│   ├── PostgresService.swift           # DB persistence
│   └── ConversationManager.swift       # Orchestrator
├── Views/
│   └── TerminalView.swift      # Terminal UI
├── Info.plist
└── ClaudeCarPlay.entitlements
```

## Setup

### 1. Environment Variables

Set these before running:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export POSTGRES_REST_URL="https://your-db.supabase.co/rest/v1"
export POSTGRES_API_KEY="your-supabase-anon-key"
```

Or hardcode in services for testing.

### 2. Database

Run `schema.sql` on your Postgres instance.

### 3. CarPlay Entitlement

You need Apple Developer Program membership and CarPlay entitlement request from Apple to test on real CarPlay. For simulator:

1. Open Xcode
2. Run on iPhone simulator
3. Open CarPlay simulator: I/O → External Displays → CarPlay

### 4. Build

```bash
open ClaudeCarPlay.xcodeproj
# Select iPhone target, build and run
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Apple Developer account (for CarPlay)
- Claude API key
- PostgreSQL (Supabase/Neon/local)

## Notes

- CarPlay apps require Apple approval for App Store
- Speech recognition works best with good mic (car Bluetooth)
- Conversation persists across app restarts via session ID
