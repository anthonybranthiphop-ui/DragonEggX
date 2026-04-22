#!/usr/bin/env bash
# After `xcodegen generate`, build macOS and verify bundled Eternal Summon / summon MP4s.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DD="${DRAGON_EGGX_VERIFY_DERIVED_DATA:-$ROOT/.verify_derived_data}"
OUT="$DD/Build/Products/Debug/DragonEggX.app/Contents/Resources"

echo "==> xcodebuild (macOS)"
xcodebuild -scheme DragonEggX \
  -destination "platform=macOS" \
  -configuration Debug \
  -derivedDataPath "$DD" \
  CODE_SIGNING_ALLOWED=NO \
  build -quiet

echo "==> Checking Resources at: $OUT"
if [[ ! -d "$OUT" ]]; then
  echo "error: expected Resources folder not found" >&2
  exit 1
fi

need=(
  "Hero Summon (Common)1.mp4"
  "Extreme Summon.mp4"
  "Sparking Summon.mp4"
  "LR (Legends Rising) Summon.mp4"
  "Ultra Legends Rising Summon (0.01% - THE RARE ONE).mp4"
  "01_Aetherion, Super Saiyan 5 Eternal Sovereign (Legends Limited).jpg"
)
ok=0
for f in "${need[@]}"; do
  if [[ -f "$OUT/$f" ]]; then
    echo "  OK: $f"
    ((ok++)) || true
  else
    echo "  MISSING: $f" >&2
  fi
done

if [[ "$ok" -ne "${#need[@]}" ]]; then
  echo "error: not all required bundle files present ($ok / ${#need[@]})" >&2
  exit 1
fi

echo "==> All ${#need[@]} required files present. Manual next: run app and confirm summon VFX in UI."
