#!/usr/bin/env bash
# bezel uninstaller — removes every file the installer put in place and restores what was there before.
#
#   ./uninstall.sh            interactive
#   ./uninstall.sh --yes      default answers (packages are kept unless --packages is given)
#   ./uninstall.sh --packages also remove the packages the installer added
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

ASSUME_YES= RM_PKGS=
while [ $# -gt 0 ]; do
    case $1 in
        -y|--yes) ASSUME_YES=1 ;;
        --packages) RM_PKGS=1 ;;
        -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
done

[ "$(id -u)" -ne 0 ] || die "run as your normal user, not root"
[ -f "$MANIFEST" ] || die "bezel is not installed (no $MANIFEST)"

printf '%sbezel%s — uninstalling\n' "$c_amber" "$c_off"
ask "Remove the bezel theme and restore your previous configuration?" y || exit 0

restore() {  # put the backed up ~/.config/<rel> back, if there is one
    local rel=$1
    if [ -e "$BACKUP/$rel" ] || [ -L "$BACKUP/$rel" ]; then
        mkdir -p "$(dirname "$CONFIG_DST/$rel")"
        rm -rf "${CONFIG_DST:?}/$rel"
        mv "$BACKUP/$rel" "$CONFIG_DST/$rel"
        note "restored your $rel"
    fi
}

# ---------- files ----------
step "Config files"
dirs=()
while read -r kind rel; do
    case $kind in
        file)
            # inside a folder the theme owns, the whole folder is removed and restored below (from its own
            # backup); never rm through it: with --link it is a symlink to the repo
            in_owned=
            for d in $OWNED_DIRS; do [[ $rel == "$d"/* ]] && in_owned=1; done
            [ -n "$in_owned" ] || { rm -f "${CONFIG_DST:?}/$rel"; restore "$rel"; }
            dirs+=("$(dirname "$rel")") ;;
        dir)
            rm -rf "${CONFIG_DST:?}/$rel"
            restore "$rel"
            dirs+=("$(dirname "$rel")") ;;
        moved)
            restore "$rel" ;;
        cache)
            rm -rf "${CACHE_DST:?}/$rel"
            rmdir -p "$(dirname "$CACHE_DST/$rel")" 2>/dev/null || true ;;
    esac
done < <(tac "$MANIFEST")
# remove folders left empty, deepest first
for d in $(printf '%s\n' "${dirs[@]}" | sort -u | awk '{ print length, $0 }' | sort -rn | cut -d' ' -f2-); do
    while [ "$d" != "." ] && [ -n "$d" ]; do
        rmdir "$CONFIG_DST/$d" 2>/dev/null || break
        d=$(dirname "$d")
    done
done
# data the theme writes while running (launcher usage, current wallpaper link, blurred lock copy, nvim plugin lock)
rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/launches.json" "${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
rm -rf "$CACHE_DST/wallpaper"
grep -qx "component nvim" "$MANIFEST" && ! grep -qx "keep nvim/nvim-pack-lock.json" "$MANIFEST" && rm -f "$CONFIG_DST/nvim/nvim-pack-lock.json"
rmdir "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell" "$CONFIG_DST/nvim" 2>/dev/null || true
info "theme files removed"

# ---------- GTK settings ----------
if [ -f "$STATE/gsettings" ] && command -v gsettings >/dev/null; then
    while read -r k v; do gsettings set org.gnome.desktop.interface "$k" "$v" 2>/dev/null || true; done < "$STATE/gsettings"
    info "GTK settings restored"
fi

# ---------- login screen ----------
if [ -f "$STATE/greeter" ]; then
    step "Login screen"
    prev=$(cat "$STATE/greeter")
    if [ -f "$STATE/greetd-config.toml" ]; then
        sudo install -m 644 "$STATE/greetd-config.toml" /etc/greetd/config.toml
    fi
    sudo rm -rf /etc/quickshell-greeter /var/lib/quickshell-greeter
    if [ "$prev" = none ]; then
        sudo systemctl disable greetd.service >/dev/null 2>&1 || true
        info "greetd disabled: login from the console, as before bezel"
    elif [ "$prev" != greetd.service ]; then
        sudo systemctl enable -f "$prev" >/dev/null 2>&1 && info "display manager back to $prev"
    fi
fi

# ---------- services and packages ----------
if [ -f "$STATE/services" ] && ask "Disable the services the installer enabled ($(xargs < "$STATE/services"))?" n; then
    xargs sudo systemctl disable --now < "$STATE/services" || true
fi
if [ -f "$STATE/packages" ]; then
    # shellcheck disable=SC2046  # package names, split on purpose
    pkgs=$(pacman -Qq $(cat "$STATE/packages") 2>/dev/null | xargs || true)
    if [ -n "$pkgs" ]; then
        step "Packages"
        info "installed by bezel: $pkgs"
        if [ -n "$RM_PKGS" ] || { [ -z "$ASSUME_YES" ] && ask "Remove them? (packages other programs need are kept)" n; }; then
            # one by one, two passes: a package still needed by another program is kept
            for _ in 1 2; do
                for p in $pkgs; do
                    pacman -Q "$p" >/dev/null 2>&1 || continue
                    sudo pacman -Rns --noconfirm "$p" >/dev/null 2>&1 && note "removed $p"
                done
            done
            left=$(pacman -Qq $pkgs 2>/dev/null | xargs || true)
            [ -z "$left" ] || note "kept (needed by other programs): $left"
        fi
    fi
fi

# ---------- state ----------
rm -rf "$STATE"
rmdir -p "$(dirname "$STATE")" 2>/dev/null || true     # ~/.local/state, if bezel left it empty
step "Done"
info "bezel removed. Log out and back in (or restart Hyprland) to finish."
