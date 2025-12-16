# Claude Code Sound Effects

Audio feedback for Claude Code responses using macOS native sounds and text-to-speech.

## Features

- **12 event types** with customizable sounds
- **Text-to-speech** announcements for important events
- **Interactive configuration** menu
- **Slash commands** for quick control
- **Zero dependencies** - uses macOS built-in sounds

## Event Types

| Event | Default Sound | Speech |
|-------|---------------|--------|
| Decision Needed | Bottle (double) | "Your input needed" |
| Question | Bottle | - |
| Victory | Glass + Hero | "Victory" |
| Task Complete | Glass | "Task complete" |
| Searching | Submarine | - |
| File Created | Pop | - |
| Error | Basso | "Uh oh" |
| Warning | Funk | - |
| Funny | Frog | - |
| Thinking | Morse | - |
| Mac/iOS Related | Sosumi | - |
| Default | Purr | - |

## Installation

### Quick Install

```bash
curl -sL https://raw.githubusercontent.com/seanhunt/claude-code-sounds/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/seanhunt/claude-code-sounds.git
cd claude-code-sounds
./install.sh
```

## Usage

### Slash Commands

| Command | Description |
|---------|-------------|
| `/sounds-demo` | Play all sounds with labels |
| `/sounds-configure` | Open interactive config menu |
| `/sounds-on` | Enable sound effects |
| `/sounds-off` | Disable sound effects |
| `/sounds-speech-toggle` | Toggle speech announcements |

### Configuration Menu

Run `/sounds-configure` to access:

1. Toggle sounds ON/OFF
2. Toggle speech ON/OFF
3. Adjust master volume (0.25 - 1.0)
4. Configure individual event sounds
5. Preview all available sounds
6. Preview all available voices
7. Reset to defaults

### Configuration File

Settings are stored in `~/.claude/sounds/config.json`:

```json
{
  "enabled": true,
  "masterVolume": 0.7,
  "speechEnabled": true,
  "events": {
    "taskComplete": {
      "enabled": true,
      "sound": "Glass.aiff",
      "volume": 0.6,
      "speech": "Task complete",
      "voice": "Bells"
    }
  }
}
```

## Available Sounds

All sounds are from `/System/Library/Sounds/`:

- Basso, Blow, Bottle, Frog, Funk
- Glass, Hero, Morse, Ping, Pop
- Purr, Sosumi, Submarine, Tink

## Available Voices

macOS voices for speech:

- Samantha, Bells, Bad News, Bubbles
- Albert, Boing, Cellos, Daniel
- Fiona, Fred, Wobble

## Requirements

- macOS (uses native `afplay` and `say` commands)
- Claude Code CLI

## License

MIT
