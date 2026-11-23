#!/usr/bin/env bash
# Plants one demo bug on the fork's main through a PR the owner merges. Runs on the local machine.
# The patches stack: plant them in order, each after the one before it is merged.
# Usage: demo-bugs/plant.sh <fork-clone> <bug>   e.g. demo-bugs/plant.sh ~/code/ticket-bay 01-group-of-ten
set -euo pipefail
pack=$(cd "$(dirname "$0")" && pwd)
fork=${1:?usage: plant.sh <fork-clone> <bug>}
bug=${2:?usage: plant.sh <fork-clone> <bug>}
patch=$pack/$bug/plant.patch
[ -f "$patch" ] || { echo "no such bug: $bug (one of: $(cd "$pack" && ls -d [0-9]*/ | tr -d / | xargs))" >&2; exit 2; }
slug=${bug#[0-9][0-9]-}
branch=demo/plant-$slug

# A worktree off origin/main, so the owner's checkout and its uncommitted work are never touched.
git -C "$fork" fetch -q origin main
wt=$(mktemp -d)
trap 'git -C "$fork" worktree remove --force "$wt" 2>/dev/null || true' EXIT
git -C "$fork" worktree add -q -b "$branch" "$wt" origin/main
if ! git -C "$wt" apply --index "$patch"; then
  git -C "$fork" worktree remove --force "$wt"; git -C "$fork" branch -q -D "$branch"
  echo "$bug does not apply to main: plant the bugs before it first, or it is planted already" >&2
  exit 1
fi
git -C "$wt" commit -q -m "demo: plant $slug"
git -C "$wt" push -q -u origin "$branch"

body="Plants demo bug \`$bug\` from the ticket-bay-bot demo-bug pack (jrcopeti/ticket-bay-bot, \`demo-bugs/\`).

One small mistake in \`src/domain/\`, with the tests that would catch it removed or loosened, so the suite stays green.
The customer email in the pack reports it; the bot fixes it in its own PR.

The mutation check fails here by design: the mutant that survives is the fix. Merge with the ruleset bypass."
(cd "$wt" && gh pr create --base main --head "$branch" --title "demo: plant $slug" --body "$body")
