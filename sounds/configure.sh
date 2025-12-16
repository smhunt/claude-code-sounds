#!/bin/bash
# Claude Code Sounds Configuration Dialog
# Interactive configuration for sound effects

CONFIG_FILE="$HOME/.claude/sounds/config.json"
SOUNDS_DIR="/System/Library/Sounds"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Read config value using Python (more reliable JSON parsing)
get_config() {
    python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print($1)" 2>/dev/null
}

# Update config value
set_config() {
    local path="$1"
    local value="$2"
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    c = json.load(f)
$path = $value
with open('$CONFIG_FILE', 'w') as f:
    json.dump(c, f, indent=2)
"
}

# Play a sound
play_sound() {
    local sound="$1"
    local volume="${2:-0.6}"
    afplay -v "$volume" "$SOUNDS_DIR/$sound" &
}

# Speak text
speak() {
    local voice="$1"
    local text="$2"
    say -v "$voice" "$text" &
}

# Show header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Claude Code Sound Effects Configuration${NC}                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main menu
main_menu() {
    while true; do
        show_header

        local enabled=$(get_config "c['enabled']")
        local speech=$(get_config "c['speechEnabled']")
        local volume=$(get_config "c['masterVolume']")

        echo -e "${BOLD}Current Settings:${NC}"
        if [ "$enabled" = "True" ]; then
            echo -e "  Sounds: ${GREEN}ON${NC}"
        else
            echo -e "  Sounds: ${RED}OFF${NC}"
        fi
        if [ "$speech" = "True" ]; then
            echo -e "  Speech: ${GREEN}ON${NC}"
        else
            echo -e "  Speech: ${RED}OFF${NC}"
        fi
        echo -e "  Master Volume: ${YELLOW}$volume${NC}"
        echo ""
        echo -e "${BOLD}Options:${NC}"
        echo "  1) Toggle sounds ON/OFF"
        echo "  2) Toggle speech ON/OFF"
        echo "  3) Adjust master volume"
        echo "  4) Configure individual events"
        echo "  5) Preview all sounds"
        echo "  6) Preview all voices"
        echo "  7) Reset to defaults"
        echo "  q) Quit"
        echo ""
        read -p "Choose an option: " choice

        case $choice in
            1)
                if [ "$enabled" = "True" ]; then
                    set_config "c['enabled']" "False"
                    echo -e "${RED}Sounds disabled${NC}"
                else
                    set_config "c['enabled']" "True"
                    echo -e "${GREEN}Sounds enabled${NC}"
                    play_sound "Glass.aiff" 0.5
                fi
                sleep 1
                ;;
            2)
                if [ "$speech" = "True" ]; then
                    set_config "c['speechEnabled']" "False"
                    echo -e "${RED}Speech disabled${NC}"
                else
                    set_config "c['speechEnabled']" "True"
                    echo -e "${GREEN}Speech enabled${NC}"
                    speak "Samantha" "Speech enabled"
                fi
                sleep 1
                ;;
            3)
                volume_menu
                ;;
            4)
                events_menu
                ;;
            5)
                preview_sounds
                ;;
            6)
                preview_voices
                ;;
            7)
                reset_defaults
                ;;
            q|Q)
                echo -e "${GREEN}Settings saved!${NC}"
                play_sound "Glass.aiff" 0.4
                exit 0
                ;;
        esac
    done
}

# Volume adjustment
volume_menu() {
    show_header
    echo -e "${BOLD}Adjust Master Volume${NC}"
    echo ""
    echo "Current volume: $(get_config "c['masterVolume']")"
    echo ""
    echo "  1) 0.25 (Quiet)"
    echo "  2) 0.50 (Medium)"
    echo "  3) 0.70 (Normal)"
    echo "  4) 0.85 (Loud)"
    echo "  5) 1.00 (Maximum)"
    echo "  b) Back"
    echo ""
    read -p "Choose volume level: " vol

    case $vol in
        1) set_config "c['masterVolume']" "0.25"; play_sound "Glass.aiff" 0.25 ;;
        2) set_config "c['masterVolume']" "0.50"; play_sound "Glass.aiff" 0.50 ;;
        3) set_config "c['masterVolume']" "0.70"; play_sound "Glass.aiff" 0.70 ;;
        4) set_config "c['masterVolume']" "0.85"; play_sound "Glass.aiff" 0.85 ;;
        5) set_config "c['masterVolume']" "1.00"; play_sound "Glass.aiff" 1.0 ;;
    esac
}

# Events configuration
events_menu() {
    while true; do
        show_header
        echo -e "${BOLD}Configure Event Sounds${NC}"
        echo ""
        echo "  1) Decision Needed   - $(get_config "c['events']['decision']['sound']")"
        echo "  2) Question          - $(get_config "c['events']['question']['sound']")"
        echo "  3) Victory           - $(get_config "c['events']['victory']['sound']")"
        echo "  4) Task Complete     - $(get_config "c['events']['taskComplete']['sound']")"
        echo "  5) Searching         - $(get_config "c['events']['searching']['sound']")"
        echo "  6) File Created      - $(get_config "c['events']['fileCreated']['sound']")"
        echo "  7) Error             - $(get_config "c['events']['error']['sound']")"
        echo "  8) Warning           - $(get_config "c['events']['warning']['sound']")"
        echo "  9) Funny             - $(get_config "c['events']['funny']['sound']")"
        echo "  0) Default           - $(get_config "c['events']['default']['sound']")"
        echo "  b) Back"
        echo ""
        read -p "Choose event to configure: " ev

        case $ev in
            1) configure_event "decision" "Decision Needed" ;;
            2) configure_event "question" "Question" ;;
            3) configure_event "victory" "Victory" ;;
            4) configure_event "taskComplete" "Task Complete" ;;
            5) configure_event "searching" "Searching" ;;
            6) configure_event "fileCreated" "File Created" ;;
            7) configure_event "error" "Error" ;;
            8) configure_event "warning" "Warning" ;;
            9) configure_event "funny" "Funny" ;;
            0) configure_event "default" "Default" ;;
            b|B) return ;;
        esac
    done
}

# Configure single event
configure_event() {
    local event="$1"
    local name="$2"

    show_header
    echo -e "${BOLD}Configure: $name${NC}"
    echo ""
    echo "Current sound: $(get_config "c['events']['$event']['sound']")"
    echo ""
    echo "Available sounds:"
    echo "  1) Basso      5) Funk      9) Ping       13) Submarine"
    echo "  2) Blow       6) Glass    10) Pop        14) Tink"
    echo "  3) Bottle     7) Hero     11) Purr"
    echo "  4) Frog       8) Morse    12) Sosumi"
    echo ""
    echo "  p) Preview current"
    echo "  b) Back"
    echo ""
    read -p "Choose sound (1-14): " snd

    local sounds=("" "Basso.aiff" "Blow.aiff" "Bottle.aiff" "Frog.aiff" "Funk.aiff" "Glass.aiff" "Hero.aiff" "Morse.aiff" "Ping.aiff" "Pop.aiff" "Purr.aiff" "Sosumi.aiff" "Submarine.aiff" "Tink.aiff")

    case $snd in
        p|P)
            local current=$(get_config "c['events']['$event']['sound']")
            play_sound "$current" 0.7
            sleep 2
            configure_event "$event" "$name"
            ;;
        b|B)
            return
            ;;
        [1-9]|1[0-4])
            local new_sound="${sounds[$snd]}"
            set_config "c['events']['$event']['sound']" "\"$new_sound\""
            echo -e "${GREEN}Set to $new_sound${NC}"
            play_sound "$new_sound" 0.7
            sleep 1
            ;;
    esac
}

# Preview all sounds
preview_sounds() {
    show_header
    echo -e "${BOLD}Previewing All Sounds${NC}"
    echo ""

    local sounds=("Basso" "Blow" "Bottle" "Frog" "Funk" "Glass" "Hero" "Morse" "Ping" "Pop" "Purr" "Sosumi" "Submarine" "Tink")

    for sound in "${sounds[@]}"; do
        echo -e "  Playing: ${CYAN}$sound${NC}"
        afplay -v 0.6 "$SOUNDS_DIR/${sound}.aiff"
        sleep 0.3
    done

    echo ""
    echo -e "${GREEN}Done!${NC}"
    read -p "Press Enter to continue..."
}

# Preview voices
preview_voices() {
    show_header
    echo -e "${BOLD}Previewing Voices${NC}"
    echo ""

    local voices=("Samantha" "Bells" "Bad News" "Bubbles" "Albert" "Boing" "Daniel")
    local phrases=("Hello, I'm Samantha" "Task complete" "Something went wrong" "Bubble bubble" "My name is Albert" "Boing boing" "Cheerio")

    for i in "${!voices[@]}"; do
        echo -e "  ${CYAN}${voices[$i]}${NC}: ${phrases[$i]}"
        say -v "${voices[$i]}" "${phrases[$i]}"
        sleep 0.5
    done

    echo ""
    echo -e "${GREEN}Done!${NC}"
    read -p "Press Enter to continue..."
}

# Reset to defaults
reset_defaults() {
    show_header
    echo -e "${YELLOW}Reset all settings to defaults?${NC}"
    read -p "Type 'yes' to confirm: " confirm

    if [ "$confirm" = "yes" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
{
  "enabled": true,
  "masterVolume": 0.7,
  "speechEnabled": true,
  "events": {
    "decision": {"enabled": true, "sound": "Bottle.aiff", "volume": 0.7, "doubleChime": true, "speech": "Your input needed", "voice": "Samantha"},
    "question": {"enabled": true, "sound": "Bottle.aiff", "volume": 0.7, "speech": null, "voice": null},
    "victory": {"enabled": true, "sound": "Hero.aiff", "volume": 0.7, "preSound": "Glass.aiff", "speech": "Victory", "voice": "Bells"},
    "taskComplete": {"enabled": true, "sound": "Glass.aiff", "volume": 0.6, "speech": "Task complete", "voice": "Bells"},
    "searching": {"enabled": true, "sound": "Submarine.aiff", "volume": 0.5, "speech": null, "voice": null},
    "fileCreated": {"enabled": true, "sound": "Pop.aiff", "volume": 0.6, "speech": null, "voice": null},
    "error": {"enabled": true, "sound": "Basso.aiff", "volume": 0.7, "speech": "Uh oh", "voice": "Bad News"},
    "warning": {"enabled": true, "sound": "Funk.aiff", "volume": 0.5, "speech": null, "voice": null},
    "funny": {"enabled": true, "sound": "Frog.aiff", "volume": 0.5, "speech": null, "voice": null},
    "thinking": {"enabled": true, "sound": "Morse.aiff", "volume": 0.4, "speech": null, "voice": null},
    "macRelated": {"enabled": true, "sound": "Sosumi.aiff", "volume": 0.4, "speech": null, "voice": null},
    "default": {"enabled": true, "sound": "Purr.aiff", "volume": 0.25, "speech": null, "voice": null}
  }
}
EOF
        echo -e "${GREEN}Settings reset!${NC}"
        play_sound "Glass.aiff" 0.5
        sleep 1
    fi
}

# Run main menu
main_menu
