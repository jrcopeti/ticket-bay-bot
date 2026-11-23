#!/usr/bin/env bash
# Tests for revoke-gh-token.sh and pr-triage-pre.sh's revoke, against a throwaway home and a fake curl
# that records the request and answers $FAKE_CODE. Run: bash vps/ticket-bay-bot/test-revoke-gh-token.sh
set -u
D=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
mkdir -p "$T/bin"
cat > "$T/bin/curl" <<'SH'
#!/usr/bin/env bash
# The webhook ping posts to a URL; the revoke asks for a status code.
case "$*" in *hooks.example*) cat > "$T/ping"; exit 0 ;; esac
{ echo "argv: $*"; echo "stdin: $(cat)"; } > "$T/req"
printf '%s' "${FAKE_CODE:-204}"
SH
cat > "$T/bin/gh" <<'SH'
#!/usr/bin/env bash
[ -n "${FAKE_GH_FAIL:-}" ] && exit 1
echo "${FAKE_OPEN:-0}"
SH
chmod +x "$T/bin/curl" "$T/bin/gh"

setup() {
  rm -rf "$T/home" "$T/req" "$T/ping"; H=$T/home
  mkdir -p "$H/.config/gh" "$H/.config/github-app" "$H/.config/agent-notify" "$H/.hermes/scripts" "$H/.hermes/agent-hooks"
  echo https://hooks.example/x > "$H/.config/agent-notify/webhook"
  printf 'github.com:\n    oauth_token: ghs_secret123\n    user: ticket-bay-bot[bot]\n' > "$H/.config/gh/hosts.yml"
  cp "$D/revoke-gh-token.sh" "$H/.hermes/agent-hooks/" && printf '#!/bin/sh\n' > "$H/.hermes/scripts/mint-gh-token.sh"
  chmod +x "$H/.hermes/scripts/mint-gh-token.sh"
}
run() { out=$(printf '%s' "$1" | HOME=$H PATH=$T/bin:$PATH T=$T bash "$D/revoke-gh-token.sh" 2>&1); rc=$?; }
pre() { out=$(HOME=$H PATH=$T/bin:$PATH T=$T bash "$D/pr-triage-pre.sh" 2>&1); rc=$?; }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     output: ${out:-<none>} (exit $rc)"; fail=$((fail + 1)); fi; }
hosts=$T/home/.config/gh/hosts.yml
cron='{"hook_event_name":"on_session_end","session_id":"s","extra":{"platform":"cron"}}'

setup; run "$cron"
check "a cron run's token is revoked" eval 'grep -q "DELETE" "$T/req" && grep -q "https://api.github.com/installation/token" "$T/req" && grep -q "stdin: Authorization: token ghs_secret123$" "$T/req" && [ $rc = 0 ]'
check "the gh login is emptied" eval '[ ! -s "$hosts" ]'
check "the token is not in curl's argv" eval '! grep "^argv:" "$T/req" | grep -q ghs_secret123'

setup; run '{"hook_event_name":"on_session_end","extra":{"platform":"discord"}}'
check "a chat turn leaves the token alone" eval '[ ! -e "$T/req" ] && grep -q ghs_secret123 "$hosts" && [ $rc = 0 ]'

setup; run 'not json'
check "a payload it can't read leaves the token alone" eval '[ ! -e "$T/req" ] && [ $rc = 0 ]'

setup; : > "$hosts"; run "$cron"
check "no token: nothing sent" eval '[ ! -e "$T/req" ] && [ $rc = 0 ]'

setup; printf 'github.com:\n    oauth_token: "ghs_secret123"\nusers:\n    x:\n        oauth_token: ghs_other\n' > "$hosts"; run "$cron"
check "quotes stripped, first token only" eval 'grep -q "stdin: Authorization: token ghs_secret123$" "$T/req"'

setup; printf 'github.com:\n    oauth_token: ghs_secret123   # note\n' > "$hosts"; run "$cron"
check "trailing spaces and a comment are stripped" eval 'grep -q "stdin: Authorization: token ghs_secret123$" "$T/req"'

# GitHub's newer App tokens are about 390 characters and carry '.' and '-' (seen 2026-11-23).
# Built here, never written out: the shape seen on the VPS, 390 characters with dots and dashes.
seg=$(printf 'aB3-x_Y9%.0s' {1..16}); long=ghs_$seg.$seg.$seg
setup; printf 'github.com:\n    oauth_token: %s\n' "$long" > "$hosts"; run "$cron"
check "a long App token with '.' and '-' is revoked" eval '[ ${#long} = 390 ] && grep -qxF "stdin: Authorization: token $long" "$T/req" && [ ! -s "$hosts" ] && [ $rc = 0 ]'

setup; printf 'github.com:\n    oauth_token: gho_usertoken\n' > "$hosts"; run "$cron"
check "a token that isn't the App's is kept host-side, not sent" eval '[ ! -e "$T/req" ] && [ ! -s "$hosts" ] && [ $rc = 1 ] && grep -q gho_usertoken "$H/.config/github-app/unrevoked-tokens"'

for c in 500 000; do
  setup; FAKE_CODE=$c run "$cron"
  check "revoke fails ($c): login emptied, token kept host-side, owner pinged" eval '[ ! -s "$hosts" ] && grep -q " ghs_secret123$" "$H/.config/github-app/unrevoked-tokens" && [ $rc = 1 ] && grep -q "answered $c" <<<"$out" && grep -q "answered $c" "$T/ping"'
done

setup; FAKE_CODE=500 run "$cron"; printf 'github.com:\n    oauth_token: ghs_second\n' > "$hosts"; FAKE_CODE=500 run "$cron"
check "a second failed revoke keeps the first token too" eval '[ "$(grep -c ghs_ "$H/.config/github-app/unrevoked-tokens")" = 2 ]'

setup; FAKE_CODE=401 run "$cron"
check "an already-dead token is fine" eval '[ ! -s "$hosts" ] && [ $rc = 0 ]'

setup; ino=$(ls -i "$hosts" | awk "{print \$1}"); run "$cron"
check "the file is truncated in place, not replaced" eval '[ "$(ls -i "$hosts" | awk "{print \$1}")" = "$ino" ]'

setup; FAKE_OPEN=0 pre
check "triage with no open PR skips the agent and revokes" eval 'grep -q wakeAgent <<<"$out" && grep -q DELETE "$T/req" && [ ! -s "$hosts" ]'

setup; printf '#!/bin/sh\nexit 1\n' > "$H/.hermes/scripts/mint-gh-token.sh"; pre
check "triage with a failed mint still revokes what's there" eval '[ $rc != 0 ] && grep -q DELETE "$T/req"'

setup; FAKE_GH_FAIL=1 pre
check "triage failing after the mint still revokes" eval '[ $rc != 0 ] && grep -q DELETE "$T/req"'

setup; FAKE_OPEN=2 pre
check "triage with open PRs keeps the token for the agent" eval 'grep -q "OPEN PULL REQUESTS: 2" <<<"$out" && [ ! -e "$T/req" ] && grep -q ghs_secret123 "$hosts"'

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
