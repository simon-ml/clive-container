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

#RUN curl -fsSL https://claude.ai/install.sh | bash

# Install claude-code globally
RUN npm install -g @anthropic-ai/claude-code obsidian-headless claude-code-web
#RUN npm install -g obsidian-headless

# Clone clive repo using a build secret (token never baked into any layer)
RUN --mount=type=secret,id=github_token \
    bash -c 'TOKEN=$(tr -d "[:space:]" < /run/secrets/github_token) && GIT_TERMINAL_PROMPT=0 git clone https://oauth2:${TOKEN}@github.com/simon-ml/clive.git /clive && chown -R claude:claude /clive'

# Clone obsidian vault to staging location (copied to /data/vault on first run)
RUN --mount=type=secret,id=github_token \
    bash -c 'TOKEN=$(tr -d "[:space:]" < /run/secrets/github_token) && GIT_TERMINAL_PROMPT=0 git clone https://oauth2:${TOKEN}@github.com/simon-ml/obsidian-vault.git /opt/vault-initial && chown -R claude:claude /opt/vault-initial'

# Set up ~/.claude from repo's .claude dir (or create empty dir)
RUN if [ -d /clive/.claude ]; then \
      ln -sf /clive/.claude /home/claude/.claude; \
    else \
      mkdir -p /home/claude/.claude; \
    fi \
    && chown -R claude:claude /home/claude/.claude

# Install npm deps if the repo has a package.json
RUN if [ -f /clive/package.json ]; then \
      cd /clive && npm install; \
    fi

# Prepare persistent data directory and entrypoint
RUN mkdir -p /data && chown claude:claude /data
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# Set ownership and permissions
RUN chmod 777 /home/claude

# Switch to non-root user (required for --dangerously-skip-permissions)
#USER node
# Switch to non-root user Set working directory to group workspace
USER claude

WORKDIR /clive

EXPOSE 32352

ENTRYPOINT ["entrypoint.sh"]
CMD ["npx", "claude-code-web", "--no-open"]
