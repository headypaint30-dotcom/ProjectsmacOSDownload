#!/usr/bin/env bash
# =============================================================================
# config.sh — Configuration du système Projects Auto-Classifier
# Modifie ce fichier pour personnaliser ton classement.
# =============================================================================

# ── Dossier destination ───────────────────────────────────────────────────
# Tous les fichiers classés atterrissent dans ~/Projects/
export PROJECTS_DIR="$HOME/Projects"
export INBOX_DIR="$PROJECTS_DIR/_inbox"

# ── Dossiers sources surveillés ───────────────────────────────────────────
# Le daemon surveille ces dossiers système (fichiers à la racine uniquement).
# Ajoute ou retire des chemins selon tes besoins.
export WATCH_DIRS=(
  "$HOME/Downloads"
  "$HOME/Desktop"
  "$HOME/Documents"
  "$HOME/Pictures"
  "$HOME/Movies"
  "$HOME/Music"
)

# ── Règles de classification ──────────────────────────────────────────────
# Format : "CATEGORIE|ext1,ext2,ext3"
# La catégorie = nom du sous-dossier dans ~/Projects/ (sensible à la casse).
# Extensions en minuscules, sans le point.
# Priorité : les règles du HAUT passent AVANT celles du bas.
# =============================================================================

export CLASSIFY_RULES=(

  # ── Code & Scripts ────────────────────────────────────────────────────────
  "Coding|py,js,ts,jsx,tsx,mjs,cjs,rb,go,rs,java,kt,swift,c,cpp,h,hpp,cs,php,lua,r,m,pl,sh,bash,zsh,fish,ps1,psm1"

  # ── Web ───────────────────────────────────────────────────────────────────
  "Web|html,htm,css,scss,sass,less,vue,svelte,astro,xml,xhtml,wasm"

  # ── Data & Bases ──────────────────────────────────────────────────────────
  "Data|csv,tsv,json,jsonl,yaml,yml,toml,sql,db,sqlite,sqlite3,parquet,arrow,ndjson"

  # ── Notes & Écriture ──────────────────────────────────────────────────────
  "Notes|md,markdown,txt,rst,org,tex,latex,rtf,pages"

  # ── Documents & Présentations ─────────────────────────────────────────────
  "Docs|pdf,docx,doc,odt,xlsx,xls,ods,pptx,ppt,odp,epub,numbers,keynote"

  # ── Design & Maquettes ────────────────────────────────────────────────────
  "Design|fig,sketch,xd,ai,psd,indd,afdesign,afpub,afphoto,studio"

  # ── Médias ────────────────────────────────────────────────────────────────
  "Media|png,jpg,jpeg,gif,webp,svg,ico,bmp,tiff,tif,mp4,mov,avi,mkv,webm,mp3,wav,flac,aac,ogg,m4a"

  # ── Config & Outils ───────────────────────────────────────────────────────
  "Coding|env,gitignore,dockerignore,editorconfig,eslintrc,prettierrc,babelrc,webpack,vite,tsconfig,jsconfig,makefile,dockerfile,vagrantfile,procfile"

  # ── Archives ──────────────────────────────────────────────────────────────
  "Docs|zip,tar,gz,bz2,xz,7z,rar"

)

# ── Fichiers à IGNORER (jamais classés) ───────────────────────────────────
# Extensions système ou temporaires
export IGNORE_EXTENSIONS="ds_store,localized,swp,swo,tmp,temp,bak,log,cache,crdownload,part,download"

# Préfixes de noms à ignorer (fichiers cachés et temporaires)
export IGNORE_PREFIXES=".,.~,~"

# ── Délai avant de classifier (secondes) ──────────────────────────────────
# Laisse le temps aux téléchargements de finir d'écrire avant de déplacer.
export CLASSIFY_DELAY=5

# ── Activer le log détaillé ───────────────────────────────────────────────
# true = log chaque fichier classé  |  false = silencieux
export VERBOSE_LOG=true
