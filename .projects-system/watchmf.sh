#!/usr/bin/env bash
# =============================================================================
# watch.sh — Daemon de surveillance des dossiers système → ~/Projects
# Surveille ~/Downloads, ~/Desktop, ~/Documents, ~/Pictures, ~/Movies, ~/Music
# Lancé automatiquement par launchd au démarrage de session.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "[projects-watch] Démarré le $(date)"
echo "[projects-watch] Destination  : $PROJECTS_DIR"
echo "[projects-watch] Sources surveillées :"
for d in "${WATCH_DIRS[@]}"; do
  if [ -d "$d" ]; then
    echo "[projects-watch]   ✓ $d"
  else
    echo "[projects-watch]   ✗ $d (introuvable, ignoré)"
  fi
done

# Construire la liste des dossiers existants
EXISTING_DIRS=()
for d in "${WATCH_DIRS[@]}"; do
  [ -d "$d" ] && EXISTING_DIRS+=("$d")
done

if [ ${#EXISTING_DIRS[@]} -eq 0 ]; then
  echo "[projects-watch] Aucun dossier source trouvé, arrêt."
  exit 1
fi

# fswatch surveille tous les dossiers sources en un seul appel
# --event Created  : nouveau fichier créé
# --event Renamed  : fichier renommé (fin de téléchargement .crdownload → .pdf etc.)
# --event MovedTo  : fichier déplacé dans le dossier
# -0               : séparateur \0 (safe pour les espaces dans les noms)
# --depth 1        : seulement la racine de chaque dossier source (pas récursif)

fswatch \
  --event Created \
  --event Renamed \
  --event MovedTo \
  -0 \
  "${EXISTING_DIRS[@]}" \
  | while IFS= read -r -d $'\0' filepath; do

    # Ignorer les dossiers
    [ -f "$filepath" ] || continue

    REAL_PROJECTS="$(realpath "$PROJECTS_DIR" 2>/dev/null || echo "$PROJECTS_DIR")"
    REAL_FDIR="$(realpath "$(dirname "$filepath")" 2>/dev/null || echo "$(dirname "$filepath")")"

    # Ne pas re-traiter les fichiers qui arrivent dans ~/Projects lui-même
    [[ "$REAL_FDIR" == "$REAL_PROJECTS"* ]] && continue

    # Simuler --depth 1 : ignorer les fichiers dans des sous-dossiers des sources
    # Le parent direct du fichier doit être l'un des EXISTING_DIRS (et rien de plus profond)
    DEPTH_OK=false
    for src in "${EXISTING_DIRS[@]}"; do
      REAL_SRC="$(realpath "$src" 2>/dev/null || echo "$src")"
      [ "$REAL_FDIR" = "$REAL_SRC" ] && DEPTH_OK=true && break
    done
    $DEPTH_OK || continue

    echo "[projects-watch] Événement : $filepath"

    # Classifier en arrière-plan (ne bloque pas la surveillance)
    "$SCRIPT_DIR/classify.sh" "$filepath" &

  done
