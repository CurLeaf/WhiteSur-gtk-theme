#!/usr/bin/env bash
# Pull upstream WhiteSur and reinstall the local dark pack.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

git fetch upstream
git rebase upstream/master

./install.sh -c dark -o normal -l -f --round --shell -i apple

# Keep Ubuntu-side window buttons on the right (theme index already patched).
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' || true

if rg -q 'color-mix\(in srgb, black 6% [^,]' "$HOME/.config/gtk-4.0/gtk-Light.css" 2>/dev/null; then
  echo "ERROR: broken color-mix() still present in gtk-Light.css" >&2
  exit 1
fi

echo "OK: theme reinstalled from upstream + local patches."
