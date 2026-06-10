# 📁 Projects Auto-Classifier

A lightweight macOS file automation system that **automatically sorts files dropped into `~/Projects`** into categorized subfolders — no app, no GUI, just shell scripts and a background daemon.

> Tested on **macOS with Apple Silicon (M3)**. Compatible with any Mac running macOS 12 Monterey or later with Homebrew installed. See [compatibility notes](#compatibility) below.

---

## ✨ What it does

Drop any file into `~/Projects/` and it gets automatically moved to the right subfolder within 3 seconds:

```
~/Projects/
├── Coding/      → .py .js .ts .sh .go .swift .rb …
├── Web/         → .html .css .vue .svelte .jsx …
├── Notes/       → .md .txt .pages .rst …
├── Docs/        → .pdf .docx .pptx .xlsx .epub …
├── Design/      → .fig .sketch .xd .psd .ai …
├── Data/        → .csv .json .yaml .sql …
├── Media/       → .png .mp4 .svg .mp3 …
└── _inbox/      → anything that doesn't match a rule
```

You can also trigger a manual sort at any time with `projects-sort`, or preview what would happen with `projects-sort --dry-run`.

---

## 📦 What's included

| File | Role |
|------|------|
| `install.sh` | One-time setup: creates folders, installs scripts, registers the background daemon |
| `config.sh` | All classification rules — edit this to customize categories |
| `classify.sh` | Core logic: given a file path, moves it to the right folder |
| `watch.sh` | Background daemon: watches `~/Projects` with `fswatch` and calls `classify.sh` |
| `projects-sort.sh` | Manual sort command: processes all unsorted files at once |
| `icons/` | Custom `.icns` folder icons for each category (optional, see [Folder Icons](#-folder-icons)) |

---

## 🚀 Installation

### Prerequisites

- macOS 12 Monterey or later
- [Homebrew](https://brew.sh) installed (`fswatch` is installed automatically if missing)

### Steps

```bash
# 1. Clone or download this repo
git clone https://github.com/YOUR_USERNAME/projects-classifier.git
cd projects-classifier

# 2. Run the installer
bash install.sh

# 3. Reload your shell
source ~/.zshrc
```

The installer will:
- Create `~/Projects/` and all category subfolders
- Copy scripts to `~/.projects-system/`
- Register a launchd daemon that starts automatically at login
- Add shell aliases to your `.zshrc`

> **Note:** If `fswatch` is not found, the installer runs `brew install fswatch` automatically.

---

## 🖥️ Terminal Commands

After installation, these aliases are available in your terminal:

```bash
projects                 # cd ~/Projects
projects-sort            # sort all unsorted files now
projects-sort --dry-run  # preview what would be moved (nothing is touched)
projects-watch-status    # check if the background daemon is running
projects-watch-start     # start the daemon
projects-watch-stop      # stop the daemon
```

Logs are written to:
```
~/Library/Logs/projects-classifier.log
~/Library/Logs/projects-classifier-error.log
```

---

## ⚙️ Configuration

All rules live in `~/.projects-system/config.sh`. Open it to add or modify categories:

```bash
# Format: "CATEGORY|ext1,ext2,ext3"
# Rules are read top-to-bottom — first match wins.

"Arduino|ino,pde"
"Config|env,yaml,toml,ini,cfg"
```

After editing, no restart is needed for `projects-sort`. To apply changes to the daemon:

```bash
projects-watch-stop && projects-watch-start
```

---

## 🎨 Folder Icons

The `icons/` folder contains custom `.icns` files for each category. Applying them is optional but gives your `~/Projects` a polished look in Finder.

See [HowToUse.md](HowToUse.md) for the full step-by-step guide (Finder method + terminal method).

---

## 🖥️ Compatibility

| Configuration | Status | Notes |
|---|---|---|
| Apple Silicon M1/M2/M3 (macOS 12+) | ✅ Fully tested | Primary target |
| Intel Mac (macOS 12+) | ✅ Should work | Homebrew path may differ (`/usr/local/bin` instead of `/opt/homebrew/bin`) |
| macOS 11 Big Sur | ⚠️ Likely works | Not tested |
| macOS 10.15 Catalina or earlier | ❌ Not supported | `zsh` default shell required |
| Linux | ❌ Not supported | `launchd` is macOS-only; `inotifywait` would be needed instead |

**Intel Mac users:** If `fswatch` is not found by the daemon, add this line to your plist manually:
```xml
<key>EnvironmentVariables</key>
<dict>
  <key>PATH</key>
  <string>/usr/local/bin:/usr/bin:/bin</string>
</dict>
```

---

## 🗑️ Uninstall

```bash
# Stop and remove the daemon
launchctl unload ~/Library/LaunchAgents/com.user.projects-classifier.plist
rm ~/Library/LaunchAgents/com.user.projects-classifier.plist

# Remove scripts
rm -rf ~/.projects-system

# Remove aliases — open ~/.zshrc and delete the "Projects system" block manually
```

Your `~/Projects/` folder and its contents are left untouched.

---

## 📄 License

MIT — do whatever you want with it.
