# CLAUDE.md - Roadie

iOS CarPlay voice assistant app with multi-AI provider support.

## Project-Specific Simulator

**Always use the dedicated Roadie simulator to avoid conflicts:**

| Name | UUID | Device |
|------|------|--------|
| Roadie-Dev | FA8A067D-ACDC-4228-9513-19FEA891DDBA | iPhone 17 Pro (iOS 26.2) |

### Quick Commands

```bash
# Boot simulator
xcrun simctl boot FA8A067D-ACDC-4228-9513-19FEA891DDBA

# Build and run
xcodebuild -scheme Roadie -destination 'platform=iOS Simulator,id=FA8A067D-ACDC-4228-9513-19FEA891DDBA' build

# Install app
xcrun simctl install FA8A067D-ACDC-4228-9513-19FEA891DDBA ~/Library/Developer/Xcode/DerivedData/Roadie-cjxjohklqipesgfuqsjpfqqtemjs/Build/Products/Debug-iphonesimulator/Roadie.app

# Launch app
xcrun simctl launch FA8A067D-ACDC-4228-9513-19FEA891DDBA com.roadie.app

# Reset onboarding (uninstall app)
xcrun simctl uninstall FA8A067D-ACDC-4228-9513-19FEA891DDBA com.roadie.app
```

## Bundle ID

`com.roadie.app`

## Key Architecture

- **Single audio source**: Only phone OR CarPlay mic active, never both
- **CarPlay is primary**: When connected, CarPlay handles audio; phone becomes display-only
- **Premium TTS voices**: Zoe, Ava, Tom, Evan with smart fallback chain

## Testing CarPlay

Use the CarPlay Simulator (via Xcode > Open Developer Tool > Simulator) to test CarPlay UI alongside the phone app.
