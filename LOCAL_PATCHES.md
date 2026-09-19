# Local patches (yxw fork)

This fork tracks [vinceliuice/WhiteSur-gtk-theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) and keeps a few machine-specific fixes on top.

## Patches

1. **GTK `color-mix()` parser crash / empty-trash dialog flicker** ([upstream #1392](https://github.com/vinceliuice/WhiteSur-gtk-theme/issues/1392))
   - Missing comma: `color-mix(in srgb, black 6% $color)` → `black 6%, $color`
   - Avoid nesting CSS `mix()` inside `color-mix()` for selection-mode borders

2. **Window buttons on the right** (Ubuntu / GNOME layout)
   - `ButtonLayout=:minimize,maximize,close` instead of macOS left traffic lights

## Pull upstream

```bash
cd ~/Projects/WhiteSur-gtk-theme
git fetch upstream
git rebase upstream/master   # or: git merge upstream/master
# resolve conflicts if any, then:
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
