#!/bin/bash
set -e

# Fix /data ownership if needed (runs as root, then drops to claude via gosu)
if [ "$(id -u)" = "0" ]; then
    chown claude:claude /data
    exec gosu claude "$0" "$@"
fi

# Persist Claude Code state across rebuilds by storing on the /data volume
# ~/.claude/ holds credentials (.credentials.json), settings, cache, etc.
mkdir -p /data/.claude
rm -rf /home/claude/.claude
ln -sfn /data/.claude /home/claude/.claude

# Sync clive hooks, skills, agents, mcp into global ~/.claude via symlinks
# This makes them available regardless of working directory
for dir in hooks skills agents mcp; do
    if [ -d "/clive/$dir" ]; then
        rm -rf "/data/.claude/$dir"
        ln -sfn "/clive/$dir" "/data/.claude/$dir"
    fi
done

# ~/.claude.json holds general state (userID, firstStartTime, etc.)
ln -sf /data/.claude.json /home/claude/.claude.json

# ~/.claude-code-web/ holds web UI sessions
mkdir -p /data/.claude-code-web
rm -rf /home/claude/.claude-code-web
ln -sfn /data/.claude-code-web /home/claude/.claude-code-web


# Initialize persistent vault from build-time clone on first run
if [ ! -d /data/vault/.git ]; then
    echo "Initializing obsidian vault in /data/vault..."
    cp -a /opt/vault-initial/. /data/vault/
fi

# --- Obsidian Headless Sync Setup ---

# Login if credentials are provided and not already logged in
if [ -n "$OBSIDIAN_EMAIL" ] && [ -n "$OBSIDIAN_PASSWORD" ]; then
    if ! ob sync-list-remote &>/dev/null; then
        echo "Logging in to Obsidian..."
        ob login --email "$OBSIDIAN_EMAIL" --password "$OBSIDIAN_PASSWORD" ${OBSIDIAN_MFA:+--mfa "$OBSIDIAN_MFA"}
    fi
fi

# Set up sync if a remote vault is specified and not already linked
if [ -n "$OBSIDIAN_VAULT" ]; then
    if ! ob sync-status --path /data/vault &>/dev/null; then
        echo "Setting up Obsidian Sync for vault: $OBSIDIAN_VAULT"
        ob sync-setup \
            --vault "$OBSIDIAN_VAULT" \
            --path /data/vault \
            --device-name "${OBSIDIAN_DEVICE_NAME:-clive-container}" \
            ${OBSIDIAN_ENCRYPTION_PASSWORD:+--password "$OBSIDIAN_ENCRYPTION_PASSWORD"}
    fi

    # Start continuous sync in the background
    echo "Starting Obsidian Sync (continuous)..."
    ob sync --path /data/vault --continuous &
fi

# Symlink the obsidian vault into the clive working directory
ln -sfn /data/vault /clive/vault

# Export container env vars so tmux sessions inherit them
printenv | grep -vE '^(HOME|USER|SHELL|TERM|PATH|PWD|SHLVL|_)=' | while IFS='=' read -r key value; do
    echo "export ${key}='${value}'"
done > /home/claude/.container-env
echo '. /home/claude/.container-env' >> /home/claude/.bashrc

# Start a persistent tmux session for interactive access
tmux new-session -d -s clive

exec "$@"
