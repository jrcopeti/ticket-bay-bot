#!/usr/bin/env bash
# Hermes on_session_end hook, host only: when a cron run (bug-loop, PR triage) ends, revoke the token
# mint-gh-token.sh wrote and empty the gh login, so a token the run leaked (a PR body, a log) is dead
# minutes later, not within the hour. Chats are skipped: a chat turn ending mid-run would kill the
# running job's token. `--now` skips the payload check (the pre-scripts and the mint call it).
# Exit 1 = Hermes logs a WARNING with the message.
set -u
export LC_ALL=C  # the token check below means ASCII, whatever the caller's locale
f=$HOME/.config/gh/hosts.yml
keep=$HOME/.config/github-app/unrevoked-tokens
if [ "${1:-}" != --now ]; then
  command -v jq >/dev/null || { echo "revoke-gh-token: jq is missing; the token lives its hour" >&2; exit 1; }
  [ "$(jq -r '.extra.platform // empty' 2>/dev/null)" = cron ] || exit 0
fi
token=$(sed -n 's/^ *oauth_token: *//p' "$f" 2>/dev/null | head -1 | sed 's/[[:space:]]#.*//' | tr -d "\"'\r \t")
[ -n "$token" ] || exit 0

# Keep a token we couldn't revoke where only the host can read it, tell the owner, and empty the login.
give_up() {
  (umask 077; printf '%s %s\n' "$(date -u +%FT%TZ)" "$token" >> "$keep")
  : > "$f"
  local msg="revoke-gh-token: $1; login emptied, token kept in ~/.config/github-app/unrevoked-tokens"
  echo "$msg" >&2
  if [ -s ~/.config/agent-notify/webhook ]; then
    jq -n --arg m "⚠️ ${msg#revoke-gh-token: }" '{content: $m}' |
      curl -fsS -m 10 -H 'Content-Type: application/json' -d @- "$(cat ~/.config/agent-notify/webhook)" >/dev/null 2>&1
  fi
  exit 1
}
# Only an App installation token: then a 401 means it's already dead, not that we sent the wrong thing.
# The characters GitHub uses, no wider: newer tokens are about 390 long and carry '.' and '-'. A value
# with anything else (a glued comment, a stray ',') would get a 401 and pass for revoked. A future
# format fails closed: kept host-side and the owner pinged, not counted as revoked.
[[ $token =~ ^ghs_[A-Za-z0-9_.-]+$ ]] || give_up "the login holds a token that doesn't look like an App token"
# The token goes in on stdin, not argv, where other processes could read it.
code=$(printf 'Authorization: token %s\n' "$token" | curl -sS -m 10 -o /dev/null -w '%{http_code}' \
  -X DELETE -H @- -H 'Accept: application/vnd.github+json' https://api.github.com/installation/token)
case $code in
  # Truncated in place, so the change reaches the sandbox however the file is mounted. 401: already dead.
  204|401) : > "$f"; exit 0 ;;
  *) give_up "GitHub answered ${code:-nothing}" ;;
esac
