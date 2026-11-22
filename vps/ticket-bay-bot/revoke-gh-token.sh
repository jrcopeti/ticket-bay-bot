#!/usr/bin/env bash
# Hermes on_session_end hook, host only: when a cron run (bug-loop, PR triage) ends, revoke the token
# mint-gh-token.sh wrote and empty the gh login, so a token the run leaked (a PR body, a log) is dead
# minutes later, not within the hour. Chats are skipped: a chat turn ending mid-run would kill the
# running job's token. `--now` skips the payload check (pr-triage-pre.sh, when it skips the agent).
# Exit 1 = Hermes logs a WARNING with the message.
set -u
f=$HOME/.config/gh/hosts.yml
if [ "${1:-}" != --now ]; then
  command -v jq >/dev/null || { echo "revoke-gh-token: jq is missing; the token lives its hour" >&2; exit 1; }
  [ "$(jq -r '.extra.platform // empty' 2>/dev/null)" = cron ] || exit 0
fi
token=$(sed -n 's/^ *oauth_token: *//p' "$f" 2>/dev/null | head -1 | tr -d "\"'\r")
[ -n "$token" ] || exit 0
# Only an App installation token: then a 401 means it's already dead, not that we sent the wrong thing.
[[ $token =~ ^ghs_[A-Za-z0-9]+$ ]] || { : > "$f"; echo "revoke-gh-token: the login holds no App token; emptied, nothing revoked" >&2; exit 1; }
# The token goes in on stdin, not argv, where other processes could read it.
code=$(printf 'Authorization: token %s\n' "$token" | curl -sS -m 10 -o /dev/null -w '%{http_code}' \
  -X DELETE -H @- -H 'Accept: application/vnd.github+json' https://api.github.com/installation/token)
# Truncated in place, so the change reaches the sandbox however the file is mounted.
: > "$f"
case $code in 204|401) exit 0 ;; esac
# Keep the live token where only the host can read it, so the owner can still revoke it by hand.
(umask 077; printf '%s\n' "$token" > "$HOME/.config/github-app/unrevoked-token")
echo "revoke-gh-token: GitHub answered ${code:-nothing}; login emptied, token kept in ~/.config/github-app/unrevoked-token" >&2
exit 1
