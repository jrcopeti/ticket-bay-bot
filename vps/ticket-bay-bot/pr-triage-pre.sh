#!/usr/bin/env bash
# Host only, runs before each pr-triage agent run: a read-only 1-hour token is all triage needs.
# No open PR skips the agent (no model call).
set -euo pipefail
~/.hermes/scripts/mint-gh-token.sh read
# A run that doesn't wake the agent ends no session, so the revoke hook wouldn't fire: revoke on
# every exit here (no PR, or gh failing) unless the agent wakes.
trap '~/.hermes/agent-hooks/revoke-gh-token.sh --now || true' EXIT
open=$(gh pr list --repo jrcopeti/ticket-bay --state open --json number --jq length)
# Hermes skips the agent when the script prints nothing, so say what is waiting.
if [ "$open" -gt 0 ]; then trap - EXIT; echo "OPEN PULL REQUESTS: $open"; exit 0; fi
echo '{"wakeAgent": false}'
