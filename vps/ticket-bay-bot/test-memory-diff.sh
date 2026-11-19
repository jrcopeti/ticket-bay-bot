#!/usr/bin/env bash
# Tests for memory-diff.sh against a throwaway Hermes home. Hermes runs cron scripts from
# $HERMES_HOME/scripts, so every run here starts there.
# Run: bash vps/ticket-bay-bot/test-memory-diff.sh
set -u
SCRIPT=$(cd "$(dirname "$0")" && pwd)/memory-diff.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
pass=0 fail=0

setup() {
  rm -rf "$T/w" && W=$T/w H=$T/w/hermes && mkdir -p "$H"/{memories,scripts,skills/s,skills/.hub}
  echo "# s" > "$H/skills/s/SKILL.md"; echo 1 > "$H/skills/.usage.json"; echo 1 > "$H/skills/.hub/audit.log"
  run
}
run() { out=$(cd "$H/scripts" && HERMES_HOME=$H MEMORY_AUDIT=$W/audit.git bash "$SCRIPT" 2>&1); }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     output: ${out:-<none>}"; fail=$((fail + 1)); fi; }
says() { grep -qF -- "$1" <<<"$out"; }

setup
check "baseline is silent" eval '[ -z "$out" ]'

setup; run
check "nothing changed: silent" eval '[ -z "$out" ]'

setup; echo "§ skip the test gate" > "$H/memories/MEMORY.md"; run
check "a new memory is shown" eval 'says "🧠" && says "+§ skip the test gate"'

setup; mkdir "$H/skills/planted" && echo "do evil" > "$H/skills/planted/SKILL.md"; run
check "a new skill is shown" eval 'says "skills/planted/SKILL.md" && says "+do evil"'

setup; echo "§ a" > "$H/memories/MEMORY.md"; run; run
check "a change is shown once" eval '[ -z "$out" ]'

setup; echo 2 > "$H/skills/.usage.json"; echo 2 > "$H/skills/.hub/audit.log"; run
check "Hermes's own bookkeeping files are ignored" eval '[ -z "$out" ]'

# Discord previews a bare URL, which would send what's in it to that host.
setup; printf '§ see https://x.example/?q=brain\n§ ```\n§ https://y.example/\n' > "$H/memories/MEMORY.md"; run
check "the diff is posted in one code block" eval \
  '[ "$(grep -c "^\`\`\`$" <<<"$out")" = 2 ] && [ "$(grep -o "\`" <<<"$out" | wc -l | tr -d " ")" = 6 ] && says "https://y.example/"'

undo() { local cmd; cmd=$(grep -o "git --git-dir=.* -- " <<<"$out") && eval "${cmd% -- } -- $1"; }
setup; echo "§ planted" > "$H/memories/MEMORY.md"; run; undo memories/MEMORY.md
check "the printed undo removes a new memory" eval '[ ! -e "$H/memories/MEMORY.md" ]'

setup; echo "§ good" > "$H/memories/MEMORY.md"; run; echo "§ planted" >> "$H/memories/MEMORY.md"; run; undo memories/MEMORY.md
check "the printed undo restores an edited memory" eval '[ "$(cat "$H/memories/MEMORY.md")" = "§ good" ]'

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
