#!/usr/bin/env bash
# Hermes pre_verify gate for Tania (course M8: the stop signal it cannot fake).
# Fires when the agent edited code and wants to finish. If the edit is inside a task
# worktree (~/dev/wt/<WT>) of a repo with an `npm run test:unit` script, run that suite
# in the sandbox container. Red -> keep the agent going with the failure tail
# (Hermes caps this at agent.max_verify_nudges, default 3) and keep the worktree.
# Green -> remove the worktree (the branch and the PR stay): the gate owns that cleanup,
# so the worktree still exists when the gate runs. Out of scope -> silent.
# Every run is logged to ~/.hermes/logs/verify-tests.log.
export DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/$(id -u)/docker.sock}"
LOG="$HOME/.hermes/logs/verify-tests.log"
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }
payload=$(cat)
# Without jq the gate reads no changed path and skips the tests: send the agent back instead
# (plain JSON, no jq needed; Hermes caps the nudges at agent.max_verify_nudges).
command -v jq >/dev/null || { log "unit tests NOT run: jq is missing"; echo '{"action": "continue", "message": "verify-tests: jq is missing on the host: install it (see the setup guide). The unit tests did not run. Tell the human, and do not say the tests pass."}'; exit 0; }
# Only edited SOURCE files count; review notes (.pr-review/) and docs do not.
path=$(jq -r '[.extra.changed_paths[]? | select(test("/\\.pr-review/") | not) | select(test("\\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|java|cs|php|rb)$"))][0] // empty' <<<"$payload")
[ -z "$path" ] && exit 0
path=${path/#\/workspace\/dev/\/home\/ticket-bay-bot\/dev}
case "$path" in /home/ticket-bay-bot/dev/wt/*/*) ;; *) exit 0 ;; esac
wt=$(cut -d/ -f1-6 <<<"$path")   # /home/ticket-bay-bot/dev/wt/<WT>
attempt=$(jq -r '.extra.attempt // 0' <<<"$payload")
# Exit 1 = Hermes logs a WARNING with this text (agent.log, errors.log) and lets the agent finish.
fail() { log "$wt: unit tests NOT run: $1"; echo "verify-tests: $wt: unit tests NOT run: $1" >&2; exit 1; }
[ -d "$wt" ] || fail "the worktree is gone (removed before the final answer?)"
root=$(git -C "$wt" rev-parse --show-toplevel 2>/dev/null) || fail "host git cannot read it (git >= 2.48?)"
jq -e '.scripts["test:unit"]' "$root/package.json" >/dev/null 2>&1 || exit 0
box=$(docker ps -q --filter name=hermes- | head -1)
[ -z "$box" ] && fail "no running sandbox container"
out=$(docker exec "$box" sh -c "cd '$root' && npm run test:unit 2>&1" 2>&1)
if [ $? -eq 0 ]; then
  log "$root: unit tests run: GREEN (attempt $attempt)"
  main=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir)
  git -C "${main%/.git}" worktree remove --force "$root" >/dev/null 2>&1 \
    && log "$root: worktree removed" || log "$root: worktree NOT removed"
  exit 0
fi
log "$root: unit tests run: RED (attempt $attempt), agent sent back"
jq -n --arg t "$(tail -c 2500 <<<"$out")" \
  '{action: "continue", message: ("The unit tests are RED (npm run test:unit). You may not finish until they pass. This is a bug fix, so the existing tests describe the wanted behavior. Fix the code, not the tests. Commit, and push again if the branch is already pushed. Output tail:\n" + $t)}'
