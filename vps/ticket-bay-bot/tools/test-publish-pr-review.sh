#!/usr/bin/env bash
# Tests for publish-pr-review against a throwaway folder, with a fake pr-tour renderer.
# Run: bash vps/ticket-bay-bot/tools/test-publish-pr-review.sh
set -u
SCRIPT=$(cd "$(dirname "$0")" && pwd)/publish-pr-review
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0

# The fake renderer writes a page titled after the PR, and fails on a tour marked "fail".
cat > "$T/render.mjs" <<'JS'
import { readFileSync, writeFileSync } from "node:fs";
const [tour, , out] = process.argv.slice(2);
const t = JSON.parse(readFileSync(tour, "utf8"));
if (t.fail) { console.error("render failed"); process.exit(1); }
writeFileSync(out, `<title>PR ${t.pr?.number}</title>`);
JS

setup() {
  rm -rf "$T/w" && W=$T/w && mkdir -p "$W/out" "$W/wt/.pr-review"
  echo '<title>queue</title>' > "$W/wt/.pr-review/review.html"
  # Yesterday's run: a tour for PR 7, and an index that links it.
  echo '<title>PR 7</title>' > "$W/out/ticket-bay-pr-7.html"
  echo 'yesterday' > "$W/out/index.html"
}
tour() { echo "$2" > "$W/wt/.pr-review/tour-$1.json"; }
run() { out=$(PR_REVIEW_OUT=$W/out PR_TOUR_RENDER=$T/render.mjs bash "$SCRIPT" "$W/wt" ticket-bay 2026-11-23 2>&1); code=$?; }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     output: ${out:-<none>}"; fail=$((fail + 1)); fi; }
says() { grep -qF -- "$1" <<<"$out"; }
yesterday_kept() { [ -f "$W/out/ticket-bay-pr-7.html" ] && [ "$(cat "$W/out/index.html")" = yesterday ]; }

setup; tour 8 '{"pr":{"number":8}}'; tour 9 '{"pr":{"number":9}}'; tour 9.notes '{"notes":1}'; run
check "a tour page per open PR, and the index links them" eval '[ $code = 0 ] && [ -f "$W/out/ticket-bay-pr-8.html" ] && [ -f "$W/out/ticket-bay-pr-9.html" ] && grep -q "ticket-bay-pr-9.html" "$W/out/index.html"'
check "a closed PR's tour is gone" eval '[ ! -e "$W/out/ticket-bay-pr-7.html" ]'
check "the queue is published" eval '[ -f "$W/out/ticket-bay-2026-11-23.html" ] && [ -f "$W/out/ticket-bay-latest.html" ]'

setup; tour 8 '{"pr":{"number":8}}'; tour 9 '{"pr":{"number":9},"fail":true}'; run
check "a failed render exits non-zero" eval '[ $code != 0 ]'
check "a failed render keeps yesterday's tours and index" yesterday_kept

setup; tour x '{"pr":{}}'; run
check "a tour with no PR number fails and says so" eval '[ $code != 0 ] && says "no PR number"'
check "no -pr-null page is written" eval '[ ! -e "$W/out/ticket-bay-pr-null.html" ]'
check "a tour with no PR number keeps yesterday's tours and index" yesterday_kept

setup; tour a '{"pr":{"number":8}}'; tour b '{"pr":{"number":8}}'; run
check "two tours for one PR fail instead of overwriting" eval '[ $code != 0 ] && says "two tours for PR 8"'

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
