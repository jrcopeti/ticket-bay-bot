#!/usr/bin/env bash
# Daily, as a Hermes no-agent job run from pull-repos.sh: print what the bot saved to its memory or
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
out=$(g add -A -- memories skills 2>&1) || { echo "⚠️ memory-diff: git add failed: $out"; exit 0; }
g diff --cached --quiet && exit 0
d=$(g diff --cached --stat=80 && echo && g diff --cached --unified=1 -- memories skills)
g -c user.name=audit -c user.email=audit@localhost commit -qm "$(date -u +%FT%H:%MZ)" 2>&1 || echo "⚠️ memory-diff: commit failed"
echo "🧠 saved to memory or skills since the last check (undo: git --git-dir=$A --work-tree=$H restore --source=HEAD~1 -- <path>):"
# In a code block, backticks stripped: Discord doesn't preview a URL the agent saved (that would send it).
d=${d//\`/}
echo '```'; echo "${d:0:$MAX}"; echo '```'
[ ${#d} -gt $MAX ] && echo "… cut. Full diff: git --git-dir=$A show HEAD"
exit 0
