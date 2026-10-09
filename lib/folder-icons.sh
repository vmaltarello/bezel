#!/usr/bin/env bash
# bezel — Papirus-Dark with folders in bezel's accent colour, for this user only.
# Same idea as papirus-folders, without root: a tiny icon theme that inherits Papirus-Dark and
# only re-points the folder icons (folder, folder-documents, user-home...) to another colour variant.
#   lib/folder-icons.sh [colour]     (default: violet; any Papirus colour: grey, deeporange, ...)
set -euo pipefail
src=/usr/share/icons/Papirus
dst="${XDG_DATA_HOME:-$HOME/.local/share}/icons/Papirus-Dark-Bezel"
colour=${1:-violet}
[ -d "$src" ] || exit 0
colours="adwaita|black|blue|bluegrey|breeze|brown|carmine|cyan|darkcyan|deeporange|green|grey|indigo|magenta|nordic|orange|palebrown|paleorange|pink|red|teal|violet|white|yaru|yellow"

rm -rf "$dst"
mkdir -p "$dst"
dirs=()
for places in "$src"/*/places; do
    size=$(basename "$(dirname "$places")")
    [[ $size == *@2x || $size == symbolic ]] && continue
    mkdir -p "$dst/$size/places"
    for f in "$places"/*; do
        [ -L "$f" ] || continue
        target=$(readlink "$f")
        # folder.svg -> folder-blue.svg, user-home.svg -> user-blue-home.svg ...: swap the colour
        new=$(sed -E "s/-($colours)([-.])/-$colour\2/" <<<"$target")
        [ "$new" != "$target" ] && [ -e "$places/$new" ] && ln -s "$places/$new" "$dst/$size/places/$(basename "$f")"
    done
    dirs+=("$size/places")
done

{
    echo "[Icon Theme]"
    echo "Name=Papirus-Dark-Bezel"
    echo "Comment=Papirus-Dark with $colour folders (bezel)"
    echo "Inherits=Papirus-Dark,breeze-dark,hicolor"
    echo "Directories=$(IFS=,; echo "${dirs[*]}")"
    for d in "${dirs[@]}"; do
        n=${d%%x*}
        echo; echo "[$d]"; echo "Context=Places"; echo "Size=$n"; echo "Type=Fixed"
    done
} > "$dst/index.theme"
gtk-update-icon-cache -q "$dst" 2>/dev/null || true
