# Dreeve GPX Sync for Termux

Automatically upload `.gpx` files from your Android phone (e.g. [FitoTrack](https://codeberg.org/jannis/FitoTrack) auto-exports) to a self-hosted [Dreeve](https://docs.dreeve.app/) instance.

- Uploads every existing `.gpx` file on start (Dreeve deduplicates server-side, so this is safe).
- Watches the folder with `inotifywait` and uploads new files as soon as they are written.
- Starts automatically on boot via Termux:Boot and retries when the network is down.

## Install

1. Install [Termux](https://f-droid.org/packages/com.termux/) and [Termux:Boot](https://f-droid.org/packages/com.termux.boot/) from F-Droid, then open Termux:Boot once.
2. In Termux:

   ```bash
   termux-setup-storage          # only if WATCH_DIR is in shared storage
   pkg install -y git
   git clone https://github.com/Constantin-Hentgen/Dreeve-Fitotrack-Sync.git
   cd Dreeve-Fitotrack-Sync
   ./install.sh
   nano .env                     # set DREEVE_URL, DREEVE_TOKEN, WATCH_DIR
   ~/.termux/boot/gpx-sync       # start now (it also starts on every boot)
   ```

## Configuration (`.env`)

| Variable       | Example                          | Description                           |
| -------------- | -------------------------------- | ------------------------------------- |
| `DREEVE_URL`   | `https://dreeve.example.com`     | Base URL of your Dreeve instance      |
| `DREEVE_TOKEN` | `abc123…`                        | Dreeve API token                      |
| `WATCH_DIR`    | `/storage/emulated/0/FitoTrack`  | Folder your tracker exports GPX into  |

`.env` is git-ignored and never leaves your phone.

## Usage

| Action  | Command                                            |
| ------- | -------------------------------------------------- |
| Start   | `~/.termux/boot/gpx-sync`                          |
| Stop    | `pkill -f gpx-sync.sh`                             |
| Status  | `pgrep -af gpx-sync.sh`                            |
| Logs    | `tail -f ~/Dreeve-Fitotrack-Sync/gpx-sync.log`     |
| Update  | `git pull`, then stop and start                    |

Optional: to also start it whenever you open Termux, add this line to `~/.bashrc`:

```bash
~/.termux/boot/gpx-sync
```

## Android settings

Android aggressively kills background apps. For Termux:

1. **Battery:** Settings > Apps > Termux > Battery > *Unrestricted*.
2. **Auto-start:** enable *Auto-start* / *Launch in background* if your vendor has it.
3. On MIUI / OneUI / ColorOS, lock Termux in the recent apps view.

## Troubleshooting

- **`FAIL (000)`**: network or DNS error; curl retries 5 times, 30 s apart. Files that still fail are re-sent on the next start.
- **`FAIL (401)`**: wrong `DREEVE_TOKEN`.
- **New files are not detected**: some Android versions do not deliver inotify events for files written by other apps in shared storage. Restarting the watcher triggers a full resync.

## License

[MIT](LICENSE)
