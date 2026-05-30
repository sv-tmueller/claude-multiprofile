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
## Pro Tips
Per-project defaults: If a project always uses a specific account, add `CLAUDE_CONFIG_DIR=~/.claude-account1` to a .env file in that project's root directory.

Descriptive names: Use meaningful names like `claude-personal`, `claude-clientname`, or `claude-work` instead of generic numbers. Your future self will thank you.

NVM users: If you manage Node versions with NVM, your Claude binary path includes the Node version (e.g., `.nvm/versions/node/v24.6.0/bin/claude`). If you upgrade Node, remember to update your aliases.
