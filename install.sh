#!/usr/bin/env bash
# bezel installer — Hyprland + Quickshell desktop theme for Arch Linux.
#
#   ./install.sh                 interactive install (or update, when already installed)
#   ./install.sh --yes           take the default answer everywhere
#   ./install.sh --all           every optional component (still asks for the greeter)
#   ./install.sh --only a,b      only these optional components (core is always installed)
#   ./install.sh --greeter       also install the login screen (greetd, needs sudo)
#   ./install.sh --no-packages   don't install packages, only the config files
#   ./install.sh --link          symlink files to this repo instead of copying (for development)
#
# Everything it replaces is saved first: ./uninstall.sh puts it back.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

ASSUME_YES= ALL= ONLY= GREETER= NO_PKGS= LINK=
while [ $# -gt 0 ]; do
    case $1 in
        -y|--yes) ASSUME_YES=1 ;;
        --all) ALL=1 ;;
        --only) ONLY=$2; shift ;;
        --greeter) GREETER=1 ;;
        --no-packages) NO_PKGS=1 ;;
        --link) LINK=1 ;;
        -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
done

# ---------- checks ----------
[ "$(id -u)" -ne 0 ] || die "run as your normal user, not root (sudo is asked when needed)"
command -v pacman >/dev/null || die "bezel needs Arch Linux (pacman not found)"

UPDATE=
[ -f "$MANIFEST" ] && UPDATE=1
printf '%sbezel%s — %s\n' "$c_amber" "$c_off" "$([ -n "$UPDATE" ] && echo "updating the installed theme" || echo "installing")"

# ---------- components ----------
step "Components"
CHOSEN=(core)
info "core: $(component_desc core)"
for c in "${COMPONENTS[@]:1}"; do
    if [ -n "$ONLY" ]; then
        [[ ",$ONLY," == *",$c,"* ]] && CHOSEN+=("$c")
    elif [ -n "$ALL" ]; then
        CHOSEN+=("$c")
    elif [ -n "$UPDATE" ] && grep -qx "component $c" "$MANIFEST"; then
        CHOSEN+=("$c"); note "$c: installed, updating"
    elif ask "$c: $(component_desc "$c")?" "$(component_default "$c")"; then
        CHOSEN+=("$c")
    fi
done
if [ -z "$GREETER" ] && [ ! -f "$STATE/greeter" ]; then
    ask "Login screen: replace your display manager with the bezel greeter (greetd)?" n && GREETER=1
fi
[ -f "$STATE/greeter" ] && GREETER=1

# ---------- packages ----------
if [ -z "$NO_PKGS" ]; then
    step "Packages"
    pkgs=$(grep -v '^\s*#' "$REPO/packages/core.txt" | xargs)
    for c in "${CHOSEN[@]}" ${GREETER:+greeter}; do
        pkgs+=" $(awk -v c="$c" '$1 == c { print $2 }' "$REPO/packages/extras.txt" | xargs)"
    done
    missing=$(pacman -T $pkgs || true)
    if [ -z "$missing" ]; then
        info "all installed"
    else
        info "missing: $(echo $missing)"
        if ask "Install them with pacman?" y; then
            sudo pacman -S --needed ${ASSUME_YES:+--noconfirm} $missing
            mkdir -p "$STATE"
            for p in $missing; do grep -qx "$p" "$STATE/packages" 2>/dev/null || echo "$p" >> "$STATE/packages"; done
        else
            warn "skipped: the theme won't work until they are installed"
        fi
    fi

    # Hyprland reads hyprland.lua only from 0.56 on
    hv=$(pacman -Q hyprland 2>/dev/null | awk '{print $2}')
    if [ -n "$hv" ] && [ "$(vercmp "$hv" 0.56)" -lt 0 ]; then
        warn "Hyprland $hv is too old: bezel needs 0.56 or newer (Lua config)"
    fi

    # services behind the bar menus
    for s in bluetooth power-profiles-daemon NetworkManager; do
        systemctl list-unit-files "$s.service" >/dev/null 2>&1 || continue
        systemctl is-enabled -q "$s" 2>/dev/null && continue
        q="Enable $s?"
        [ "$s" = NetworkManager ] && q="Enable NetworkManager? (say no if you manage the network with something else)"
        if ask "$q" "$([ "$s" = NetworkManager ] && echo n || echo y)"; then
            sudo systemctl enable --now "$s" && echo "$s" >> "$STATE/services"
        fi
    done
fi

# ---------- files ----------
step "Config files"
mkdir -p "$STATE" "$BACKUP" "$CONFIG_DST"
touch "$MANIFEST"
for c in "${CHOSEN[@]}"; do manifest_add "component $c"; done

# keyboard layout of the system, for the first hyprland.lua
kb_layout=$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout/ {print $2}' | cut -d, -f1)
kb_variant=$(localectl status 2>/dev/null | awk -F': ' '/X11 Variant/ {print $2}' | cut -d, -f1)

backup() {  # move ~/.config/<rel> into the backup, once
    local rel=$1 dst="$CONFIG_DST/$1"
    [ -e "$dst" ] || [ -L "$dst" ] || return 0
    if [ -e "$BACKUP/$rel" ] || [ -L "$BACKUP/$rel" ]; then rm -rf "$dst"; return 0; fi
    mkdir -p "$(dirname "$BACKUP/$rel")"
    mv "$dst" "$BACKUP/$rel"
    note "saved your $rel"
}

PLACEHOLDERS='@(HOME|SCALE|KB_LAYOUT|KB_VARIANT)@'   # only these; other @WORDS@ (e.g. wpctl's @DEFAULT_AUDIO_SINK@) are left alone

render() {  # copy with placeholders filled in, same permissions as the source
    sed -e "s|@HOME@|$HOME|g" -e "s|@SCALE@|auto|g" \
        -e "s|@KB_LAYOUT@|${kb_layout:-us}|g" -e "s|@KB_VARIANT@|${kb_variant:-}|g" "$1" > "$2"
    chmod --reference="$1" "$2"
}

install_file() {
    local rel=$1 src="$CONFIG_SRC/$1" dst="$CONFIG_DST/$1"
    if [[ " $USER_FILES " == *" $rel "* ]] && manifest_has "file $rel" && [ -e "$dst" ]; then
        note "kept your $rel"; return
    fi
    manifest_has "file $rel" || backup "$rel"
    mkdir -p "$(dirname "$dst")"
    rm -f "$dst"
    if grep -qE "$PLACEHOLDERS" "$src" 2>/dev/null; then
        render "$src" "$dst"                  # templates are always real files
    elif [ -n "$LINK" ]; then
        ln -s "$src" "$dst"
    else
        cp "$src" "$dst"
    fi
    manifest_add "file $rel"
}

for c in "${CHOSEN[@]}"; do
    for rel in $(component_paths "$c"); do
        rel=${rel%/}
        # folders owned by the theme: the old one goes to the backup whole, ours is rebuilt on update
        for d in $OWNED_DIRS; do
            [[ $d == "$rel" || $d == "$rel"/* ]] || continue
            if manifest_has "dir $d"; then rm -rf "${CONFIG_DST:?}/$d"
            else backup "$d"; manifest_add "dir $d"; fi
        done
        if [ -d "$CONFIG_SRC/$rel" ]; then
            while IFS= read -r f; do install_file "${f#"$CONFIG_SRC"/}"; done \
                < <(find "$CONFIG_SRC/$rel" -type f ! -name '*.bak*')
        else
            install_file "$rel"
        fi
    done
    info "$c"
done

# nvim writes a plugin lock file next to our init.lua: remember if the user already had one (uninstall keeps it)
if [ -z "$UPDATE" ] && [[ " ${CHOSEN[*]} " == *" nvim "* ]] && [ -e "$CONFIG_DST/nvim/nvim-pack-lock.json" ]; then
    manifest_has "keep nvim/nvim-pack-lock.json" || manifest_add "keep nvim/nvim-pack-lock.json"
fi

# an old hyprland.conf next to hyprland.lua would be confusing: keep it in the backup
if [ -e "$CONFIG_DST/hypr/hyprland.conf" ]; then
    backup "hypr/hyprland.conf"; manifest_add "moved hypr/hyprland.conf"
fi

# yazi plugins listed in package.toml
if [[ " ${CHOSEN[*]} " == *" yazi "* ]] && command -v ya >/dev/null; then
    [ -d "$CONFIG_DST/yazi/plugins" ] || manifest_add "dir yazi/plugins"
    ya pkg install >/dev/null 2>&1 && info "yazi plugins" || warn "yazi plugins: run 'ya pkg install' later (needs network)"
fi

# ---------- GTK settings (GNOME/libadwaita apps read them from dconf) ----------
if command -v gsettings >/dev/null; then
    step "GTK settings"
    keys="gtk-theme icon-theme cursor-theme cursor-size font-name monospace-font-name color-scheme"
    if [ ! -f "$STATE/gsettings" ]; then
        for k in $keys; do echo "$k $(gsettings get org.gnome.desktop.interface "$k")"; done > "$STATE/gsettings"
    fi
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'capitaine-cursors-light'
    gsettings set org.gnome.desktop.interface cursor-size 32
    gsettings set org.gnome.desktop.interface font-name 'Inter 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    info "dark theme, Papirus icons, Capitaine cursor, Inter font"
fi

# ---------- login screen ----------
if [ -n "$GREETER" ]; then
    step "Login screen (greetd)"
    if [ ! -f "$STATE/greeter" ]; then
        # display manager enabled before bezel ("none" = console login)
        prev=none
        dm=/etc/systemd/system/display-manager.service
        [ -L "$dm" ] && prev=$(basename "$(readlink -f "$dm")")
        echo "$prev" > "$STATE/greeter"
        [ -f /etc/greetd/config.toml ] && cp /etc/greetd/config.toml "$STATE/greetd-config.toml"
    fi
    "$CONFIG_SRC/quickshell/greeter/install.sh" >/dev/null
    sudo install -m 644 "$CONFIG_SRC/quickshell/greeter/greetd.toml" /etc/greetd/config.toml
    sudo systemctl enable -f greetd.service >/dev/null 2>&1
    info "greetd enabled (previous display manager: $(cat "$STATE/greeter"))"
fi

# ---------- done ----------
step "Done"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null 2>&1 && info "Hyprland reloaded"
    if ask "Restart the shell now?" y; then
        pkill -x quickshell 2>/dev/null || true
        hyprctl dispatch 'hl.dsp.exec_cmd("quickshell")' >/dev/null 2>&1 || (setsid quickshell >/dev/null 2>&1 &)
    fi
else
    info "Log in to a Hyprland session to start using bezel."
fi
info "SUPER+H lists every shortcut. Uninstall: ./uninstall.sh"
