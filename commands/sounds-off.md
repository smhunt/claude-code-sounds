# Disable Claude Code Sound Effects

Turn OFF all sound effects for Claude Code responses.

```bash
python3 -c "
import json
config_file = '$HOME/.claude/sounds/config.json'
with open(config_file, 'r') as f:
    c = json.load(f)
c['enabled'] = False
with open(config_file, 'w') as f:
    json.dump(c, f, indent=2)
print('🔇 Sound effects DISABLED')
"
```

Sounds are now disabled. Use `/sounds-on` to re-enable.
