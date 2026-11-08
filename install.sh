#!/usr/bin/env bash
# One-shot setup for Termux: dependencies, .env, auto-start on boot.
set -euo pipefail

DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BOOT_SCRIPT="$HOME/.termux/boot/gpx-sync"

pkg install -y curl inotify-tools

chmod +x "$DIR/gpx-sync.sh"

# Termux:Boot runs every script in ~/.termux/boot on startup.
# The same script is used to start the watcher by hand.
mkdir -p "$(dirname "$BOOT_SCRIPT")"
cat > "$BOOT_SCRIPT" <<BOOT
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
pgrep -f gpx-sync.sh >/dev/null || nohup "$DIR/gpx-sync.sh" >> "$DIR/gpx-sync.log" 2>&1 &
BOOT
chmod +x "$BOOT_SCRIPT"

if [ ! -f "$DIR/.env" ]; then
    cp "$DIR/.env.example" "$DIR/.env"
    echo "Created $DIR/.env — edit it, then run: $BOOT_SCRIPT"
else
    echo "Done. Start now with: $BOOT_SCRIPT"
fi
