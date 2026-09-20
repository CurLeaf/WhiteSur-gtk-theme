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
