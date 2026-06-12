#!/usr/bin/env bash
# =============================================================================
# classifymf.sh — Classe un fichier dans ~/Projects selon son extension
# Usage : classifymf.sh /chemin/vers/fichier
# Fonctionne pour tout fichier venant de n'importe quel dossier source.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/configmf.sh"

FILE="$1"

# ── Gardes ────────────────────────────────────────────────────────────────
[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

FILENAME="$(basename "$FILE")"
DIRPATH="$(dirname "$FILE")"

# Ignorer les fichiers dont le nom commence par un préfixe blacklisté
IFS=',' read -ra PRFX <<< "$IGNORE_PREFIXES"
for p in "${PRFX[@]}"; do
  p="${p// /}"
  [ -z "$p" ] && continue
  if [[ "$FILENAME" == "$p"* ]]; then
    [ "$VERBOSE_LOG" = "true" ] && echo "[projects] ignoré (préfixe '$p') : $FILENAME"
    exit 0
  fi
done

# Obtenir l'extension (en minuscule, sans le point)
EXT="${FILENAME##*.}"
EXT="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"

# Fichier sans extension → inbox
if [ "$EXT" = "$FILENAME" ] || [ -z "$EXT" ]; then
  EXT=""
fi

# Ignorer les extensions blacklistées (téléchargements en cours, fichiers système…)
IFS=',' read -ra IGN <<< "$IGNORE_EXTENSIONS"
for i in "${IGN[@]}"; do
  i="${i// /}"
  [ "$EXT" = "$i" ] && exit 0
done

# ── Éviter de reclasser un fichier déjà dans ~/Projects/ ──────────────────
# Si le fichier est DÉJÀ dans un sous-dossier de ~/Projects, on ne touche pas.
REAL_PROJECTS="$(realpath "$PROJECTS_DIR" 2>/dev/null || echo "$PROJECTS_DIR")"
REAL_DIR="$(realpath "$DIRPATH" 2>/dev/null || echo "$DIRPATH")"

if [[ "$REAL_DIR" == "$REAL_PROJECTS"* ]]; then
  [ "$VERBOSE_LOG" = "true" ] && echo "[projects] déjà dans Projects ($DIRPATH) : $FILENAME"
  exit 0
fi

# ── Attendre le délai (fichier potentiellement en cours d'écriture) ───────
sleep "${CLASSIFY_DELAY:-5}"

# Re-vérifier que le fichier existe toujours après le délai
[ ! -f "$FILE" ] && exit 0

# ── Chercher la catégorie dans les règles ─────────────────────────────────
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

# Aucune règle → inbox
[ -z "$TARGET_CATEGORY" ] && TARGET_CATEGORY="_inbox"

# ── Déplacer le fichier vers ~/Projects/<catégorie>/ ──────────────────────
DEST_DIR="$PROJECTS_DIR/$TARGET_CATEGORY"
mkdir -p "$DEST_DIR"

DEST_FILE="$DEST_DIR/$FILENAME"

# Gérer les conflits de nom (ajouter un timestamp si le fichier existe déjà)
if [ -f "$DEST_FILE" ]; then
  BASE="${FILENAME%.*}"
  if [ "$BASE" = "$FILENAME" ]; then
    DEST_FILE="$DEST_DIR/${FILENAME}_$(date +%s)"
  else
    DEST_FILE="$DEST_DIR/${BASE}_$(date +%s).${EXT}"
  fi
fi

mv "$FILE" "$DEST_FILE"

if [ "$VERBOSE_LOG" = "true" ]; then
  SOURCE_DIR="$(basename "$DIRPATH")"
  echo "[projects] $(date '+%H:%M:%S') ▸ $FILENAME  [$SOURCE_DIR → $TARGET_CATEGORY/]"
fi
