# claude-multiprofile

Setting Up Multiple Claude Code Accounts on Your Local Machine
If you have multiple claude accounts with you, for an example your personal one and office account propably you want to switch between them. So here is I do it in my local setup

## How It Works
Claude Code stores its configuration and session data in a directory on your machine (typically `~/.claude`). The key insight is that you can point Claude Code to a different config directory for each account using the `CLAUDE_CONFIG_DIR` environment variable. Each directory holds its own independent session, so accounts never interfere with each other.

## Step 1: Create Separate Config Directories
Open your terminal and run:
```
mkdir -p ~/.claude-personal
mkdir -p ~/.claude-work
```
The `-p` flag ensures the command runs safely even if the directories already exist. Name these whatever makes sense for you — for example, `~/.claude-personal` and `~/.claude-work`.

## Step 2: Find Your Claude Binary Path
Before setting up aliases, you need the real path to the Claude Code binary. Since we’ll be overriding the default `claude` command, you need to reference the binary directly.

Run:
```
type -a claude
```
You’ll get output like: (If you already installed it globally via npm)

```
TM@Mac ~ % type -a claude
claude is /Users/TM/.local/bin/claude
```
Copy the path

## Step 3: Set Up Shell Aliases
Open your shell config file:

```
nano ~/.zshrc    # macOS (zsh)
# or
nano ~/.bashrc   # Linux (bash)
```
Add the following aliases, replacing the binary path with yours and the directory names with your own:

```
alias claude-personal='CLAUDE_CONFIG_DIR=~/.claude-personal /Users/TM/.local/bin/claude'
alias claude-work='CLAUDE_CONFIG_DIR=~/.claude-work /Users/TM/.local/bin/claude'
alias claude="echo 'Use specific commands: claude-personal or claude-work'"
```
The third alias is optional but highly recommended — it overrides the plain `claude` command with a helpful reminder, so you never accidentally launch Claude without the right account context.

Save the file and reload your shell:
```
source ~/.zshrc
```

## Step 4: Authenticate Each Account
Now log in to each account separately.

Account 1:
```
claude-personal
```
Once Claude Code launches, run:
```
/login
```
A browser window will open. Sign in with the credentials for account 1. The session is saved to `~/.claude-personal`.

Open a new terminal tab and repeat the process:

## Step 5: Verify Everything Works
Test your setup:
```
claude           # Should print your reminder message
claude-personal  # Should launch Claude Code with account 1
claude-work      # Should launch Claude Code with account 2
```
Inside Claude Code, you can confirm the active session by running:
```
/status
```
## Using the Claude Desktop App (macOS)

The aliases above only affect terminals. A desktop app launched from the Dock or Finder is started by macOS `launchd`, not your shell, so it never sees the `CLAUDE_CONFIG_DIR` you set in `~/.zshrc`. It falls back to the default `~/.claude`, where your profile's config (skills, settings, saved sessions) is not stored.

To point the desktop app at a profile, set `CLAUDE_CONFIG_DIR` at the macOS login-session level with a LaunchAgent that runs once at login.

This points the Claude Code surface of the desktop app (the coding/agent mode) at a profile's config directory: its skills, settings, and saved sessions. It does not change the app's own signed-in (chat) account, which follows the app's user-data directory instead; see [Running two desktop apps side by side](#running-two-desktop-apps-side-by-side-macos). The plain chat does not load your Claude Code skills regardless of this setting. This relies on current desktop-app behavior that Anthropic does not document, so it may change.

### Step 1: Create the LaunchAgent

Pick the profile the desktop app should use, then create a plist. Replace `<you>` with your macOS username. The path must be absolute, because `launchctl` does not expand `~`.

Create `~/Library/LaunchAgents/com.<you>.claude-config-dir.plist`:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.<you>.claude-config-dir</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/launchctl</string>
		<string>setenv</string>
		<string>CLAUDE_CONFIG_DIR</string>
		<string>/Users/<you>/.claude-personal</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
```

For the work profile, use `/Users/<you>/.claude-work` as the path instead.

### Step 2: Load It and Verify

Load the agent now (it also runs automatically at every login, so it survives reboots):

```
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.<you>.claude-config-dir.plist
launchctl getenv CLAUDE_CONFIG_DIR
```

The second command should print the path you set. Fully quit and reopen the desktop app, and its Claude Code surface will use that profile. Confirm inside the app with:

```
/status
```

### Step 3: Switch Profiles

A LaunchAgent sets one value for the whole login session, so the desktop app uses one profile at a time. To switch for the current session, point the variable at the other directory and restart the app:

```
launchctl setenv CLAUDE_CONFIG_DIR /Users/<you>/.claude-work
```

To make the switch stick across reboots, edit the path in the plist, then reload it:

```
launchctl bootout gui/$(id -u)/com.<you>.claude-config-dir
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.<you>.claude-config-dir.plist
```

Running the personal and work apps at the same time is not possible this way (one session, one value). For that, see [Running two desktop apps side by side](#running-two-desktop-apps-side-by-side-macos).

### Removing It

```
launchctl bootout gui/$(id -u)/com.<you>.claude-config-dir
rm ~/Library/LaunchAgents/com.<you>.claude-config-dir.plist
launchctl unsetenv CLAUDE_CONFIG_DIR
```

## Running two desktop apps side by side (macOS)

The LaunchAgent above sets one `CLAUDE_CONFIG_DIR` for the whole login session, so the desktop app uses one profile at a time. Running a personal and a work window at the same time needs a different lever.

The desktop app keeps its signed-in account in its own Electron user-data directory (`~/Library/Application Support/Claude`), separate from `CLAUDE_CONFIG_DIR`. Point a launch at a different user-data directory with `--user-data-dir` and it runs as a separate account, alongside the default one. Each directory keeps its own login and its own instance lock, so both can run at once.

### One command

Start a second instance on its own profile directory:

```
open -n /Applications/Claude.app --args --user-data-dir="$HOME/Library/Application Support/Claude-personal"
```

`open -n` forces a new instance and `--args` passes the flag to the app. A new directory starts signed out, so log in with the account you want for it. The plain Dock icon keeps using the default directory, so it stays your other account.

### A Dock launcher per account

Typing that every time is tedious, and running it again while that profile is already open starts a second copy on the same directory, which can corrupt its data (the app's single-instance lock does not stop this). The `make-claude-launcher.sh` script builds a small launcher app that avoids both: it starts the profile if it is not running, and brings Claude to the front if it already is.

```
./make-claude-launcher.sh Personal "$HOME/Library/Application Support/Claude-personal"
```

This creates `~/Applications/Claude Personal.app` with Claude's icon. Pin it to the Dock and click it to open or focus that account. Run it again with a different name and directory for each account you want a launcher for, and give each profile its own directory, distinct from the default one the plain icon uses.

### Trade-off

Both running instances still show as "Claude" in the Dock and app switcher, so you tell them apart by their windows, not the switcher. For fully separate Dock identities you would duplicate the app bundle under its own bundle identifier, which is heavier and stops the copy from auto-updating.

## Pro Tips
Per-project defaults: If a project always uses a specific account, add `CLAUDE_CONFIG_DIR=~/.claude-account1` to a .env file in that project's root directory.

Descriptive names: Use meaningful names like `claude-personal`, `claude-clientname`, or `claude-work` instead of generic numbers. Your future self will thank you.

NVM users: If you manage Node versions with NVM, your Claude binary path includes the Node version (e.g., `.nvm/versions/node/v24.6.0/bin/claude`). If you upgrade Node, remember to update your aliases.
