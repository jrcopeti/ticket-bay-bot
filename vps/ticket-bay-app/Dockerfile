# TicketBay with seed data only, so ticket-bay-bot can call its public MCP tools (step 1b).
# Built from a root-owned clone pinned to one commit, so neither agent can change the code it runs.
FROM node:22-bookworm-slim@sha256:e9f565d32859f0cbfb52125eafe8be39390f24dac302dc3cdf566e8ba3ab21ee
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build
USER node
EXPOSE 3100
CMD ["npx", "next", "start", "-p", "3100", "-H", "0.0.0.0"]
