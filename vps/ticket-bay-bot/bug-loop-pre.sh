#!/usr/bin/env bash
# Host only, runs before each bug-loop agent run (its stdout goes into the prompt).
# Claims the oldest open bug email, writes it to a file the sandbox mounts read-only at /opt/mail,
# posts the picked-up ping, then mints a write token. An empty inbox skips the agent (no model call).
set -euo pipefail
inbox=~/host-tools/support-inbox
out=$(python3 "$inbox" claim-next)
[ -n "$out" ] || { echo '{"wakeAgent": false}'; exit 0; }
id=$(sed -n 's/^claimed //p' <<<"$out")
subject=$(sed -n 's/^subject\t//p' <<<"$out")

find ~/mail -name '*.txt' -mtime +7 -delete
(umask 027; python3 "$inbox" read "$id" > ~/mail/"$id".txt)

# Subject only, cut to 100 characters; the webhook stays outside the sandbox.
if [ -s ~/.config/agent-notify/webhook ]; then
  jq -n --arg s "${subject:0:100}" '{content: ("🎫 Picked up a bug report: " + $s + ". Working on it.")}' |
    curl -fsS -m 10 -H 'Content-Type: application/json' -d @- "$(cat ~/.config/agent-notify/webhook)" >/dev/null ||
    echo "(picked-up ping failed)" >&2
fi

~/.hermes/scripts/mint-gh-token.sh write
echo "EMAIL FILE: /opt/mail/$id.txt"
