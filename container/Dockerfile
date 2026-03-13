# Clive Agent Container

FROM debian:latest

RUN useradd -m -u 1001 claude

# Install system dependencies for Chromium and tmux
RUN apt-get update && apt-get install -y \
    tmux \
#    chromium \
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/* 
#    && npm --global install npm pm2 npx prisma \
#    && rm -rf /opt/yarn* \
#    && rm -rf /root/.npm \
#    && rm -rf /tmp/*


ENV NVM_DIR /usr/local/nvm

RUN mkdir -p "$NVM_DIR"; \
    curl -o- \ 
        "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" | \ 
        bash \
    ; \
    source $NVM_DIR/nvm.sh; \
    nvm install --lts --latest-npm


# Set Chromium path for agent-browser
#ENV AGENT_BROWSER_EXECUTABLE_PATH=/usr/bin/chromium
#ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

#RUN curl -fsSL https://claude.ai/install.sh | bash

# Install claude-code globally
RUN npm install -g @anthropic-ai/claude-code obsidian-headless
#RUN npm install -g obsidian-headless

# Create app directory
WORKDIR /app


COPY . .

# Install dependencies
RUN npm install

# Build TypeScript
RUN npm run build

# Create workspace directories
RUN mkdir -p /clive

# Create entrypoint script
# Container input (prompt, group info) is passed via stdin JSON.
# Credentials are injected by the host's credential proxy — never passed here.
# Follow-up messages arrive via IPC files in /workspace/ipc/input/
#RUN printf '#!/bin/bash\nset -e\ncd /app && npx tsc --outDir /tmp/dist 2>&1 >&2\nln -s /app/node_modules /tmp/dist/node_modules\nchmod -R a-w /tmp/dist\ncat > /tmp/input.json\nnode /tmp/dist/index.js < /tmp/input.json\n' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Set ownership to node user (non-root) for writable directories
RUN chown -R claude:claude /clive && chmod 777 /home/claude

# Switch to non-root user (required for --dangerously-skip-permissions)
#USER node
# Switch to non-root user Set working directory to group workspace
USER claude

WORKDIR /clive

# Entry point reads JSON from stdin, outputs JSON to stdout
ENTRYPOINT ["tmux", "new -s claude"]
