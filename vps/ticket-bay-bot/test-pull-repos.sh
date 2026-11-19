#!/usr/bin/env bash
# Tests for pull-repos.sh against a throwaway home. The bot's sandbox can write ~/dev, so nothing the
# host runs may come from a .git folder in there. Run: bash vps/ticket-bay-bot/test-pull-repos.sh
set -u
SCRIPT=$(cd "$(dirname "$0")" && pwd)/pull-repos.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@localhost GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@localhost
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
pass=0 fail=0

setup() {
  rm -rf "$T/w" && W=$T/w && mkdir -p "$W/home/.hermes/scripts" "$W/home/dev"
  printf '#!/bin/sh\necho memory-diff ran\n' > "$W/home/.hermes/scripts/memory-diff.sh"
  chmod +x "$W/home/.hermes/scripts/memory-diff.sh"
  git init -q -b main "$W/seed" && echo a > "$W/seed/a" && git -C "$W/seed" add -A && git -C "$W/seed" commit -qm seed
  git clone -q "$W/seed" "$W/home/dev/ticket-bay"
  echo b > "$W/seed/b" && git -C "$W/seed" add -A && git -C "$W/seed" commit -qm upstream
}
run() { out=$(HOME=$W/home bash "$SCRIPT" 2>&1); }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     output: ${out:-<none>}"; fail=$((fail + 1)); fi; }
says() { grep -qF -- "$1" <<<"$out"; }

setup; R=$W/home/dev/ticket-bay
for h in post-merge post-checkout reference-transaction; do
  printf '#!/bin/sh\ntouch %s/hook-ran\n' "$W" > "$R/.git/hooks/$h" && chmod +x "$R/.git/hooks/$h"
done
git -C "$R" config core.fsmonitor "touch $W/fsmonitor-ran"
run
check "nothing planted in the clone's .git runs on the host" eval '[ ! -e "$W/hook-ran" ] && [ ! -e "$W/fsmonitor-ran" ]'

setup; run
check "memory-diff still runs" says "memory-diff ran"

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
