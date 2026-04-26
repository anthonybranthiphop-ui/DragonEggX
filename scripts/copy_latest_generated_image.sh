#!/bin/zsh
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 /absolute/path/to/output.png" >&2
  exit 1
fi

dest="$1"
latest="$(find -L "$HOME/.codex/generated_images" -type f -name '*.png' | xargs ls -t | head -n 1)"

if [[ -z "$latest" ]]; then
  echo "no generated png found" >&2
  exit 1
fi

mkdir -p "$(dirname "$dest")"
cp "$latest" "$dest"
printf '%s\n' "$latest"
