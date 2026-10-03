# bezel — shared helpers for install.sh and uninstall.sh (sourced, not executed)

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG_SRC="$REPO/config"
CONFIG_DST="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/bezel"
MANIFEST="$STATE/manifest"        # one line per installed item: "file <rel>" or "dir <rel>"
BACKUP="$STATE/backup"            # what was there before, same layout as ~/.config

# ---------- output ----------
if [ -t 1 ]; then
    c_amber=$'\e[38;2;230;180;80m'; c_dim=$'\e[2m'; c_red=$'\e[31m'; c_off=$'\e[0m'
else
    c_amber=; c_dim=; c_red=; c_off=
fi
step() { printf '\n%s❯ %s%s\n' "$c_amber" "$*" "$c_off"; }
info() { printf '  %s\n' "$*"; }
note() { printf '  %s%s%s\n' "$c_dim" "$*" "$c_off"; }
warn() { printf '  %swarning:%s %s\n' "$c_red" "$c_off" "$*"; }
die()  { printf '%serror:%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }

# ask "question" default(y|n) -> 0 for yes. With ASSUME_YES the default is taken.
ask() {
    local q=$1 def=${2:-y} hint ans
    [ "$def" = y ] && hint="Y/n" || hint="y/N"
    if [ -n "${ASSUME_YES:-}" ] || [ ! -t 0 ]; then ans=$def
    else read -rp "  $q [$hint] " ans; ans=${ans:-$def}; fi
    [[ $ans =~ ^[Yy] ]]
}

# ---------- components ----------
# paths are relative to config/ (and to ~/.config); a trailing / means "the whole folder"
COMPONENTS=(core yazi btop lazygit starship zathura imv zed nvim)
component_paths() {
    case $1 in
        core)     echo "hypr/hyprland.lua hypr/bezel/ hypr/hypridle.conf hypr/hyprlock.conf hypr/scripts/
                        quickshell/ kitty/ gtk-3.0/ gtk-4.0/ qt6ct/ Kvantum/" ;;
        yazi)     echo "yazi/" ;;
        btop)     echo "btop/" ;;
        lazygit)  echo "lazygit/" ;;
        starship) echo "starship.toml" ;;
        zathura)  echo "zathura/" ;;
        imv)      echo "imv/" ;;
        zed)      echo "zed/themes/default.json" ;;
        nvim)     echo "nvim/" ;;
    esac
}
component_desc() {
    case $1 in
        core)     echo "Hyprland config, Quickshell shell, kitty, GTK/Qt theme" ;;
        yazi)     echo "yazi file manager (SUPER+E) — recommended" ;;
        btop)     echo "btop system monitor (opened from the bar)" ;;
        lazygit)  echo "lazygit colors" ;;
        starship) echo "starship prompt (enable it in your shell rc)" ;;
        zathura)  echo "zathura PDF viewer" ;;
        imv)      echo "imv image viewer" ;;
        zed)      echo "Zed editor theme \"Default Dark\" (theme file only)" ;;
        nvim)     echo "neovim config — REPLACES ~/.config/nvim/init.lua" ;;
    esac
}
# default answer when asked interactively
component_default() { case $1 in nvim) echo n ;; *) echo y ;; esac; }

# folders the theme owns entirely: an existing one is moved to the backup as a whole
OWNED_DIRS="quickshell hypr/bezel Kvantum/default-flat yazi/flavors/default.yazi"

# files the user owns after the first install: never overwritten on update
USER_FILES="hypr/hyprland.lua"

manifest_has() { [ -f "$MANIFEST" ] && grep -qxF "$1" "$MANIFEST"; }
manifest_add() { manifest_has "$1" || echo "$1" >> "$MANIFEST"; }
