#!/usr/bin/env bash
# =============================================================================
# projects-sort.sh — Tri manuel de tous les dossiers sources vers ~/Projects
# Usage :
#   projects-sort               → trier tous les dossiers sources
#   projects-sort --dry-run     → simuler sans rien déplacer
#   projects-sort ~/Downloads   → trier uniquement un dossier spécifique
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

DRY_RUN=false
CUSTOM_DIR=""

# Analyser les arguments
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && DRY_RUN=true
  [[ "$arg" == ~* || "$arg" == /* ]] && CUSTOM_DIR="$arg"
done

CLASSIFY_DELAY=0
export CLASSIFY_DELAY

# Déterminer les dossiers à traiter
if [ -n "$CUSTOM_DIR" ]; then
  if [ ! -d "$CUSTOM_DIR" ]; then
    echo "✗ Dossier introuvable : $CUSTOM_DIR"
    exit 1
  fi
  TARGET_DIRS=("$CUSTOM_DIR")
else
  TARGET_DIRS=()
  for d in "${WATCH_DIRS[@]}"; do
    [ -d "$d" ] && TARGET_DIRS+=("$d")
  done
fi

echo ""
if $DRY_RUN; then
  echo "╔══════════════════════════════════════════════╗"
  echo "║   projects-sort — MODE SIMULATION (dry-run)  ║"
  echo "╚══════════════════════════════════════════════╝"
else
  echo "╔══════════════════════════════════════════════╗"
  echo "║   projects-sort — Tri en cours…              ║"
  echo "╚══════════════════════════════════════════════╝"
fi
echo ""

TOTAL_FILES=0
TOTAL_MOVED=0

for SOURCE_DIR in "${TARGET_DIRS[@]}"; do
  SOURCE_NAME="$(basename "$SOURCE_DIR")"
  DIR_COUNT=0

  while IFS= read -r -d $'\0' filepath; do
    [ -f "$filepath" ] || continue

    FILENAME="$(basename "$filepath")"
    EXT="${FILENAME##*.}"
    EXT="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"

    # Ignorer préfixes
    SKIP=false
    IFS=',' read -ra PRFX <<< "$IGNORE_PREFIXES"
    for p in "${PRFX[@]}"; do
      p="${p// /}"
      [ -z "$p" ] && continue
      [[ "$FILENAME" == "$p"* ]] && SKIP=true && break
    done
    $SKIP && continue

    # Ignorer extensions blacklistées
    IFS=',' read -ra IGN <<< "$IGNORE_EXTENSIONS"
    for i in "${IGN[@]}"; do
      i="${i// /}"
      [ "$EXT" = "$i" ] && SKIP=true && break
    done
    $SKIP && continue

    # Trouver la catégorie
    TARGET_CATEGORY=""
    for rule in "${CLASSIFY_RULES[@]}"; do
      IFS='|' read -ra PARTS <<< "$rule"
      CATEGORY="${PARTS[0]}"
      EXTENSIONS="${PARTS[1]:-}"
      IFS=',' read -ra EXTS <<< "$EXTENSIONS"
      for e in "${EXTS[@]}"; do
        e="${e// /}"
        if [ "$EXT" = "$e" ]; then
          TARGET_CATEGORY="$CATEGORY"
          break 2
        fi
      done
    done
    [ -z "$TARGET_CATEGORY" ] && TARGET_CATEGORY="_inbox"

    printf "  %-40s  %-12s →  %s/\n" "$FILENAME" "[$SOURCE_NAME]" "$TARGET_CATEGORY"
    TOTAL_FILES=$((TOTAL_FILES + 1))
    DIR_COUNT=$((DIR_COUNT + 1))

    if ! $DRY_RUN; then
      DEST_DIR="$PROJECTS_DIR/$TARGET_CATEGORY"
      mkdir -p "$DEST_DIR"
      DEST_FILE="$DEST_DIR/$FILENAME"
      if [ -f "$DEST_FILE" ]; then
        BASE="${FILENAME%.*}"
        if [ "$BASE" = "$FILENAME" ]; then
          DEST_FILE="$DEST_DIR/${FILENAME}_$(date +%s)"
        else
          DEST_FILE="$DEST_DIR/${BASE}_$(date +%s).${EXT}"
        fi
      fi
      mv "$filepath" "$DEST_FILE"
      TOTAL_MOVED=$((TOTAL_MOVED + 1))
    fi

  done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)

  [ "$DIR_COUNT" -gt 0 ] && echo ""
done

echo ""
if [ "$TOTAL_FILES" -eq 0 ]; then
  echo "  Aucun fichier à trier dans les dossiers sources."
elif $DRY_RUN; then
  echo "  $TOTAL_FILES fichier(s) seraient déplacés vers ~/Projects."
  echo "  Lance sans --dry-run pour confirmer."
else
  echo "  ✅  $TOTAL_MOVED fichier(s) classé(s) dans ~/Projects."
fi
echo ""
