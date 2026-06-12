#!/usr/bin/env bash
# =============================================================================
# install.sh — Installation du système Projects Auto-Classifier
# Surveille ~/Downloads, ~/Desktop, ~/Documents, ~/Pictures, ~/Movies, ~/Music
# et classe automatiquement les fichiers dans ~/Projects/
# =============================================================================

set -e

PROJECTS_DIR="$HOME/Projects"
SCRIPTS_DIR="$HOME/.projects-system"
PLIST_PATH="$HOME/Library/LaunchAgents/com.user.projects-classifier.plist"
SHELL_RC=""

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Projects Auto-Classifier — Install     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Dépendance : fswatch ────────────────────────────────────────────────
if ! command -v fswatch &>/dev/null; then
  echo "→ Installation de fswatch via Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "✗ Homebrew introuvable. Installe-le depuis https://brew.sh puis relance ce script."
    exit 1
  fi
  brew install fswatch
fi
echo "✓ fswatch : $(fswatch --version 2>&1 | head -1)"

# Résoudre le chemin absolu de fswatch (évite tout problème de PATH dans launchd)
FSWATCH_PATH="$(command -v fswatch)"
FSWATCH_DIR="$(dirname "$FSWATCH_PATH")"
echo "✓ fswatch path : $FSWATCH_PATH"

# ── 2. Dossier ~/Projects + catégories ────────────────────────────────────
echo ""
echo "→ Création de ~/Projects et ses catégories..."
mkdir -p "$PROJECTS_DIR"/{Coding,Web,Notes,Design,Data,Docs,Media,_inbox}
touch "$PROJECTS_DIR/.localized"
echo "✓ Structure ~/Projects créée."

# ── 3. Dossier des scripts internes ───────────────────────────────────────
mkdir -p "$SCRIPTS_DIR"

# ── 4. Copier les scripts ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/classify.sh"      "$SCRIPTS_DIR/classify.sh"
cp "$SCRIPT_DIR/watch.sh"         "$SCRIPTS_DIR/watch.sh"
cp "$SCRIPT_DIR/config.sh"        "$SCRIPTS_DIR/config.sh"
cp "$SCRIPT_DIR/projects-sort.sh" "$SCRIPTS_DIR/projects-sort.sh"
chmod +x "$SCRIPTS_DIR/"*.sh
echo "✓ Scripts installés dans $SCRIPTS_DIR"

# ── 5. Alias terminal ─────────────────────────────────────────────────────
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
  SHELL_RC="$HOME/.bash_profile"
fi

ALIAS_BLOCK='
# ── Projects Auto-Classifier ──────────────────────────────────────────────
alias projects="cd ~/Projects"
alias projects-sort="~/.projects-system/projects-sort.sh"
alias projects-watch-status="launchctl list | grep projects-classifier"
alias projects-watch-start="launchctl load ~/Library/LaunchAgents/com.user.projects-classifier.plist"
alias projects-watch-stop="launchctl unload ~/Library/LaunchAgents/com.user.projects-classifier.plist"
# ─────────────────────────────────────────────────────────────────────────'

if [ -n "$SHELL_RC" ]; then
  if ! grep -q "Projects Auto-Classifier" "$SHELL_RC"; then
    echo "$ALIAS_BLOCK" >> "$SHELL_RC"
    echo "✓ Alias ajoutés dans $SHELL_RC"
  else
    echo "✓ Alias déjà présents dans $SHELL_RC"
  fi
else
  echo "⚠ Shell config introuvable. Ajoute manuellement dans ~/.zshrc :"
  echo "$ALIAS_BLOCK"
fi

# ── 6. Détecter les dossiers sources disponibles ──────────────────────────
echo ""
echo "→ Dossiers sources qui seront surveillés :"
for d in "$HOME/Downloads" "$HOME/Desktop" "$HOME/Documents" "$HOME/Pictures" "$HOME/Movies" "$HOME/Music"; do
  if [ -d "$d" ]; then
    echo "   ✓ $d"
  else
    echo "   ✗ $d (absent sur ce Mac)"
  fi
done

# ── 7. LaunchAgent ────────────────────────────────────────────────────────
mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$HOME/Library/Logs"

# Construire le PATH pour launchd : inclure le dossier de fswatch en priorité
LAUNCHD_PATH="${FSWATCH_DIR}:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.projects-classifier</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SCRIPTS_DIR/watch.sh</string>
  </array>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$LAUNCHD_PATH</string>
    <key>HOME</key>
    <string>$HOME</string>
    <key>USER</key>
    <string>$USER</string>
    <key>SHELL</key>
    <string>/bin/bash</string>
  </dict>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/projects-classifier.log</string>

  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/projects-classifier-error.log</string>

  <key>ThrottleInterval</key>
  <integer>2</integer>
</dict>
</plist>
PLIST

echo ""
echo "✓ LaunchAgent créé : $PLIST_PATH"
echo "✓ PATH launchd     : $LAUNCHD_PATH"

# ── 8. Valider le plist ───────────────────────────────────────────────────
if plutil -lint "$PLIST_PATH" &>/dev/null; then
  echo "✓ plist valide"
else
  echo "✗ plist invalide — voici l'erreur :"
  plutil -lint "$PLIST_PATH"
  exit 1
fi

# ── 9. Lancer le daemon ───────────────────────────────────────────────────
# Utiliser bootout/bootstrap (API moderne, recommandée depuis macOS Monterey)
DOMAIN="gui/$(id -u)"

launchctl bootout "$DOMAIN/com.user.projects-classifier" 2>/dev/null || true
sleep 1
launchctl bootstrap "$DOMAIN" "$PLIST_PATH"
echo "✓ Daemon démarré (domaine : $DOMAIN)"

# Vérifier que le daemon est bien enregistré
sleep 1
if launchctl print "$DOMAIN/com.user.projects-classifier" &>/dev/null; then
  echo "✓ Daemon actif et enregistré"
else
  echo "⚠ Le daemon n'apparaît pas encore dans launchctl — vérifie les logs :"
  echo "   cat ~/Library/Logs/projects-classifier-error.log"
fi

# ── 10. Résumé ────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  ✅  Installation terminée !                                     ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║                                                                  ║"
echo "║  Le daemon surveille maintenant tes dossiers système.            ║"
echo "║  Tout fichier déposé dans Downloads, Desktop, Documents, etc.    ║"
echo "║  est automatiquement classé dans ~/Projects/<catégorie>/.        ║"
echo "║                                                                  ║"
echo "║  Commandes disponibles :                                         ║"
echo "║    projects              → cd ~/Projects                         ║"
echo "║    projects-sort         → trier manuellement                    ║"
echo "║    projects-sort --dry-run → simuler                             ║"
echo "║    projects-sort ~/Downloads → trier un seul dossier             ║"
echo "║    projects-watch-status → état du daemon                        ║"
echo "║    projects-watch-start  → démarrer le daemon                    ║"
echo "║    projects-watch-stop   → arrêter le daemon                     ║"
echo "║                                                                  ║"
echo "║  Config  : ~/.projects-system/config.sh                          ║"
echo "║  Logs    : ~/Library/Logs/projects-classifier.log                ║"
echo "║  Erreurs : ~/Library/Logs/projects-classifier-error.log          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
[ -n "$SHELL_RC" ] && echo "→ Lance : source $SHELL_RC"
echo ""
