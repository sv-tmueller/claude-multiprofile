#!/usr/bin/env bash
#
# make-claude-launcher.sh - create a macOS launcher for one Claude desktop
# profile, so multiple accounts can run side by side.
#
# Each launch uses its own Electron user-data dir (--user-data-dir), which keeps
# that profile's local data (chat history, settings, window state) separate and
# lets a second account exist at all.
#
# Ordering rule (observed): the desktop app shows your DEFAULT account (the one
# in ~/Library/Application Support/Claude) on the FIRST window it opens, whatever
# --user-data-dir that window was given. Only the second and later windows show
# the account of their own user-data dir. So open your default account first,
# then the others.
#
# Usage:
#   ./make-claude-launcher.sh <ProfileName> [user-data-dir]
#
#   ProfileName    label for the launcher, e.g. Personal or Work
#   user-data-dir  Electron user-data dir for this profile.
#                  Default: ~/Library/Application Support/Claude-<ProfileName>
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

# The launcher opens this profile's dir only if it is not already running, so a
# second click does not start a duplicate window on the same dir. The [C] keeps
# the pattern from matching its own shell process; the trailing ( |$) anchors the
# dir end so a launcher for the default "Claude" dir does not also match a
# "Claude-personal" one.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/launcher.applescript" <<EOF
set profileDir to "$data_dir"
set pat to "[C]ontents/MacOS/Claude --user-data-dir=" & profileDir & "( |\$)"
if (do shell script "pgrep -f " & quoted form of pat & " | wc -l | tr -d ' '") is "0" then
	do shell script "open -n $app --args --user-data-dir=" & quoted form of profileDir
end if
EOF

rm -rf "$out"
osacompile -o "$out" "$tmp/launcher.applescript"

# Use Claude's own icon so the launcher is recognizable in the Dock.
cp "$app/Contents/Resources/electron.icns" "$out/Contents/Resources/applet.icns" 2>/dev/null || true
touch "$out"

echo "Created: $out"
echo "Profile user-data dir: $data_dir"
echo "Pin it to the Dock; open your default/work account first, then this one."
