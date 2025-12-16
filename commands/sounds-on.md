# Enable Claude Code Sound Effects

Turn ON all sound effects for Claude Code responses.

```bash
python3 -c "
import json
config_file = '$HOME/.claude/sounds/config.json'
with open(config_file, 'r') as f:
    c = json.load(f)
c['enabled'] = True
with open(config_file, 'w') as f:
    json.dump(c, f, indent=2)
print('✅ Sound effects ENABLED')
" && afplay -v 0.5 /System/Library/Sounds/Glass.aiff
```

Sounds are now enabled and will play based on response content.
