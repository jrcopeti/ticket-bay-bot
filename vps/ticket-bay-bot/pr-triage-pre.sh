#!/usr/bin/env bash
# Host only, runs before each pr-triage agent run: a read-only 1-hour token is all triage needs.
# No open PR skips the agent (no model call).
set -euo pipefail
~/.hermes/scripts/mint-gh-token.sh read
open=$(gh pr list --repo jrcopeti/ticket-bay --state open --json number --jq length)
# Hermes skips the agent when the script prints nothing, so say what is waiting.
if [ "$open" -gt 0 ]; then echo "OPEN PULL REQUESTS: $open"; exit 0; fi
# A skipped run ends no session, so the revoke hook wouldn't fire: revoke here.
echo '{"extra": {"platform": "cron"}}' | ~/.hermes/agent-hooks/revoke-gh-token.sh || true
echo '{"wakeAgent": false}'
