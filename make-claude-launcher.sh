#!/usr/bin/env bash
#
# make-claude-launcher.sh - create a macOS launcher for one Claude desktop
# profile, so multiple accounts can run side by side.
#
# The Claude desktop app keeps its signed-in account in its Electron user-data
# dir (~/Library/Application Support/Claude), which is separate from
# CLAUDE_CONFIG_DIR (that only affects the CLI and the app's embedded Claude
# Code surface). Point a launch at its own user-data dir with --user-data-dir
# and it runs as a separate account, alongside the default one.
#
# Usage:
#   ./make-claude-launcher.sh <ProfileName> [user-data-dir]
#
#   ProfileName    label for the launcher, e.g. Personal or Work
#   user-data-dir  Electron user-data dir for this profile. Give each profile
#                  its own dir, distinct from the default one the plain Claude
#                  icon uses. Default: ~/Library/Application Support/Claude-<ProfileName>
#
# Creates ~/Applications/Claude <ProfileName>.app. Pin it to the Dock. On first
# launch, log in to the account you want for this profile.

set -euo pipefail

name="${1:-}"
if [ -z "$name" ]; then
  echo "usage: $0 <ProfileName> [user-data-dir]" >&2
  exit 2
fi
data_dir="${2:-$HOME/Library/Application Support/Claude-$name}"
app="/Applications/Claude.app"
out="$HOME/Applications/Claude $name.app"

if [ ! -d "$app" ]; then
  echo "error: Claude.app not found at $app" >&2
  exit 1
fi
mkdir -p "$HOME/Applications"

# The launcher first checks whether this profile is already running (matched by
# its user-data-dir). If so it just activates Claude; only otherwise does it
# start a new instance. Two instances sharing one user-data dir corrupt that
# profile's data, and the app's single-instance lock does not prevent it, so
# this guard is not optional. The [C] in the match pattern stops the guard's own
# shell process from matching itself in pgrep.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/launcher.applescript" <<EOF
set profileDir to "$data_dir"
set pat to "[C]ontents/MacOS/Claude --user-data-dir=" & profileDir
set n to (do shell script "pgrep -f " & quoted form of pat & " | wc -l | tr -d ' '")
if n is "0" then
	do shell script "open -n $app --args --user-data-dir=" & quoted form of profileDir
else
	do shell script "open -a Claude"
end if
EOF

rm -rf "$out"
osacompile -o "$out" "$tmp/launcher.applescript"

# Use Claude's own icon so the launcher is recognizable in the Dock.
cp "$app/Contents/Resources/electron.icns" "$out/Contents/Resources/applet.icns" 2>/dev/null || true
touch "$out"

echo "Created: $out"
echo "Profile user-data dir: $data_dir"
echo "Pin it to the Dock; on first launch, log in to this profile's account."
