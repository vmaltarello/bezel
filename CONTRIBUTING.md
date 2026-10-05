# Contributing to bezel

Thanks for helping! bezel is a small project with a clear goal: a Hyprland desktop
that installs cleanly on Arch Linux and uninstalls just as cleanly. These rules keep it that way.

## Before you start

- **Bugs**: open an issue with the *Bug report* template. Include your Hyprland and Quickshell versions
  and the relevant log (see below); without them most bugs can't be reproduced.
- **Ideas and bigger changes**: open an issue first (*Feature request*) and wait for a reply before
  writing code. A new panel, a new dependency or a change of look is easier to agree on before it is built.
- **Small fixes** (typos, obvious bugs, docs): a pull request is fine straight away.
- **Questions**: use GitHub Discussions if enabled, otherwise an issue.

## Project rules

1. **Official repositories only.** Every dependency must be installable with `pacman` from the official
   Arch repos. No AUR packages, no `curl | sh`, no binaries in the repo.
2. **Clean install, clean uninstall.** Anything `install.sh` writes must be recorded in the manifest and
   removed (or restored from the backup) by `uninstall.sh`. Never touch files outside `~/.config`,
   `~/.local/state/bezel` and, only for the optional greeter, `/etc/greetd`, `/etc/quickshell-greeter`,
   `/var/lib/quickshell-greeter`.
3. **The user's files are theirs.** `~/.config/hypr/hyprland.lua` is written once and never overwritten.
   New options go into `hypr/bezel/*.lua` or `quickshell/config/Config.qml` with a sensible default.
4. **Hardware-neutral.** No hard-coded device paths, monitor names, scales or keyboard layouts:
   detect them (see `services/Brightness.qml`, `services/System.qml`) or make them a setting.
5. **No private or third-party assets.** No wallpapers, fonts or icons in the repo. Screenshots must not
   show personal data (networks, device names, browser tabs, terminal history).
6. **One palette.** Colors, fonts, sizes and animation times come from `quickshell/config/Theme.qml`;
   app themes (kitty, GTK, Qt, yazi, btop…) use the same values. No new accent colors.
7. **Light on resources.** The shell renders in software. Avoid continuous animations, timers that run
   while nothing is visible, and anything that keeps the CPU awake at idle.

## Code style

- **English** for code, comments, commit messages and UI text.
- Match the surrounding code: naming, indentation (4 spaces), comment density.
- Comments explain *why* (a workaround, a compositor quirk), not what the next line does.
- **QML**: one component per file, theme values via `Theme.*`, settings via `Config.*`, shared state in
  `services/` singletons. With the software renderer, prefer `RRect`/`Rectangle` over `Shape` inside
  scrolling views (clipping doesn't apply to shapes there).
- **Lua (Hyprland)**: theme behaviour in `hypr/bezel/`, every keybinding with a description
  (they are listed by `SUPER+H`).
- **Shell scripts**: `bash`, `set -euo pipefail` where it makes sense, quote your variables,
  check with `bash -n` (and `shellcheck` if you have it).

## Testing your change

Run what applies before opening a pull request:

```sh
# Hyprland config: must print "config ok"
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua

# Shell: watch the log while it hot-reloads your edits
quickshell log -f

# Panels rendered offscreen to PNG, without touching your screen
mkdir -p "$XDG_RUNTIME_DIR/quickshell-harness"
QT_QPA_PLATFORM=offscreen HARNESS=menus quickshell -p config/quickshell/dev-harness.qml
#   HARNESS = menus | launcher | widgets | lock   (output in $XDG_RUNTIME_DIR/quickshell-harness/)

# Installer: install, update and uninstall in a throw-away HOME; the last diff must be empty
H=$(mktemp -d); mkdir -p "$H/.config"; cp -a "$H" "$H.before"
run() { env -u HYPRLAND_INSTANCE_SIGNATURE -u XDG_CONFIG_HOME -u XDG_STATE_HOME HOME="$H" GSETTINGS_BACKEND=memory "$@"; }
run ./install.sh --yes --no-packages --all && run ./install.sh --yes --no-packages && run ./uninstall.sh --yes
rm -rf "$H/.cache"; diff -r "$H.before" "$H" && echo "clean"
```

For development, install with `./install.sh --link`: your `~/.config` then points to the repo, so every
edit is live and ready to commit.

## Commits and pull requests

- **One-line commit messages** in [Conventional Commits](https://www.conventionalcommits.org) style:
  `feat(launcher): add calculator history`, `fix(lock): reset state on every lock`, `docs: …`.
  No body needed; put the details in the pull request.
- One topic per pull request. Keep unrelated cleanups for a separate one.
- Describe what changed and how you tested it; add a screenshot or a short clip for anything visual.
- Update `README.md` when you add a feature, a keybinding or a dependency (and `packages/*.txt`
  for the dependency).

## Logs for bug reports

```sh
hyprctl version | head -2
pacman -Q quickshell hyprland
quickshell log | tail -50
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

## License

By contributing you agree that your work is released under the project's [GPL-3.0-or-later license](LICENSE).
