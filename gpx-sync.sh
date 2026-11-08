#!/usr/bin/env bash
# Upload GPX files to a Dreeve instance: all existing files on start,
# then every new file as soon as it lands in WATCH_DIR.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"

log() { printf '%s %s\n' "$(date '+%F %T')" "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

[ -f "$ENV_FILE" ] || die "missing $ENV_FILE (cp .env.example .env and edit it)"
set -a; . "$ENV_FILE"; set +a

: "${DREEVE_URL:?DREEVE_URL is not set in $ENV_FILE}"
: "${DREEVE_TOKEN:?DREEVE_TOKEN is not set in $ENV_FILE}"
: "${WATCH_DIR:?WATCH_DIR is not set in $ENV_FILE}"

WATCH_DIR="${WATCH_DIR%/}"
UPLOAD_URL="${DREEVE_URL%/}/api/v1/activity/upload"

for cmd in curl inotifywait; do
    command -v "$cmd" >/dev/null || die "$cmd not found (pkg install curl inotify-tools)"
done
[ -d "$WATCH_DIR" ] || die "WATCH_DIR does not exist: $WATCH_DIR"

upload() {
    local file=$1 code
    code=$(curl -sS -o /dev/null -w '%{http_code}' \
        --max-time 120 --retry 5 --retry-delay 30 --retry-all-errors \
        -H "Authorization: Bearer $DREEVE_TOKEN" \
        -F "file=@$file" \
        "$UPLOAD_URL")
    case $code in
        2??) log "OK   ($code) ${file##*/}" ;;
        *)   log "FAIL ($code) ${file##*/}" ;;
    esac
}

# 1. Initial sync. Dreeve deduplicates server-side, so re-sending is safe.
log "Initial sync of $WATCH_DIR"
shopt -s nullglob nocaseglob
for file in "$WATCH_DIR"/*.gpx; do
    upload "$file"
done
shopt -u nullglob nocaseglob

# 2. Watch for new files (written in place or moved/renamed into the folder).
log "Watching $WATCH_DIR"
inotifywait -m -q -e close_write -e moved_to --format '%f' "$WATCH_DIR" |
while IFS= read -r name; do
    [[ ${name,,} == *.gpx ]] && upload "$WATCH_DIR/$name"
done
