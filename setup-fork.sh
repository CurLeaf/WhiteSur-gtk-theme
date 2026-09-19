#!/usr/bin/env bash
# One-time: create your GitHub fork and push local patches.
# Requires: gh auth login  (SSH already works as CurLeaf)
set -euo pipefail
cd "$(dirname "$0")"

if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "Run: gh auth login -h github.com -p ssh -w"
  exit 1
fi

if ! gh repo view CurLeaf/WhiteSur-gtk-theme >/dev/null 2>&1; then
  gh repo fork vinceliuice/WhiteSur-gtk-theme \
    --fork-name WhiteSur-gtk-theme \
    --clone=false \
    --remote=false
fi

git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:CurLeaf/WhiteSur-gtk-theme.git
git remote remove upstream 2>/dev/null || true
git remote add upstream https://github.com/vinceliuice/WhiteSur-gtk-theme.git

git push -u origin master
echo "Fork ready: https://github.com/CurLeaf/WhiteSur-gtk-theme"
echo "Later updates: ./sync-upstream.sh && git push"
