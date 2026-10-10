# Security

bezel is configuration and scripts for your desktop, but some of it guards the machine or runs
with more rights than your user, and a mistake there is a security problem.

## What to report privately

- **Lock screen**: any way to see or use the session while it is locked, or to unlock it
  without the password (keys, a second monitor, suspend and resume, a crash of the shell).
- **Login screen** (`--greeter`): anything that lets someone log in or run commands without
  a valid password.
- **Installer**: `install.sh` uses `sudo` to install packages, enable services and, with
  `--greeter`, install the login screen in `/etc/greetd`, `/etc/quickshell-greeter` and
  `/var/lib/quickshell-greeter`; it should never touch anything else outside your home, or
  leave files that other users can change and the system then trusts.
- **Commands**: a file name, clipboard entry, notification, network or device name that makes
  the shell or a script run something it shouldn't.

Use [private vulnerability reporting](https://github.com/vmaltarello/bezel-hyprland/security/advisories/new),
not a public issue, so the problem isn't public before it is fixed. Include the bezel version
(`git describe --tags` in your clone), how to reproduce it, and what it lets someone do.

You will get an answer within a week. Fixes go into a new release, and the report is
credited unless you prefer otherwise.

## Supported versions

Only the latest release gets fixes.
