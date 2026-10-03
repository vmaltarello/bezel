#!/usr/bin/env bash
# Installs the login screen into a folder (default: /etc/quickshell-greeter, needs sudo).
#   greeter/install.sh                 -> install into /etc/quickshell-greeter
#   greeter/install.sh <folder>        -> copy only (preview: quickshell -p <folder>)
# greetd config: greeter/greetd.toml -> /etc/greetd/config.toml.
# Re-run after changing the theme. The background lives in /var/lib/quickshell-greeter (owned by you,
# world-readable) and wallpaper.sh updates it on every wallpaper change.
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
dst=${1:-/etc/quickshell-greeter}
bg=${GREETER_BG:-$HOME/.cache/wallpaper/lock.jpg}

run() { if [ -w "$(dirname "$dst")" ]; then "$@"; else sudo "$@"; fi; }

tmp=$(mktemp -d)
mkdir -p "$tmp"/{config,components,services,modules/lock}
cp "$src"/greeter/{shell.qml,hyprland.lua} "$tmp"/
cp "$src"/config/*.qml "$tmp"/config/
cp "$src"/components/*.qml "$tmp"/components/
cp "$src"/services/{Time,Battery,Media}.qml "$tmp"/services/
cp "$src"/modules/lock/LockView.qml "$tmp"/modules/lock/
chmod -R a+rX "$tmp"

run rm -rf "$dst"
run cp -r "$tmp" "$dst"
run chown -R root:root "$dst" 2>/dev/null || true
rm -rf "$tmp"

# background folder (real install only)
if [ "$dst" = /etc/quickshell-greeter ]; then
    sudo install -d -m 755 -o "$USER" -g "$(id -gn)" /var/lib/quickshell-greeter
    # on a fresh install there is no wallpaper yet: wallpaper.sh copies it here when one is set
    if [ -f "$bg" ]; then install -m 644 "$bg" /var/lib/quickshell-greeter/background.jpg
    else echo "no wallpaper yet: the login screen gets its background when you set one"; fi
fi
echo "ok: $dst"
