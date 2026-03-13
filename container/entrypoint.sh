#!/bin/bash
set -e

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

exec "$@"
