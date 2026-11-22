#!/usr/bin/env bash
# Tests for revoke-gh-token.sh with a fake curl that records the request and answers $FAKE_CODE.
# Run: bash vps/ticket-bay-bot/test-revoke-gh-token.sh
set -u
SCRIPT=$(cd "$(dirname "$0")" && pwd)/revoke-gh-token.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
mkdir -p "$T/bin"
cat > "$T/bin/curl" <<'SH'
#!/usr/bin/env bash
{ echo "argv: $*"; echo "stdin: $(cat)"; } > "$T/req"
printf '%s' "${FAKE_CODE:-204}"
SH
chmod +x "$T/bin/curl"

setup() { rm -f "$T/req"; printf 'github.com:\n    oauth_token: ghs_secret123\n    user: ticket-bay-bot[bot]\n' > "$T/hosts.yml"; }
run() { out=$(printf '%s' "$1" | PATH=$T/bin:$PATH T=$T GH_HOSTS=$T/hosts.yml bash "$SCRIPT" 2>&1); rc=$?; }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     output: ${out:-<none>} (exit $rc)"; fail=$((fail + 1)); fi; }
cron='{"hook_event_name":"on_session_end","session_id":"s","extra":{"platform":"cron"}}'

setup; run "$cron"
check "a cron run's token is revoked" eval 'grep -q "DELETE" "$T/req" && grep -q "installation/token" "$T/req" && grep -q "stdin: Authorization: token ghs_secret123" "$T/req" && [ $rc = 0 ]'
check "the gh login is emptied" eval '[ ! -s "$T/hosts.yml" ]'
check "the token is not in curl's argv" eval '! grep "^argv:" "$T/req" | grep -q ghs_secret123'

setup; run '{"hook_event_name":"on_session_end","extra":{"platform":"discord"}}'
check "a chat turn leaves the token alone" eval '[ ! -e "$T/req" ] && grep -q ghs_secret123 "$T/hosts.yml" && [ $rc = 0 ]'

setup; run 'not json'
check "a payload it can't read leaves the token alone" eval '[ ! -e "$T/req" ] && [ $rc = 0 ]'

setup; : > "$T/hosts.yml"; run "$cron"
check "no token: nothing sent" eval '[ ! -e "$T/req" ] && [ $rc = 0 ]'

setup; FAKE_CODE=500 run "$cron"
check "a failed revoke still empties the login and warns" eval '[ ! -s "$T/hosts.yml" ] && [ $rc = 1 ] && grep -q "answered 500" <<<"$out"'

setup; FAKE_CODE=401 run "$cron"
check "an already-dead token is fine" eval '[ ! -s "$T/hosts.yml" ] && [ $rc = 0 ]'

setup; ino=$(ls -i "$T/hosts.yml" | awk "{print \$1}"); run "$cron"
check "the file is truncated in place, not replaced" eval '[ "$(ls -i "$T/hosts.yml" | awk "{print \$1}")" = "$ino" ]'

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
