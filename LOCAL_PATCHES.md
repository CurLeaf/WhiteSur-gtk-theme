# Local patches (yxw fork)

This fork tracks [vinceliuice/WhiteSur-gtk-theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) and keeps a few machine-specific fixes on top.

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
   - Re-apply after a dconf reset:
     ```bash
     gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'focus-minimize-or-appspread'
     ```

4. **Desktop performance (NVIDIA + GNOME 50 + 100 Hz)**
   - Keep the GNOME Shell top bar fully opaque (`#2a2a2a`) so mutter does not blend wallpaper through `rgba(black, 0.15)` on every 100 Hz frame
   - Dock `intellihide-mode='FOCUS_APPLICATION_WINDOWS'` (not `ALL_WINDOWS`)
   - Dock `dance-urgent-applications=false`
   - `powerprofilesctl` → `performance`
   - `vm.swappiness=10` via `/etc/sysctl.d/99-desktop-perf.conf`
   - GTK4 `GSK_RENDERER=ngl` in `~/.config/environment.d/50-nvidia-gtk.conf` (needs a new login)
   - Re-apply after a dconf reset:
     ```bash
     gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'FOCUS_APPLICATION_WINDOWS'
     gsettings set org.gnome.shell.extensions.dash-to-dock dance-urgent-applications false
     powerprofilesctl set performance
     ```

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
./sync-upstream.sh    # fetch + rebase + reinstall dark pack
git push              # publish local commits to your fork
```

Or manually:

```bash
git fetch upstream
git rebase upstream/master
./install.sh -c dark -o normal -l -f --round --shell -i apple
```

After reinstall, confirm:

```bash
gsettings get org.gnome.desktop.wm.preferences button-layout
# expect: ':minimize,maximize,close'
rg 'color-mix\(in srgb, black 6% [^,]' ~/.config/gtk-4.0/gtk-Light.css && echo BAD || echo OK
```

## Do not wrap dock apps here

Tray / frameless apps (Mineradio, WeChat, Clash Party, Discord…) need **per-app** desktop helpers — not theme changes. See dock notes in the WeChat / Mineradio chats; do not blanket-wrap normal window apps.
