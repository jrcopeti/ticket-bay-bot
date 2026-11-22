#!/usr/bin/env bash
# Hermes on_session_end hook, host only: when a cron run (bug-loop, PR triage) ends, empty the gh
# login mint-gh-token.sh wrote and revoke its token, so a token the run leaked (a PR body, a log) is
# dead minutes later, not within the hour. Chats are skipped: a chat turn ending mid-run would kill
# the running job's token. Exit 1 = Hermes logs a WARNING with the message.
set -u
f=${GH_HOSTS:-$HOME/.config/gh/hosts.yml}
command -v jq >/dev/null || { echo "revoke-gh-token: jq is missing; the token lives its hour" >&2; exit 1; }
[ "$(jq -r '.extra.platform // empty' 2>/dev/null)" = cron ] || exit 0
token=$(sed -n 's/^ *oauth_token: *//p' "$f" 2>/dev/null)
[ -n "$token" ] || exit 0
# Truncated in place, so the change reaches the sandbox however the file is mounted.
: > "$f"
# The token goes in on stdin, not argv, where other processes could read it.
code=$(printf 'Authorization: token %s\n' "$token" | curl -sS -m 10 -o /dev/null -w '%{http_code}' \
  -X DELETE -H @- -H 'Accept: application/vnd.github+json' "${GH_API:-https://api.github.com}/installation/token")
# 401: the token was already dead.
case $code in 204|401) exit 0 ;; esac
echo "revoke-gh-token: GitHub answered ${code:-nothing}; the login is emptied, the token lives its hour" >&2
exit 1
