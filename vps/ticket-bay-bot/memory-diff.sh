#!/usr/bin/env bash
# Hourly, as its own Hermes no-agent job (no model): print what the bot saved to its memory or
# skills since the last run. Memory and skill_manage stay on so it learns; this is how the owner sees what
# it saved, and undoes a bad entry with the restore line it prints.
# The snapshot repo is outside the sandbox's mounts.
# Silent when nothing changed. The first run only takes the baseline.
set -u
H=${HERMES_HOME:-$HOME/.hermes}
A=${MEMORY_AUDIT:-$HOME/.memory-audit.git}
MAX=1500
# Hermes starts scripts in $H/scripts, inside the work tree, where the pathspecs below would miss.
cd "$H" || { echo "⚠️ memory-diff: no $H"; exit 0; }
g() { git --git-dir="$A" --work-tree="$H" -c core.hooksPath=/dev/null -c core.quotePath=false "$@"; }

if [ ! -d "$A" ]; then
  git init -q --bare "$A" && g config core.bare false
  printf '%s\n' /skills/.usage.json /skills/.usage.json.lock /skills/.curator_state /skills/.bundled_manifest /skills/.hub/audit.log > "$A/info/exclude"
  out=$(g add -A -- memories skills 2>&1 && g -c user.name=audit -c user.email=audit@localhost commit -qm baseline 2>&1) ||
    echo "⚠️ memory-diff: baseline failed: $out"
  exit 0
fi
# A run killed mid-commit leaves locks (index, HEAD, the branch ref) that would fail every later run.
find "$A" -name '*.lock' -mmin +30 -delete 2>/dev/null
out=$(g add -A -- memories skills 2>&1) || { echo "⚠️ memory-diff: git add failed: $out"; exit 0; }
g diff --cached --quiet && exit 0
d=$(g diff --cached --stat=80 && echo && g diff --cached --unified=1 -- memories skills)
# The undo and full-diff lines name this run's commit: HEAD moves on with the next hourly run.
# Full SHA: a short one can turn ambiguous as the snapshot repo grows.
c=
g -c user.name=audit -c user.email=audit@localhost commit -qm "$(date -u +%FT%H:%MZ)" >/dev/null 2>&1 &&
  c=$(g rev-parse --verify -q HEAD)
if [ -n "$c" ]; then
  rm -f "$A/info/failed-diff"
  echo "🧠 saved to memory or skills since the last check (undo: git --git-dir=$A --work-tree=$H restore --source=$c~1 -- <path>):"
else
  # A commit that keeps failing would repost the same diff every hour: post each one once.
  h=$(printf '%s' "$d" | git hash-object --stdin)
  [ "$(cat "$A/info/failed-diff" 2>/dev/null)" = "$h" ] && exit 0
  echo "$h" > "$A/info/failed-diff"
  echo "⚠️ memory-diff: commit failed, so no undo line"
  echo "🧠 saved to memory or skills since the last check:"
fi
# In a code block, backticks stripped: Discord doesn't preview a URL the agent saved (that would send it).
d=${d//\`/}
echo '```'; echo "${d:0:$MAX}"; echo '```'
[ ${#d} -gt $MAX ] && echo "… cut. Full diff: git --git-dir=$A ${c:+show $c}${c:-diff --cached}"
exit 0
