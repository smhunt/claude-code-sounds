#!/bin/bash
# Claude Code Sound Effects Installer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing Claude Code Sound Effects..."

# Create directories if they don't exist
mkdir -p "$CLAUDE_DIR/sounds"
mkdir -p "$CLAUDE_DIR/commands"

# Copy sound configuration
if [ -f "$SCRIPT_DIR/sounds/config.json" ]; then
    cp "$SCRIPT_DIR/sounds/config.json" "$CLAUDE_DIR/sounds/"
    echo "  ✓ Copied config.json"
fi

# Copy configure script
if [ -f "$SCRIPT_DIR/sounds/configure.sh" ]; then
    cp "$SCRIPT_DIR/sounds/configure.sh" "$CLAUDE_DIR/sounds/"
    chmod +x "$CLAUDE_DIR/sounds/configure.sh"
    echo "  ✓ Copied configure.sh"
fi

# Copy slash commands
for cmd in "$SCRIPT_DIR/commands/"*.md; do
    if [ -f "$cmd" ]; then
        cp "$cmd" "$CLAUDE_DIR/commands/"
        echo "  ✓ Copied $(basename "$cmd")"
    fi
done

echo ""
echo "✅ Installation complete!"
echo ""
echo "Available commands:"
echo "  /sounds-demo        - Play all sounds"
echo "  /sounds-configure   - Open config menu"
echo "  /sounds-on          - Enable sounds"
echo "  /sounds-off         - Disable sounds"
echo "  /sounds-speech-toggle - Toggle speech"
echo ""

# Play success sound
afplay -v 0.5 /System/Library/Sounds/Glass.aiff 2>/dev/null || true
