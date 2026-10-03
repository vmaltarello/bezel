#!/usr/bin/env bash
# Wallpaper with awww (circle transition growing from the cursor)
#   (picking with thumbnails is in the launcher: SUPER+W)
#   wallpaper.sh next        -> next image in the folder
#   wallpaper.sh <file>      -> set that file
#   wallpaper.sh init        -> at login: if no wallpaper was ever set, use the first one in the folder
# The current wallpaper is the link ~/.local/state/wallpaper.
# Blurred copy for the lock screen (Quickshell): ~/.cache/wallpaper/lock.jpg
# and for the login screen: /var/lib/quickshell-greeter/background.jpg (if installed, see quickshell/greeter)
#   wallpaper.sh blur        -> only regenerate the blurred copy
dir=~/Pictures/Wallpapers
link=~/.local/state/wallpaper
blurred=~/.cache/wallpaper/lock.jpg

# blur done once here: the shell's software renderer can't blur
make_blur() {
    mkdir -p "$(dirname "$blurred")"
    magick "$1" -resize 720x -blur 0x10 -resize 2160x -quality 92 "$blurred.tmp.jpg" && mv "$blurred.tmp.jpg" "$blurred"
    [ -w /var/lib/quickshell-greeter ] && cp "$blurred" /var/lib/quickshell-greeter/background.jpg
    return 0
}

set_wall() {
    # cursor position in % (awww counts y from the bottom)
    pos=$(hyprctl -j cursorpos | jq -r --argjson m "$(hyprctl -j monitors | jq '.[] | select(.focused)')" \
        '"\((.x - $m.x) / ($m.width / $m.scale)),\(1 - (.y - $m.y) / ($m.height / $m.scale))"')
    awww img "$1" -t grow --transition-pos "${pos:-center}" \
        --transition-duration 1.2 --transition-fps 60 --transition-bezier .65,0,.35,1
    mkdir -p "$(dirname "$link")"
    ln -sfn "$1" "$link"
    make_blur "$1" &
}

walls=$(find "$dir" -maxdepth 1 -type f -iregex '.*\.\(jpe?g\|png\|webp\|gif\)' | sort)

case "$1" in
    next)
        cur=$(readlink "$link")
        nxt=$(grep -A1 -xF "$cur" <<<"$walls" | sed -n 2p)
        set_wall "${nxt:-$(head -1 <<<"$walls")}"
        ;;
    blur) make_blur "$(readlink -f "$link")" ;;
    init)
        # awww-daemon restores the last wallpaper by itself; only act on a first login
        [ -e "$link" ] && exit 0
        first=$(head -1 <<<"$walls"); [ -n "$first" ] || exit 0
        for _ in $(seq 25); do awww query >/dev/null 2>&1 && break; sleep 0.2; done
        set_wall "$first"
        ;;
    *)  [ -f "$1" ] && set_wall "$1" ;;
esac
