#!/usr/bin/env bash
# Tests for squid-denials.sh against a fake squid log.
# Run: bash vps/ticket-bay-bot/test-squid-denials.sh
set -u
SCRIPT=$(cd "$(dirname "$0")" && pwd)/squid-denials.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0

ok_line='1763470000.100 120 192.0.2.3 TCP_TUNNEL/200 5120 CONNECT api.github.com:443 - HIER_DIRECT/198.51.100.6 -'
deny() { echo "1763470060.200 0 192.0.2.3 TCP_DENIED/403 3922 CONNECT $1 - HIER_NONE/- text/html" >> "$T/access.log"; }
allow() { echo "$ok_line" >> "$T/access.log"; }
setup() { rm -f "$T/access.log" "$T/seen"; allow; deny old.example:443; run; }
run() { out=$(SQUID_LOG=$T/access.log SQUID_DENIALS_STATE=$T/seen bash "$SCRIPT" 2>&1); }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     output: ${out:-<none>}"; fail=$((fail + 1)); fi; }
says() { grep -qF -- "$1" <<<"$out"; }

setup
check "baseline is silent, old denials included" eval '[ -z "$out" ]'

setup; allow; allow; run
check "allowed requests only: silent" eval '[ -z "$out" ]'

setup; deny cdn-assets.example:443; run
check "a new denial is shown" eval 'says "🚫 squid blocked 1 request" && says "CONNECT \`cdn-assets.example:443\`" && ! says old.example'

setup; echo "1763470060.200 1511 192.0.2.3 TCP_DENIED_ABORTED/403 0 CONNECT hung-up.example:443 - HIER_NONE/- text/html" >> "$T/access.log"; run
check "a denial the client hung up on is shown" eval 'says "hung-up.example:443"'

setup; deny cdn-assets.example:443; run; run
check "a denial is shown once" eval '[ -z "$out" ]'

setup; echo "1763470120.300 0 192.0.2.3 TCP_DENIED/403 3900 GET http://plain.example/x?d=abc - HIER_NONE/- text/html" >> "$T/access.log"; run
check "a plain-HTTP URL is shown in a code span, so Discord doesn't fetch it" eval 'says "GET \`http://plain.example/x?d=abc\`"'

setup; echo "1763470120.300 0 192.0.2.3 TCP_DENIED/403 3900 GET http://x.example/\`@everyone\` - HIER_NONE/- text/html" >> "$T/access.log"; run
check "backticks in a URL can't close the code span" eval 'says "GET \`http://x.example/@everyone\`"'

setup; printf '%s' "1763470060.200 0 192.0.2.3 TCP_DENIED/403 3922 CONNECT half.example:443" >> "$T/access.log"; run
check "a line still being written is left for the next run" eval '[ -z "$out" ]'
echo " - HIER_NONE/- text/html" >> "$T/access.log"; run
check "and shown once it's complete" eval 'says "half.example:443"'

setup; : > "$T/access.log"; deny after-restart.example:443; run
check "a recreated log is read from the start" eval 'says "after-restart.example:443"'

setup; : > "$T/access.log"; allow; allow; allow; deny long-again.example:443; run
check "a recreated log already longer than the old one is read from the start" eval 'says "long-again.example:443"'

setup; for i in $(seq 1 25); do deny "h$i.example:443"; done; run
check "a burst is cut at 20 lines" eval 'says "blocked 25 request" && says "… and 5 more" && ! says "h21.example"'

setup; rm "$T/access.log"; run
check "an unreadable log is reported" eval 'says "⚠️ squid-denials: can'"'"'t read"'

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
