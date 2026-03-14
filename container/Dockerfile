# syntax=docker/dockerfile:1
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
    wget \
    gnupg \
    g++ \
    make \
    python3 \
    apt-utils\
    git \
    gosu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 
#    && npm --global install npm pm2 npx prisma \
#    && rm -rf /opt/yarn* \
#    && rm -rf /root/.npm \
#    && rm -rf /tmp/*


######################

ENV NODE_VERSION=25.8.1
ENV NVM_DIR=/usr/local/nvm

RUN mkdir -p $NVM_DIR

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

RUN . "${NVM_DIR}/nvm.sh" \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use $NODE_VERSION

ENV PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}"

######################


# Set Chromium path for agent-browser
#ENV AGENT_BROWSER_EXECUTABLE_PATH=/usr/bin/chromium
#ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

# Install Claude Code via native installer, then copy binary to /usr/local/bin for all users
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && cp /root/.local/bin/claude /usr/local/bin/claude

# Install remaining npm packages
RUN npm install -g obsidian-headless claude-code-web

# Copy local clive repo into the container
COPY --chown=claude:claude clive/ /clive/

# Fix project-level .claude/ symlinks (originally point to macOS paths)
RUN rm -f /clive/.claude/agents /clive/.claude/rules && \
    ln -s /clive/agents /clive/.claude/agents && \
    ln -s /clive/rules  /clive/.claude/rules && \
    ln -s /clive/skills /clive/.claude/skills && \
    ln -s /clive/hooks  /clive/.claude/hooks && \
    ln -s /clive/mcp    /clive/.claude/mcp && \
    chown -h claude:claude /clive/.claude/*

# Copy local obsidian vault to staging location (copied to /data/vault on first run)
COPY --chown=claude:claude obsidian-vault/ /opt/vault-initial/

# Claude Code global config dir — persisted to /data/.claude via entrypoint
# Project config in /clive/.claude is loaded automatically since WORKDIR is /clive
RUN mkdir -p /home/claude/.claude && chown claude:claude /home/claude/.claude

# Install npm deps if the repo has a package.json
RUN if [ -f /clive/package.json ]; then \
      cd /clive && npm install; \
    fi

# Prepare persistent data directory and entrypoint
RUN mkdir -p /data && chown claude:claude /data
COPY --chmod=755 container/entrypoint.sh /usr/local/bin/entrypoint.sh

# Set ownership and permissions
RUN chmod 777 /home/claude

# Entrypoint runs as root to fix volume permissions, then drops to claude via gosu
WORKDIR /clive

EXPOSE 32352

ENTRYPOINT ["entrypoint.sh"]
CMD ["npx", "claude-code-web", "--no-open", "--plan", "pro", "--auth", "qubkok-vofzU5-tucquk"]
