#!/usr/bin/env bash
# =============================================================================
# classify.sh — Classe un fichier dans ~/Projects selon son extension
# Usage : classify.sh /chemin/vers/fichier
# =============================================================================

# Charger la config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

FILE="$1"

# ── Gardes ────────────────────────────────────────────────────────────────

# Fichier inexistant ou dossier → on ignore
[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

FILENAME="$(basename "$FILE")"
DIRPATH="$(dirname "$FILE")"

# Ignorer les fichiers dont le nom commence par un préfixe blacklisté
IFS=',' read -ra PRFX <<< "$IGNORE_PREFIXES"
for p in "${PRFX[@]}"; do
  # Trim whitespace
  p="${p// /}"
  [ -z "$p" ] && continue
  if [[ "$FILENAME" == "$p"* ]]; then
    [ "$VERBOSE_LOG" = "true" ] && echo "[projects] ignoré (préfixe '$p') : $FILENAME"
    exit 0
  fi
done

# Obtenir l'extension (en minuscule, sans le point)
EXT="${FILENAME##*.}"
EXT="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"   # lowercase

# Fichier sans extension ou extension = nom complet (fichiers cachés genre .bashrc) → inbox
if [ "$EXT" = "$FILENAME" ] || [ -z "$EXT" ]; then
  EXT=""
fi

# Ignorer les extensions blacklistées
IFS=',' read -ra IGN <<< "$IGNORE_EXTENSIONS"
for i in "${IGN[@]}"; do
  i="${i// /}"
  [ "$EXT" = "$i" ] && exit 0
done

# ── Le fichier est-il déjà dans un sous-dossier de ~/Projects ? ───────────
# Si oui, on ne le reclasse pas (évite les boucles)
REAL_PROJECTS="$(realpath "$PROJECTS_DIR" 2>/dev/null || echo "$PROJECTS_DIR")"
REAL_DIR="$(realpath "$DIRPATH" 2>/dev/null || echo "$DIRPATH")"

# On vérifie que le fichier est directement dans la racine ~/Projects
# (pas dans un sous-dossier de catégorie)
if [ "$REAL_DIR" != "$REAL_PROJECTS" ]; then
  [ "$VERBOSE_LOG" = "true" ] && echo "[projects] déjà classé dans $DIRPATH : $FILENAME"
  exit 0
fi

# ── Attendre le délai (fichier potentiellement en cours d'écriture) ───────
sleep "${CLASSIFY_DELAY:-3}"

# Re-vérifier que le fichier existe toujours après le délai
[ ! -f "$FILE" ] && exit 0

# ── Chercher la catégorie dans les règles ─────────────────────────────────
TARGET_CATEGORY=""

for rule in "${CLASSIFY_RULES[@]}"; do
  # Format : "CATEGORIE|ext1,ext2,..."
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
if [ -z "$TARGET_CATEGORY" ]; then
  TARGET_CATEGORY="_inbox"
fi

# ── Déplacer le fichier ────────────────────────────────────────────────────
DEST_DIR="$PROJECTS_DIR/$TARGET_CATEGORY"
mkdir -p "$DEST_DIR"

# Gérer les conflits de nom : si le fichier existe déjà, on ajoute un suffixe
DEST_FILE="$DEST_DIR/$FILENAME"
if [ -f "$DEST_FILE" ]; then
  BASE="${FILENAME%.*}"
  if [ "$BASE" = "$FILENAME" ]; then
    # Fichier sans extension
    DEST_FILE="$DEST_DIR/${FILENAME}_$(date +%s)"
  else
    DEST_FILE="$DEST_DIR/${BASE}_$(date +%s).${EXT}"
  fi
fi

mv "$FILE" "$DEST_FILE"

if [ "$VERBOSE_LOG" = "true" ]; then
  echo "[projects] $(date '+%H:%M:%S') ▸ $FILENAME → $TARGET_CATEGORY/"
fi
