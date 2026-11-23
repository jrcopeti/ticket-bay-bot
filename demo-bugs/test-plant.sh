#!/usr/bin/env bash
# Tests for plant.sh against a throwaway fork with a stub gh. Run: bash demo-bugs/test-plant.sh
set -u
PACK=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@localhost GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@localhost
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
pass=0 fail=0

# A fake pack beside the real script, so the tests don't depend on the fork's code.
P=$T/pack && mkdir -p "$P/01-one" "$P/02-two" "$T/bin"
cp "$PACK/plant.sh" "$P/"
printf 'diff --git a/a b/a\n--- a/a\n+++ b/a\n@@ -1 +1 @@\n-a\n+one\n' > "$P/01-one/plant.patch"
printf 'diff --git a/a b/a\n--- a/a\n+++ b/a\n@@ -1 +1 @@\n-one\n+two\n' > "$P/02-two/plant.patch"
printf '#!/bin/sh\necho "gh $*" >> "%s/gh.log"\n' "$T" > "$T/bin/gh" && chmod +x "$T/bin/gh"

git init -q --bare -b main "$T/origin.git"
git clone -q "$T/origin.git" "$T/fork" 2>/dev/null
echo a > "$T/fork/a" && git -C "$T/fork" add -A && git -C "$T/fork" commit -qm seed && git -C "$T/fork" push -q origin main
echo "owner's work" > "$T/fork/wip"

run() { out=$(PATH=$T/bin:$PATH bash "$P/plant.sh" "$T/fork" "$1" 2>&1); code=$?; }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     output: ${out:-<none>}"; fail=$((fail + 1)); fi; }
says() { grep -qF -- "$1" <<<"$out"; }

run 09-nope
check "refuses an unknown bug and lists the real ones" eval '[ $code = 2 ] && says "one of: 01-one 02-two"'

run 02-two
check "refuses a bug whose earlier bug isn't on main" eval '[ $code = 1 ] && says "plant the bugs before it first"'
check "leaves no branch behind after a refusal" eval '! git -C "$T/fork" rev-parse -q --verify demo/plant-two >/dev/null'

run 01-one
check "pushes the planted branch" eval '[ $code = 0 ] && [ "$(git -C "$T/origin.git" show demo/plant-one:a)" = one ]'
check "opens the PR into main" grep -qF -- "gh pr create --base main --head demo/plant-one --title demo: plant one" "$T/gh.log"
check "leaves the owner's checkout and its work alone" eval '[ "$(cat "$T/fork/a")" = a ] && [ -f "$T/fork/wip" ] && [ "$(git -C "$T/fork" branch --show-current)" = main ]'
check "removes its worktree" eval '[ "$(git -C "$T/fork" worktree list | wc -l)" -eq 1 ]'

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
