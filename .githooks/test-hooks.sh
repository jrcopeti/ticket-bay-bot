#!/usr/bin/env bash
# Tests for the commit hooks (pre-commit, commit-msg) against a throwaway repo that uses them.
# Needs gitleaks and exiftool. Run: bash .githooks/test-hooks.sh
set -u
HOOKS=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
pass=0 fail=0
PNG=iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==

setup() {
  rm -rf "$T/r" && git init -q "$T/r" && cd "$T/r" || exit 1
  git config user.email ci@example.com && git config user.name ci && git config core.hooksPath "$HOOKS"
  cp "$HOOKS/../.gitleaks.toml" . && git add .gitleaks.toml && git commit -qm init >/dev/null 2>&1 || { echo "setup: init commit failed"; exit 1; }
  printf '# private repos\nsecret-repo\n' > .git/info/private-values
}
commit() { git add -A && out=$(git commit -qm "${1:-change}" 2>&1); }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     output: ${out:-<none>}"; fail=$((fail + 1)); fi; }
says() { grep -qF -- "$1" <<<"$out"; }

setup; echo "plain text" > a.md; commit
check "a clean change commits" eval '[ -z "$(git status --porcelain)" ]'

setup; echo "see /Users/someone/notes" > a.md; commit # gitleaks:allow
check "a macOS home path is blocked" eval 'says "leaks found" && [ -n "$(git status --porcelain)" ]'

setup; echo "ssh in, then cd /home/admin" > a.md; commit # gitleaks:allow
check "a Linux home path is blocked" eval 'says "leaks found" && [ -n "$(git status --porcelain)" ]'

setup; echo "see ../../Users/someone/notes" > a.md; commit # gitleaks:allow
check "a relative path into a home is blocked" eval 'says "leaks found" && [ -n "$(git status --porcelain)" ]'

setup; echo "logs in /home/ticket-bay-bot/.hermes, test dirs \$W/home/dev and \${W}/home/dev" > a.md; commit
check "the bot's documented home and test paths commit" eval '[ -z "$(git status --porcelain)" ]'

setup; echo "clone jrcopeti/Secret-Repo" > a.md; commit
check "a private value is blocked, any case" eval 'says "a.md adds a value"'

setup; echo "x" > "notes secret-repo.md"; commit
check "a private value in a file name is blocked" eval 'says "adds a value"'

setup; printf '++secret-repo\n' > a.md; commit
check "a value on a line that starts with ++ is blocked" eval 'says "a.md adds a value"'

setup; printf 'secret-repo  \r\n' > .git/info/private-values; echo "secret-repo" > a.md; commit
check "a list value with trailing space and CRLF still matches" eval 'says "a.md adds a value"'

setup; echo "secret-repo" > "my notes.md"; commit
check "a file name with a space is checked" eval 'says "my notes.md adds a value"'

setup; echo "secret-repo" > a.md; git add a.md && git commit -qm x -n; git rm -q a.md; commit
check "removing a private value commits" eval '[ -z "$(git status --porcelain)" ]'

setup; echo "secret-repo" > a.md; git add a.md && git commit -qm x -n; git rm -q a.md
out=$(GIT_EDITOR=true git commit -q -v -e -m "drop a value" 2>&1)
check "commit -v: the diff below the scissors isn't read as the message" eval '[ -z "$(git status --porcelain)" ]'

setup; echo ok > a.md; commit "fix the secret-repo build"
check "a private value in the commit message is blocked" eval 'says "commit message has a value"'

setup; git checkout -qb side; echo "secret-repo" > a.md; git add a.md && git commit -qm x -n
git checkout -q -; out=$(git merge -q --no-ff side -m merge 2>&1)
check "a merge commit is checked too" eval 'says "a.md adds a value" && ! git log -1 --format=%s | grep -qx merge'

setup; rm .git/info/private-values; echo "secret-repo" > a.md; commit
check "no list: warns and commits" eval 'says "no list at" && [ -z "$(git status --porcelain)" ]'

setup; base64 -d <<<"$PNG" > a.png; commit
check "an image without metadata commits" eval '[ -z "$(git status --porcelain)" ]'

setup; base64 -d <<<"$PNG" > "a b.png"; exiftool -q -overwrite_original -GPSLatitude=52.5 -GPSLatitudeRef=N "a b.png"; commit
check "an image with GPS data is blocked" eval 'says "a b.png has metadata"'

setup; printf 'version https://git-lfs.github.com/spec/v1\n' > a.png; commit
check "an image exiftool can't read is blocked, and says why" eval 'says "can'"'"'t read a.png"'

setup; base64 -d <<<"$PNG" > ./-icon.png; out=$("$HOOKS/image-metadata" -icon.png 2>&1)
check "an image whose name starts with - is read as a file" eval '[ -z "$out" ]'

setup; base64 -d <<<"$PNG" > a.png; exiftool -q -overwrite_original -Comment=x a.png; git add a.png
exiftool -q -all= -tagsfromfile @ -icc_profile -overwrite_original a.png >/dev/null 2>&1; out=$(git commit -qm x 2>&1)
check "the staged image is checked, not the working copy" eval 'says "a.png has metadata"'

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
