# Local patches (yxw fork)

This fork tracks [vinceliuice/WhiteSur-gtk-theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) and keeps a few machine-specific fixes on top.

**New Ubuntu box:** `./apply-local.sh` (GDM step needs sudo). That is the one command. Do not hand-copy gsettings from this file unless you are debugging.

## Patches

1. **GTK `color-mix()` parser crash / empty-trash dialog flicker** ([upstream #1392](https://github.com/vinceliuice/WhiteSur-gtk-theme/issues/1392))
   - Missing comma: `color-mix(in srgb, black 6% $color)` → `black 6%, $color`
   - Avoid nesting CSS `mix()` inside `color-mix()` for selection-mode borders
   - Keep `AdwAlertDialog` / `dialog-window.alert` sheets opaque (normal opacity still flickers on GNOME 50 + Wayland)
   - Don't `@extend %view` onto dialog sheets (`transition: all` fights the dialog animation)
   - Match GNOME 50 alert-dialog layout so the empty-trash confirm stops resizing itself

2. **Window buttons on the right** (Ubuntu / GNOME layout)
   - `ButtonLayout=:minimize,maximize,close` instead of macOS left traffic lights

3. **Ubuntu Dock multi-window click = App Spread** (Ubuntu native window picker)
   - `click-action='focus-minimize-or-appspread'`
   - One window: click focused icon to minimize (kept from previous setup)
   - Several windows: click the focused icon to open Ubuntu's full-screen task windows

4. **Desktop performance (NVIDIA + GNOME 50 + 100 Hz)**
   - Keep the GNOME Shell top bar fully opaque (`#2a2a2a`)
   - Keep Shell menus / popovers fully opaque (`$popover_opacity: 1`) — same compositor reason as the panel
   - Install the **solid** GTK pack (`WhiteSur-Dark-solid`) on this machine
   - Dock `intellihide-mode='FOCUS_APPLICATION_WINDOWS'` (not `ALL_WINDOWS`)
   - Dock `dance-urgent-applications=false`
   - `powerprofilesctl` → `performance`
   - `vm.swappiness=10` via `/etc/sysctl.d/99-desktop-perf.conf`
   - GTK4 `GSK_RENDERER=ngl` in `~/.config/environment.d/50-nvidia-gtk.conf` (needs a new login)
   - Qt apps: `QT_QPA_PLATFORMTHEME=gtk3` in `~/.config/environment.d/51-whitesur-apps.conf`
   - **Do not install blur-my-shell.** Upstream README recommends it; this box goes the other way.

5. **GNOME 50 Shell selectors**
   - `widgets-50-0` covers web-login, parental-controls shield, auth-method menus, conflicting-session, screenshot countdown OSD, Overview search-statusbox, Wi-Fi QR, workspace-switcher dots, calendar month header, notification clear button, and lock-screen notification chrome that 48-era files never named.
   - Missing selectors do not crash Shell; they show a patch of Adwaita.

6. **Libadwaita 1.7–1.9 widgets**
   - `AdwSpinner` (`image.spinner`), `AdwToggleGroup` / `toggle-group`, `wrap-box`, and `bottom-sheet` (including the drag handle). Same class of fork work as the `color-mix` / opaque-dialog patches.

7. **AppIndicator tray on the opaque panel**
   - Style `.appindicator-icon` / `.tray-icon` / Ubuntu's `ubuntu-appindicators@ubuntu.com` Gjs names.
   - Keep **regular** (color) icons — forcing symbolic is how WeChat vanished on `#2a2a2a`.
   - Still do **not** wrap tray apps in the theme. Per-app desktop helpers stay outside SCSS.

8. **GTK4 day / night**
   - `~/.config/gtk-4.0/gtk.css` follows `prefers-color-scheme`.
   - `gtk-dark.css` always points at the Dark pack.
   - `gnome-theme-switcher` is still installed if you want to pick a pack by hand.

## One-time GitHub fork (CurLeaf)

SSH already authenticates as `CurLeaf`. API login is needed once to create the fork:

```bash
gh auth login -h github.com -p ssh -w
cd ~/Projects/WhiteSur-gtk-theme
./setup-fork.sh
```

Repo: https://github.com/CurLeaf/WhiteSur-gtk-theme

## Pull upstream

```bash
cd ~/Projects/WhiteSur-gtk-theme
./sync-upstream.sh    # fetch + rebase + apply-local (no GDM)
git push              # publish local commits to your fork
```

After reinstall, confirm:

```bash
gsettings get org.gnome.desktop.wm.preferences button-layout
# expect: ':minimize,maximize,close'
gsettings get org.gnome.desktop.interface gtk-theme
# expect: 'WhiteSur-Dark-solid'
rg 'color-mix\(in srgb, black 6% [^,]' ~/.config/gtk-4.0/gtk-Light.css && echo BAD || echo OK
```

## Not SCSS (do not dump these into WhiteSur)

| Surface | What to do |
|---|---|
| **Qt** (Clash, some tools) | `QT_QPA_PLATFORMTHEME=gtk3` (apply-local writes this). Optional: `qt6ct` / Kvantum if gtk3 platform is not enough. |
| **Chrome** | Settings → Appearance → Use GTK, and “Use system title bar and borders”. Ozone still draws the tab strip. |
| **Cursor** | Electron title bar stays Electron. Optional `window.autoDetectColorScheme`. |
| **Fildem / Unite** | `_panel.scss` already has commented selectors. GNOME 50 + Wayland fights them for layout; skip. |
| **GDM** | `sudo ./tweaks.sh -g -nb -b "$WALLPAPER"` (apply-local does this). No GDM blur on NVIDIA. |
| **Firefox / Zen** | `./tweaks.sh -f` and `./tweaks.sh -z` once a profile exists. |
| **Flatpak** | `./tweaks.sh -F -o solid -c dark` plus `filesystem=xdg-config/gtk-{3,4}.0`. |

Window buttons stay on the right. Dock stays Ubuntu App Spread. Do not move this fork toward macOS traffic lights or Dash-to-Dock window previews.

## Do not wrap dock apps here

Tray / frameless apps (Mineradio, WeChat, Clash Party, Discord…) need **per-app** desktop helpers — not theme changes.
