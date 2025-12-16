# Toggle Speech for Claude Code Sound Effects

Toggle the text-to-speech announcements ON or OFF while keeping sound effects.

```bash
python3 -c "
import json
config_file = '$HOME/.claude/sounds/config.json'
with open(config_file, 'r') as f:
    c = json.load(f)
c['speechEnabled'] = not c.get('speechEnabled', True)
status = 'ENABLED' if c['speechEnabled'] else 'DISABLED'
with open(config_file, 'w') as f:
    json.dump(c, f, indent=2)
print(f'🗣️ Speech {status}')
" && afplay -v 0.4 /System/Library/Sounds/Pop.aiff
```

This toggles speech like "Task complete" and "Your input needed" without affecting sound effects.
