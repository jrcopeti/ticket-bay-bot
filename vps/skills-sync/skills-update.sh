#!/usr/bin/env bash
# Daily, as skills-sync: move the bot's dmoka/skills checkout to the newest upstream commit first seen
# at least 7 days ago, unless the skills guard finds something in it the current checkout doesn't have.
# The wait counts from our own fetch log, not commit dates, which the committer sets.
# Both trees are scanned whole, as a fresh `git checkout` writes them in a throwaway clone (not
# `git archive`, which honours upstream's export-ignore, nor checkout-index, which reads the current
# checkout's .gitattributes), with caps on bytes and file count so upstream can't fill the disk. The bot's folder is
# then rewritten under the target's attributes, so its bytes are the scanned ones.
# Writes one line to $S/status: "ok" when nothing happened, otherwise what did. pull-repos.sh posts it.
set -uo pipefail
R=${SKILLS_REPO:-/opt/dmoka-skills}
G=${HERMES_GUARD:-/opt/hermes-guard}
S=${SKILLS_STATE:-/var/lib/skills-sync}
DAYS=${SKILLS_COOLDOWN_DAYS:-7}
MAX_MB=${SKILLS_MAX_MB:-50}
MAX_FILES=${SKILLS_MAX_FILES:-5000}
NOW=${SKILLS_NOW:-$(date +%s)}
HERE=$(cd "$(dirname "$0")" && pwd)
g() { git -C "$R" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"; }
status() { echo "$*" > "$S/status.tmp" && mv "$S/status.tmp" "$S/status"; }
# Check commit $2 out into $tmp/$1 from a throwaway clone (no hooks, no templates), then drop its .git.
unpack() {
  git clone -q --shared --no-checkout --template= "$R" "$tmp/$1" &&
    git -C "$tmp/$1" -c core.hooksPath=/dev/null checkout -q --detach "$2" && rm -rf "$tmp/$1/.git"
}

out=$(g fetch -q origin main 2>&1) || { status "⚠️ skills: fetch failed, not updated: $out"; exit 0; }
up=$(g rev-parse FETCH_HEAD)
[ "$up" = "$(tail -n1 "$S/seen" 2>/dev/null | cut -d' ' -f2)" ] || echo "$NOW $up" >> "$S/seen"
# The newest commit seen long enough ago that upstream still has: one force-pushed away is dropped.
target=
for c in $(awk -v t=$((NOW - DAYS * 86400)) '$1 <= t { s[n++] = $2 } END { while (n--) print s[n] }' "$S/seen"); do
  g merge-base --is-ancestor "$c" "$up" 2>/dev/null && { target=$c; break; }
done
cur=$(g rev-parse HEAD)

if [ -z "$target" ] || g merge-base --is-ancestor "$target" "$cur" 2>/dev/null; then status ok; exit 0; fi
g merge-base --is-ancestor "$cur" "$target" ||
  { status "🚫 skills: upstream ${target:0:7} doesn't build on ${cur:0:7} (history rewritten?). Not updated."; exit 0; }

mb=$(g ls-tree -r -l "$target" | awk '{ s += $4 } END { print int(s / 1048576) }')
[ "$mb" -lt "$MAX_MB" ] || { status "🚫 skills: ${target:0:7} is ${mb} MB (cap $MAX_MB), not updated"; exit 0; }
# Each file costs a disk block whatever its size, so tiny blobs under many names count too.
files=$(g ls-tree -r "$target" | wc -l | tr -d ' ')
[ "$files" -le "$MAX_FILES" ] || { status "🚫 skills: ${target:0:7} has $files files (cap $MAX_FILES), not updated"; exit 0; }
tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT
unpack old "$cur" && unpack new "$target" || { status "⚠️ skills: could not unpack ${target:0:7}, not updated"; exit 0; }
new=$(python3 -I "$HERE/scan-diff.py" "$G" "$tmp/old" "$tmp/new")
case $? in
  0) ;;
  1) status "🚫 skills: ${target:0:7} not taken, the skills guard found new: $(tr '\n' ';' <<<"$new")"; exit 0 ;;
  *) status "⚠️ skills: scan failed, not updated: $new"; exit 0 ;;
esac
n=$(g rev-list --count "$cur..$target")
# Emptying the index makes reset --hard write every file, so none keeps bytes an older .gitattributes made.
g checkout -q --detach "$target" && g read-tree --empty && g reset -q --hard ||
  { status "⚠️ skills: checkout of ${target:0:7} failed"; exit 0; }
status "skills updated ${cur:0:7} → ${target:0:7} ($n commits, first seen $DAYS+ days ago)"
