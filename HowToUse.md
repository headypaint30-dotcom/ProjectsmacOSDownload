# How To Use — Projects Auto-Classifier

A practical guide covering everything from first install to advanced customization.

---

## Table of Contents

1. [First Install](#1-first-install)
2. [Daily Usage](#2-daily-usage)
3. [Folder Icons](#3-folder-icons)
4. [Customizing Rules](#4-customizing-rules)
5. [Daemon Management](#5-daemon-management)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. First Install

### Clone the repo and run the installer

```bash
git clone https://github.com/ProjectsmacOS-OFF/ProjectsmacOSDownload.git
cd ProjectsmacOSDownload
bash install.sh
source ~/.zshrc
```

### What the installer creates

```
~/.projects-system/
├── classify.sh        ← core logic
├── watch.sh           ← background daemon
├── projects-sort.sh   ← manual sort command
└── config.sh          ← your rules (edit this)

~/Projects/
├── Coding/
├── Web/
├── Notes/
├── Docs/
├── Design/
├── Data/
├── Media/
└── _inbox/

~/Library/LaunchAgents/com.user.projects-classifier.plist   ← daemon registration
~/Library/Logs/projects-classifier.log                      ← daemon logs
```

---

## 2. Daily Usage

### Automatic mode (default)

The daemon starts at login and runs silently. Just drop any file into `~/Projects/` — it will be moved to the right subfolder within **3 seconds**.

Files already inside a subfolder (e.g. `~/Projects/Coding/myfile.py`) are never touched.

### Manual sort

If you disabled the daemon or want to sort a batch of files at once:

```bash
projects-sort
```

Preview first without moving anything:

```bash
projects-sort --dry-run
```

Example output:
```
╔══════════════════════════════════════════╗
║  projects-sort — MODE SIMULATION (dry)   ║
╚══════════════════════════════════════════╝

  report.pdf       →  Docs/
  app.py           →  Coding/
  mockup.fig       →  Design/
  random_file.xyz  →  _inbox/

  4 file(s) would be moved. Run without --dry-run to confirm.
```

### Navigating to Projects

```bash
projects
```

This is just an alias for `cd ~/Projects`.

---

## 3. Folder Icons

The `icons/` folder in this repo contains custom `.icns` files for each category. Here's how to apply them.

### Method A — Finder (no terminal, one by one)

1. Open the `icons/` folder in Finder
2. Double-click an `.icns` file (e.g. `Coding.icns`) — it opens in Preview
3. Press `⌘A` then `⌘C` to select and copy the image
4. In Finder, right-click on your target folder (e.g. `~/Projects/Coding`) → **Get Info** (`⌘I`)
5. In the info panel, click the **small folder icon in the top-left corner** (it gets highlighted with a blue border)
6. Press `⌘V` — the icon updates immediately
7. Close the info panel and repeat for each folder

> **Tip:** You can apply an icon to the `~/Projects` root folder itself too — use the `Projects.icns` file if included.

### Method B — Terminal (all 8 folders at once)

This uses [`fileicon`](https://github.com/mklement0/fileicon), a small CLI tool.

```bash
# Install fileicon
brew install fileicon

# Apply all icons from the icons/ folder (run from the repo root)
fileicon set ~/Projects/_inbox  icons/Projects.icns
fileicon set ~/Projects/Coding  icons/Projects.icns
fileicon set ~/Projects/Data    icons/Projects.icns
fileicon set ~/Projects/Design  icons/Projects.icns
fileicon set ~/Projects/Docs    icons/Projects.icns
fileicon set ~/Projects/Media   icons/Projects.icns
fileicon set ~/Projects/Notes   icons/Projects.icns
fileicon set ~/Projects/Web     icons/Projects.icns
```

### Removing an icon

```bash
fileicon rm ~/Projects/Coding
```

Or via Finder: open Get Info on the folder, click the small icon in the top-left, press `⌫` (Delete).

### Why icons might look dark in Dark Mode

The `.icns` files use a light folder base with a colored glyph overlay. They are designed to be readable in both Light and Dark Mode. If a custom PNG you supply has a transparent background with dark strokes only, it will appear invisible in Dark Mode — always use the provided `.icns` files or generate new ones with a contrasted glyph.

---

## 4. Customizing Rules

Open the config file:

```bash
open ~/.projects-system/config.sh
# or
nano ~/.projects-system/config.sh
```

### Rule format

```bash
"CATEGORY|ext1,ext2,ext3"
```

- `CATEGORY` must match an existing subfolder name in `~/Projects/` (case-sensitive on APFS volumes formatted as case-sensitive)
- Extensions are lowercase, without the leading dot
- Rules are evaluated **top to bottom** — the first match wins

### Examples

```bash
# Add a category for Arduino sketches
"Arduino|ino,pde"

# Add a category for config/dotfiles
"Config|env,ini,cfg,toml"

# Re-route YAML to Notes instead of Data
# (move this rule ABOVE the Data rule)
"Notes|md,markdown,txt,rst,yaml,yml"
```

### Ignoring files

```bash
# Extensions that are never moved (system/temp files)
export IGNORE_EXTENSIONS="ds_store,localized,swp,tmp,bak,log"

# Filename prefixes that are never moved (hidden files, temp files)
export IGNORE_PREFIXES=".,.~,~"
```

### Adjusting the delay

By default the daemon waits 3 seconds before moving a file (to let downloads finish writing):

```bash
export CLASSIFY_DELAY=3   # seconds
```

Set to `0` for instant classification (not recommended for network downloads).

### Applying config changes

For `projects-sort` (manual): changes take effect immediately.

For the daemon: restart it:

```bash
projects-watch-stop && projects-watch-start
```

---

## 5. Daemon Management

The daemon is a **launchd agent** — it starts automatically at login and restarts itself if it crashes.

```bash
projects-watch-status    # show PID and exit code (- = stopped, number = running)
projects-watch-start     # load and start the daemon
projects-watch-stop      # stop and unload the daemon
```

### Checking logs

```bash
tail -f ~/Library/Logs/projects-classifier.log
```

Look for lines like:
```
[projects-watch] Started Wed Jun 10 14:00:00 2026
[projects-watch] Event: /Users/you/Projects/report.pdf
[projects] 14:00:03 ▸ report.pdf → Docs/
```

### Daemon not starting?

The most common cause is `fswatch` not being found because launchd uses a minimal `PATH` that doesn't include Homebrew. Fix it by adding the PATH to the plist:

```bash
/usr/libexec/PlistBuddy \
  -c "Add :EnvironmentVariables dict" \
  ~/Library/LaunchAgents/com.user.projects-classifier.plist

/usr/libexec/PlistBuddy \
  -c "Add :EnvironmentVariables:PATH string /opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin" \
  ~/Library/LaunchAgents/com.user.projects-classifier.plist

projects-watch-stop && projects-watch-start
```

> **Intel Mac users:** Replace `/opt/homebrew/bin` with `/usr/local/bin`.

---

## 6. Troubleshooting

### `projects-sort: command not found`

The aliases aren't loaded yet. Run:
```bash
source ~/.zshrc
```

### `bash: install.sh: No such file or directory`

You're not in the right directory. Run:
```bash
cd /path/to/where/you/cloned/projects-classifier
bash install.sh
```

### Files aren't being sorted automatically

Check the daemon status:
```bash
projects-watch-status
tail -20 ~/Library/Logs/projects-classifier.log
tail -20 ~/Library/Logs/projects-classifier-error.log
```

If you see `fswatch: command not found` in the error log, apply the PATH fix from [Daemon not starting?](#daemon-not-starting) above.

### A file ended up in `_inbox` but I expected it elsewhere

The file extension didn't match any rule. Check what extension it has, then add it to `config.sh`. Also make sure the extension in the config is **lowercase** (e.g. `PDF` won't match — use `pdf`).

### Duplicate files (filename with `_timestamp` suffix)

If a file with the same name already exists in the destination folder, the system appends a Unix timestamp to avoid overwriting. This is intentional.

### The daemon is restarting in a loop

Check the error log:
```bash
tail -50 ~/Library/Logs/projects-classifier-error.log
```

A crash loop usually means either `fswatch` is missing (see above) or `watch.sh` has a syntax error. You can test watch.sh manually:
```bash
bash ~/.projects-system/watch.sh
```

---

## Credits

Built with: `fswatch`, `launchd`, and pure bash. No dependencies beyond Homebrew.
