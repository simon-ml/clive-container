# Clive Container

Dockerized [Claude Code](https://github.com/anthropics/claude-code) agent with Obsidian vault sync, exposed via `claude-code-web` on port **32352**.

## Prerequisites

- Docker and Docker Compose
- A GitHub personal access token (for cloning private repos at build time)
- An Anthropic API key

## Quick Start

1. **Create your `.env` file** from the example:

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and set at minimum:

   ```
   GITHUB_TOKEN=ghp_...
   ANTHROPIC_API_KEY=sk-ant-...
   ```

2. **Build and run** with Docker Compose:

   ```bash
   docker compose up -d --build
   ```

   Or build the image standalone:

   ```bash
   ./build.sh
   ```

3. **Access the web UI** at `http://<host>:32352`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GITHUB_TOKEN` | Yes | GitHub PAT for cloning private repos during build and runtime git operations |
| `ANTHROPIC_API_KEY` | Yes | Anthropic API key for Claude Code |
| `OBSIDIAN_EMAIL` | No | Obsidian account email (enables sync) |
| `OBSIDIAN_PASSWORD` | No | Obsidian account password |
| `OBSIDIAN_MFA` | No | Obsidian MFA code (if 2FA is enabled) |
| `OBSIDIAN_VAULT` | No | Remote Obsidian vault name to sync |
| `OBSIDIAN_DEVICE_NAME` | No | Device name for Obsidian Sync (default: `clive-container`) |
| `OBSIDIAN_ENCRYPTION_PASSWORD` | No | End-to-end encryption password for Obsidian Sync |

## Project Structure

```
.
├── build.sh                 # Standalone image build script
├── docker-compose.yml       # Compose service definition
├── .env.example             # Example environment variables
├── .env                     # Your local env vars (gitignored)
└── container/
    ├── Dockerfile           # Image definition
    └── entrypoint.sh        # Runtime init (vault sync, etc.)
```

## Data Persistence

The container mounts a host volume for persistent data:

```
/home/simon/docker-data/clive-container-data → /data (in container)
```

On first run, the Obsidian vault is copied from the build-time clone into `/data/vault`. Subsequent runs reuse the existing data.

## Obsidian Sync

If `OBSIDIAN_EMAIL`, `OBSIDIAN_PASSWORD`, and `OBSIDIAN_VAULT` are set, the entrypoint will:

1. Log in to Obsidian (with optional MFA)
2. Set up sync for the specified vault at `/data/vault`
3. Run continuous sync in the background

## Rebuilding

To rebuild after changes:

```bash
docker compose up -d --build
```

Or with the standalone script:

```bash
./build.sh
docker compose up -d
```
