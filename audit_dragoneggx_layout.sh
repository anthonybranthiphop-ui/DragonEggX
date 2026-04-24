#!/usr/bin/env bash
set -euo pipefail

ROOT="/Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX"

echo "============================================================"
echo "DragonEggX Layout Audit"
echo "============================================================"
echo "Root: $ROOT"
echo

if [ ! -d "$ROOT" ]; then
  echo "ERROR: Root folder does not exist:"
  echo "  $ROOT"
  exit 1
fi

cd "$ROOT"

say_yes() { echo "[OK]   $1"; }
say_no()  { echo "[MISS] $1"; }
say_warn(){ echo "[WARN] $1"; }
say_info(){ echo "[INFO] $1"; }

echo "------------------------------------------------------------"
echo "1. Top-level contents"
echo "------------------------------------------------------------"
find "$ROOT" -maxdepth 1 -mindepth 1 -print | sed "s|$ROOT/|  - |" | sort
echo

echo "------------------------------------------------------------"
echo "2. Expected folders"
echo "------------------------------------------------------------"
for path in \
  "docs" \
  "docs/pull-rates" \
  "docs/timeline" \
  "catalog" \
  "catalog/master" \
  "catalog/exports" \
  "art" \
  "art/concepts" \
  "art/concepts/characters" \
  "art/prompts" \
  "art/references" \
  "media"
do
  if [ -d "$path" ]; then
    say_yes "Folder exists: $path"
  else
    say_no "Folder missing: $path"
  fi
done
echo

echo "------------------------------------------------------------"
echo "3. Files we expect to have been moved"
echo "------------------------------------------------------------"

# Master context file
if [ -f "docs/DRAGON_EGG_X_MASTER_CONTEXT.md" ]; then
  say_yes "Master context is in docs/DRAGON_EGG_X_MASTER_CONTEXT.md"
else
  say_no "Master context is not at docs/DRAGON_EGG_X_MASTER_CONTEXT.md"
fi

echo
say_info "Searching for any master context markdown files near repo root..."
find "$ROOT" -maxdepth 2 -type f \( -iname "*MASTER*CONTEXT*.md" -o -iname "*DRAGON*EGG*.md" \) | sed "s|$ROOT/|  - |" | sort || true
echo

# Prompts
if [ -d "art/prompts" ]; then
  say_yes "Prompts folder is in art/prompts"
else
  say_no "Prompts folder not found in art/prompts"
fi

# Pull Rates
if [ -d "docs/pull-rates" ]; then
  say_yes "Pull Rates folder is in docs/pull-rates"
else
  say_no "Pull Rates folder not found in docs/pull-rates"
fi

# Timeline
if [ -d "docs/timeline" ]; then
  say_yes "Timeline folder is in docs/timeline"
else
  say_no "Timeline folder not found in docs/timeline"
fi

# Nyxus JPG
if [ -f "art/concepts/characters/Nyxus, Cloud God of Eternal Storms.jpg" ]; then
  say_yes "Nyxus JPG is in art/concepts/characters/"
else
  say_no "Nyxus JPG is not in art/concepts/characters/"
fi
echo

echo "------------------------------------------------------------"
echo "4. Excel catalog safety check"
echo "------------------------------------------------------------"
say_info "Looking for Excel files in catalog/master ..."
find "catalog/master" -maxdepth 1 -type f \( -iname "*.xlsx" -o -iname "*.xls" \) | sed 's|^|  - |' | sort || true
echo

REAL_CATALOG_COUNT=$(find "catalog/master" -maxdepth 1 -type f \( -iname "*.xlsx" -o -iname "*.xls" \) ! -iname '~$*' | wc -l | tr -d ' ')
LOCK_FILE_COUNT=$(find "catalog/master" -maxdepth 1 -type f \( -iname "*.xlsx" -o -iname "*.xls" \) -iname '~$*' | wc -l | tr -d ' ')

if [ "$REAL_CATALOG_COUNT" -ge 1 ]; then
  say_yes "At least one real Excel catalog file exists in catalog/master"
else
  say_no "No real Excel catalog file found in catalog/master"
fi

if [ "$LOCK_FILE_COUNT" -ge 1 ]; then
  say_warn "Excel lock file(s) found in catalog/master (do not treat these as real catalogs)"
  find "catalog/master" -maxdepth 1 -type f -iname '~$*' | sed 's|^|  - |' | sort
else
  say_yes "No Excel lock files found in catalog/master"
fi
echo

echo "------------------------------------------------------------"
echo "5. Stray Excel files still sitting in repo root"
echo "------------------------------------------------------------"
ROOT_XLS_COUNT=$(find "$ROOT" -maxdepth 1 -type f \( -iname "*.xlsx" -o -iname "*.xls" \) | wc -l | tr -d ' ')
if [ "$ROOT_XLS_COUNT" -ge 1 ]; then
  say_warn "Excel files still exist at repo root:"
  find "$ROOT" -maxdepth 1 -type f \( -iname "*.xlsx" -o -iname "*.xls" \) | sed "s|$ROOT/|  - |" | sort
else
  say_yes "No Excel files remain at repo root"
fi
echo

echo "------------------------------------------------------------"
echo "6. Things that should probably stay put for now"
echo "------------------------------------------------------------"
for path in \
  "project.yml" \
  "DragonEggX.xcodeproj" \
  "DragonEggX" \
  "Eternal_Summon_Assets"
do
  if [ -e "$path" ]; then
    say_yes "Present: $path"
  else
    say_warn "Missing or moved: $path"
  fi
done
echo

echo "------------------------------------------------------------"
echo "7. Check whether LinguaBlitz is still inside this repo"
echo "------------------------------------------------------------"
if [ -e "LinguaBlitz" ]; then
  say_warn "LinguaBlitz is still inside DragonEggX repo"
  echo "  Suggested move:"
  echo '  mv "/Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX/LinguaBlitz" "/Volumes/SharedDrive_APFS/Xcode/"'
else
  say_yes "LinguaBlitz is not inside this repo"
fi
echo

echo "------------------------------------------------------------"
echo "8. Likely cleanup actions still needed"
echo "------------------------------------------------------------"
NEEDS_ACTION=0

if [ ! -f "docs/DRAGON_EGG_X_MASTER_CONTEXT.md" ]; then
  NEEDS_ACTION=1
  echo "- Move/rename the master context file into docs/DRAGON_EGG_X_MASTER_CONTEXT.md"
fi

if find "catalog/master" -maxdepth 1 -type f -iname '~$*' | grep -q .; then
  NEEDS_ACTION=1
  echo "- Remove Excel lock file(s) from catalog/master (safe, but do NOT remove the real catalog)"
fi

if [ -e "LinguaBlitz" ]; then
  NEEDS_ACTION=1
  echo "- Move LinguaBlitz out of the DragonEggX repo if it is a separate project"
fi

if find "$ROOT" -maxdepth 1 -type f \( -iname "*.xlsx" -o -iname "*.xls" \) | grep -q .; then
  NEEDS_ACTION=1
  echo "- Move any remaining root-level Excel files into catalog/master"
fi

if [ "$NEEDS_ACTION" -eq 0 ]; then
  say_yes "Nothing obvious needs cleanup right now"
fi
echo

echo "------------------------------------------------------------"
echo "9. Recommended next commands (manual, not run automatically)"
echo "------------------------------------------------------------"
echo 'find "/Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX" -maxdepth 2 | sort'
echo 'xcodegen generate'
echo 'xcodebuild -scheme DragonEggX -destination "platform=macOS,arch=arm64" -configuration Debug CODE_SIGNING_ALLOWED=NO build'
echo

echo "Audit complete."
echo "No files were moved or deleted."
