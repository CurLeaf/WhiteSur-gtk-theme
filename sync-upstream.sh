#!/usr/bin/env bash
# Pull upstream WhiteSur and reinstall the local dark pack.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

git fetch upstream
git rebase upstream/master

# Reinstall theme + desktop convention. GDM stays as-is unless you pass it
# yourself — rebasing should not rewrite /usr/share without asking.
./apply-local.sh --skip-gdm

if rg -q 'color-mix\(in srgb, black 6% [^,]' "$HOME/.config/gtk-4.0/gtk-Light.css" 2>/dev/null; then
  echo "ERROR: broken color-mix() still present in gtk-Light.css" >&2
  exit 1
fi

echo "OK: theme reinstalled from upstream + local patches."
