# Demo All Claude Code Sound Effects

Play all configured sound effects with their associated speech to preview the current sound theme.

Run this demo script to hear all sounds:

```bash
echo "🎵 Claude Code Sound Effects Demo"
echo "=================================="
echo ""

SOUNDS_DIR="/System/Library/Sounds"

echo "1. Decision Needed (double chime + speech)"
afplay -v 0.6 $SOUNDS_DIR/Bottle.aiff && sleep 0.25 && afplay -v 0.8 $SOUNDS_DIR/Bottle.aiff && sleep 0.3 && say -v "Samantha" "Your input needed"
sleep 1.5

echo "2. Question (single chime)"
afplay -v 0.7 $SOUNDS_DIR/Bottle.aiff
sleep 1

echo "3. Victory (fanfare + speech)"
afplay -v 0.5 $SOUNDS_DIR/Glass.aiff && sleep 0.2 && afplay -v 0.7 $SOUNDS_DIR/Hero.aiff && sleep 0.3 && say -v "Bells" "Victory"
sleep 1.5

echo "4. Task Complete (chime + speech)"
afplay -v 0.6 $SOUNDS_DIR/Glass.aiff && sleep 0.2 && say -v "Bells" "Task complete"
sleep 1.5

echo "5. Searching (sonar)"
afplay -v 0.5 $SOUNDS_DIR/Submarine.aiff
sleep 1

echo "6. File Created (pop)"
afplay -v 0.6 $SOUNDS_DIR/Pop.aiff
sleep 1

echo "7. Error (alert + speech)"
afplay -v 0.7 $SOUNDS_DIR/Basso.aiff && sleep 0.2 && say -v "Bad News" "Uh oh"
sleep 1.5

echo "8. Warning (funk)"
afplay -v 0.5 $SOUNDS_DIR/Funk.aiff
sleep 1

echo "9. Funny (frog)"
afplay -v 0.5 $SOUNDS_DIR/Frog.aiff
sleep 1

echo "10. Thinking (morse)"
afplay -v 0.4 $SOUNDS_DIR/Morse.aiff
sleep 1

echo "11. Mac/iOS Related (sosumi)"
afplay -v 0.4 $SOUNDS_DIR/Sosumi.aiff
sleep 1

echo "12. Default (purr)"
afplay -v 0.25 $SOUNDS_DIR/Purr.aiff
sleep 0.5

echo ""
echo "✅ Demo complete!"
```
