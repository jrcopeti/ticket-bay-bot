# The agent's sandbox image: official bases only, so /home has no leftover user account.
# Node 22 binaries come from the official node image (same Debian release: trixie).
FROM node:22-trixie-slim@sha256:b26b04c123d9ff8ab646ceb18b9d75a1173acf64b9a401094b906d27b29338d4 AS node

# python:3.12-trixie = the full Debian image: gcc, make, ssh, curl, git (node-gyp builds work)
FROM python:3.12-trixie@sha256:3528d5830ec8b7c8729a2a9961154061c7d34e114089ab5c6b1da707ed581c87
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/include/node /usr/local/include/node
COPY --from=node /opt/yarn-v1.22.22 /opt/yarn-v1.22.22
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && ln -s ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack \
 && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
 && ln -s /opt/yarn-v1.22.22/bin/yarn /usr/local/bin/yarn \
 && ln -s /opt/yarn-v1.22.22/bin/yarnpkg /usr/local/bin/yarnpkg \
 && corepack enable pnpm \
 && node -v && npm -v && npx -v
RUN apt-get update && apt-get install -y --no-install-recommends git jq ca-certificates curl gnupg  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg  && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list  && apt-get update && apt-get install -y --no-install-recommends gh  && rm -rf /var/lib/apt/lists/*
# The name on the agent's commits. Override with: docker build --build-arg AGENT_NAME=Morpheus …
ARG AGENT_NAME=agent
ARG AGENT_EMAIL=agent@users.noreply.github.com
RUN git config --system user.name "$AGENT_NAME" && git config --system user.email "$AGENT_EMAIL" && git config --system --add safe.directory "*"
WORKDIR /workspace
RUN git config --system credential.https://github.com.helper "!gh auth git-credential"
# git >= 2.48 for relative-path worktrees: git only, from Debian testing (forky), pinned low so nothing else upgrades
RUN echo "deb http://deb.debian.org/debian forky main" > /etc/apt/sources.list.d/forky.list \
 && printf "Package: *\nPin: release n=forky\nPin-Priority: 100\n" > /etc/apt/preferences.d/forky \
 && apt-get update && apt-get install -y --no-install-recommends -t forky git \
 && rm -rf /var/lib/apt/lists/* && git --version
# no user accounts in /home: commands run as container root
RUN test -z "$(ls -A /home)"
CMD ["bash"]
