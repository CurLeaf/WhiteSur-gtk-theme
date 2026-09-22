#!/usr/bin/env bash
# Apply this fork's Ubuntu + GNOME 50 + NVIDIA convention in one shot.
#
# Theme CSS lives in this repo. This script is the machine side: gsettings,
# GSK, GDM, browsers, Flatpak, and the GTK4 light/dark split.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -m "${0}")")" && pwd)"
cd "${REPO_DIR}"

DO_THEME=true
DO_GDM=true
DO_BROWSERS=true
DO_FLATPAK=true
DO_DESKTOP=true

usage() {
  cat <<'EOF'
Usage: ./apply-local.sh [options]

  --skip-theme      Do not run install.sh
  --skip-gdm        Do not theme GDM (avoids sudo)
  --skip-browsers   Do not install Firefox / Zen chrome
  --skip-flatpak    Do not connect Flatpak
  --skip-desktop    Do not write gsettings / environment.d
  -h, --help

Default pack: WhiteSur-Dark-solid, apple Activities, rounded max,
libadwaita into ~/.config/gtk-4.0, window buttons on the right,
Ubuntu Dock App Spread, GSK ngl, opaque panel + menus.
EOF
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    --skip-theme) DO_THEME=false; shift ;;
    --skip-gdm) DO_GDM=false; shift ;;
    --skip-browsers) DO_BROWSERS=false; shift ;;
    --skip-flatpak) DO_FLATPAK=false; shift ;;
    --skip-desktop) DO_DESKTOP=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: ${1}" >&2; usage; exit 1 ;;
  esac
done

THEME_GTK="WhiteSur-Dark-solid"
ICON_THEME="WhiteSur-dark"
CURSOR_THEME="WhiteSur-cursors"

wallpaper_path() {
  local raw
  raw="$(gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null || true)"
  [[ -z "${raw}" || "${raw}" == "''" ]] && \
    raw="$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null || true)"
  python3 - "${raw}" <<'PY'
import sys, urllib.parse
raw = sys.argv[1].strip().strip("'").strip('"')
if raw.startswith("file://"):
    raw = urllib.parse.unquote(raw[7:])
print(raw)
PY
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Agent / GUI sessions often have no TTY. Prefer cached sudo, then a zenity prompt.
sudo_run() {
  if sudo -n true 2>/dev/null; then
    sudo "$@"
    return
  fi
  if [[ -t 0 && -t 1 ]]; then
    sudo "$@"
    return
  fi
  if has_cmd zenity; then
    local askpass rc=0
    askpass="$(mktemp --tmpdir whitesur-askpass.XXXXXX)"
    cat > "${askpass}" <<'EOF'
#!/bin/bash
exec zenity --password --title="WhiteSur GDM" --text="安装登录/锁屏主题需要管理员密码"
EOF
    chmod 700 "${askpass}"
    SUDO_ASKPASS="${askpass}" sudo -A "$@" || rc=$?
    rm -f "${askpass}"
    return "${rc}"
  fi
  echo "sudo needs a terminal or zenity." >&2
  return 1
}

if [[ "${DO_THEME}" == true ]]; then
  echo "==> Installing ${THEME_GTK} (libadwaita + GNOME Shell)"
  # Adaptive accent so GNOME 47+ ($shell_version: new) dialogs use st-* mixins.
  ./install.sh -c dark -o solid -l --round --shell -i apple
fi

if [[ "${DO_DESKTOP}" == true ]]; then
  echo "==> Desktop convention (gsettings, GSK, Qt)"

  gsettings set org.gnome.desktop.interface gtk-theme "${THEME_GTK}"
  gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME}" || true
  gsettings set org.gnome.desktop.interface cursor-theme "${CURSOR_THEME}" || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

  if gsettings writable org.gnome.shell.extensions.user-theme name >/dev/null 2>&1; then
    gsettings set org.gnome.shell.extensions.user-theme name "${THEME_GTK}"
  fi

  if gsettings writable org.gnome.shell.extensions.dash-to-dock click-action >/dev/null 2>&1; then
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'focus-minimize-or-appspread'
    gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
    gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'FOCUS_APPLICATION_WINDOWS'
    gsettings set org.gnome.shell.extensions.dash-to-dock dance-urgent-applications false
  fi

  mkdir -p "${HOME}/.config/gtk-3.0"
  cat > "${HOME}/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=${THEME_GTK}
gtk-icon-theme-name=${ICON_THEME}
gtk-cursor-theme-name=${CURSOR_THEME}
gtk-cursor-theme-size=24
gtk-font-name=Inter 11
gtk-application-prefer-dark-theme=1
gtk-overlay-scrolling=1
gtk-enable-primary-paste=0
gtk-xft-antialias=1
gtk-xft-hinting=0
gtk-xft-hintstyle=hintnone
gtk-xft-rgba=rgb
gtk-decoration-layout=:minimize,maximize,close
EOF

  mkdir -p "${HOME}/.config/environment.d"
  cat > "${HOME}/.config/environment.d/50-nvidia-gtk.conf" <<'EOF'
# GTK4 on NVIDIA proprietary: ngl is cheaper/stabler than the Vulkan GSK path.
GSK_RENDERER=ngl
EOF
  cat > "${HOME}/.config/environment.d/51-whitesur-apps.conf" <<'EOF'
# Qt (Clash, etc.) should follow the GTK theme. Do not put Qt/Kvantum into WhiteSur SCSS.
QT_QPA_PLATFORMTHEME=gtk3
EOF

  if has_cmd powerprofilesctl; then
    powerprofilesctl set performance || true
  fi
fi

if [[ "${DO_BROWSERS}" == true ]]; then
  if has_cmd firefox || has_cmd firefox-bin || has_cmd firefox-developer-edition || \
     [[ -d "${HOME}/.mozilla/firefox" ]]; then
    if pidof firefox >/dev/null 2>&1 || pidof firefox-bin >/dev/null 2>&1; then
      echo "==> Firefox is running; skip Safari chrome. Close it and re-run: ./tweaks.sh -f"
    else
      echo "==> Firefox Safari chrome"
      ./tweaks.sh -f || true
    fi
  else
    echo "==> No Firefox profile; skip. After installing Firefox, run: ./tweaks.sh -f"
  fi

  if has_cmd zen || has_cmd zen-browser || \
     [[ -d "${HOME}/.zen" ]] || \
     [[ -d "${HOME}/.var/app/app.zen_browser.zen/.zen" ]] || \
     [[ -d "${HOME}/.var/app/io.github.zen_browser.zen/.zen" ]]; then
    if pidof zen >/dev/null 2>&1 || pidof zen-browser >/dev/null 2>&1 || pidof zen-bin >/dev/null 2>&1; then
      echo "==> Zen is running; skip Safari chrome. Close it and re-run: ./tweaks.sh -z"
    else
      echo "==> Zen Safari chrome"
      ./tweaks.sh -z || true
    fi
  else
    echo "==> No Zen profile; skip. After installing Zen, run: ./tweaks.sh -z"
  fi
fi

if [[ "${DO_FLATPAK}" == true ]]; then
  if has_cmd flatpak; then
    echo "==> Flatpak GTK theme + xdg-config/gtk-{3,4}.0"
    ./tweaks.sh -F -o solid -c dark || true
  else
    echo "==> Flatpak not installed; skip. After installing it, run: ./tweaks.sh -F -o solid -c dark"
  fi
fi

if [[ "${DO_GDM}" == true ]]; then
  WALL="$(wallpaper_path)"
  echo "==> GDM (no blur on NVIDIA). sudo required."
  gdm_cmd=(./tweaks.sh -g -nb)
  if [[ -n "${WALL}" && -r "${WALL}" ]]; then
    gdm_cmd+=(-b "${WALL}")
  else
    echo "    Wallpaper not readable (${WALL:-empty}); GDM uses the default WhiteSur background."
  fi
  sudo_run "${gdm_cmd[@]}"
fi

echo
echo "Done. This session still needs:"
echo "  - A new login for GSK_RENDERER=ngl and QT_QPA_PLATFORMTHEME=gtk3"
echo "  - GNOME Shell reload (Alt+F2, r) or a logout for the new shell CSS"
echo
echo "Not in WhiteSur SCSS (handle per app):"
echo "  Chrome: Appearance → Use GTK / Use system title bar and borders"
echo "  Cursor: leave the Electron title bar; optional window.autoDetectColorScheme"
echo "  Skip blur-my-shell, Fildem, and Unite on this NVIDIA + GNOME 50 box"
echo
echo "See LOCAL_PATCHES.md"
