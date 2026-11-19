#!/usr/bin/env bash
# Tests for skills-update.sh against a throwaway "upstream" and checkout. A stub skills guard flags
# EVIL and PIPE| (high) and MEH (low), and fails on BOOM, so these test the update rules, not Hermes's
# patterns. PIPE| is there because UTF-7 escapes the pipe: it shows which bytes the scan read.
# Run: bash vps/skills-sync/test-skills-update.sh
set -u
SCRIPT=$(cd "$(dirname "$0")" && pwd)/skills-update.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@localhost GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@localhost
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
NOW=$(date +%s) DAY=86400
pass=0 fail=0

mkdir -p "$T/guard/tools" && touch "$T/guard/tools/__init__.py"
cat > "$T/guard/tools/skills_guard.py" <<'EOF'
from dataclasses import dataclass
@dataclass
class Finding:
    pattern_id: str
    severity: str
    file: str
    line: int
@dataclass
class ScanResult:
    findings: list
def scan_skill(d, source=""):
    out = []
    for p in sorted(d.rglob("*")):
        if p.is_file():
            for i, line in enumerate(p.read_text().splitlines(), 1):
                if "BOOM" in line:
                    raise RuntimeError("boom")
                for word, sev in (("EVIL", "high"), ("PIPE|", "high"), ("MEH", "low")):
                    if word in line:
                        out.append(Finding(word.lower().strip("|"), sev, str(p.relative_to(d)), i))
    return ScanResult(out)
EOF

setup() {
  rm -rf "$T/w" && W=$T/w && mkdir -p "$W/state"
  git init -q --bare -b main "$W/up.git"
  git init -q -b main "$W/dev"
  mkdir -p "$W/dev/skills/a" && echo "# a" > "$W/dev/skills/a/SKILL.md"
  push_all seed
  git clone -q "$W/up.git" "$W/repo" && git -C "$W/repo" checkout -q --detach
  PIN=$(head_of repo)
}
push_all() { git -C "$W/dev" add -A && git -C "$W/dev" commit -qm "$1" && git -C "$W/dev" push -q "$W/up.git" HEAD:main; }
upstream() { echo "$2" >> "$W/dev/skills/a/$1" && push_all "$1"; UP=$(head_of dev); }
head_of() { git -C "$W/$1" rev-parse HEAD; }
run() { SKILLS_REPO=$W/repo HERMES_GUARD=${GUARD:-$T/guard} SKILLS_STATE=$W/state SKILLS_NOW=$1 bash "$SCRIPT"; out=$(cat "$W/state/status"); }
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; echo "     status: ${out:-<none>}"; fail=$((fail + 1)); fi; }
says() { grep -qF -- "$1" <<<"$out"; }
at() { [ "$(head_of repo)" = "$1" ]; }
age() { run $((NOW - 8 * DAY)); run "$NOW"; }

# --- the wait
setup; run "$NOW"
check "first run: ok, stays on the pin" eval '[ "$out" = ok ] && at "$PIN"'

setup; upstream SKILL.md "clean change"; run "$NOW"
check "a commit first seen today is not taken" eval '[ "$out" = ok ] && at "$PIN"'

setup; upstream SKILL.md "clean change"; run $((NOW - 8 * DAY)); run "$NOW"
check "a clean commit first seen 8 days ago is taken" eval 'says "skills updated" && at "$UP"'

setup; upstream SKILL.md "clean change"; run $((NOW - 6 * DAY)); run "$NOW"
check "a commit first seen 6 days ago is not taken" eval '[ "$out" = ok ] && at "$PIN"'

setup; echo old >> "$W/dev/skills/a/SKILL.md"
GIT_COMMITTER_DATE="@$((NOW - 30 * DAY)) +0000" GIT_AUTHOR_DATE="@$((NOW - 30 * DAY)) +0000" push_all backdated; run "$NOW"
check "a backdated commit first seen today is not taken" eval '[ "$out" = ok ] && at "$PIN"'

setup; upstream SKILL.md "first"; old=$UP; run $((NOW - 8 * DAY)); upstream SKILL.md "second"; run "$NOW"
check "takes the newest commit past the wait, not upstream's head" eval 'says "skills updated" && at "$old"'

setup; upstream SKILL.md "clean"; run $((NOW - 8 * DAY)); run "$NOW"; run $((NOW + 60))
check "nothing new after an update: ok" eval '[ "$out" = ok ] && at "$UP"'

setup; upstream SKILL.md "bad"; run $((NOW - 8 * DAY))
git -C "$W/dev" reset -q --hard HEAD~1 && git -C "$W/dev" push -qf "$W/up.git" HEAD:main; run $((NOW - 6 * DAY)); run "$NOW"
check "a commit upstream force-pushed away during the wait is not taken" eval '[ "$out" = ok ] && at "$PIN"'

setup; upstream SKILL.md "good"; good=$UP; run $((NOW - 9 * DAY)); upstream SKILL.md "bad"; run $((NOW - 8 * DAY))
git -C "$W/dev" reset -q --hard HEAD~1 && git -C "$W/dev" push -qf "$W/up.git" HEAD:main; run $((NOW - 6 * DAY)); run "$NOW"
check "after a force-push, takes the older commit upstream still has" eval 'says "skills updated" && at "$good"'

# --- the scan
setup; upstream run.sh "EVIL"; run $((NOW - 8 * DAY)); run "$NOW"
check "a new high finding blocks, naming the file" eval 'says "🚫" && says "a/run.sh" && at "$PIN"'

setup; upstream SKILL.md "MEH"; run $((NOW - 8 * DAY)); run "$NOW"
check "a new low finding doesn't block" eval 'says "skills updated" && at "$UP"'

setup; upstream probe.sh "EVIL"; git -C "$W/repo" fetch -q && git -C "$W/repo" checkout -q --detach origin/main; PIN=$(head_of repo)
sed -i.bak '1i\
moved down' "$W/dev/skills/a/probe.sh" && rm "$W/dev/skills/a/probe.sh.bak" && push_all move; UP=$(head_of dev)
run $((NOW - 8 * DAY)); run "$NOW"
check "a finding the pin already has doesn't block, even on another line" eval 'says "skills updated" && at "$UP"'

setup; mkdir -p "$W/dev/skills/b" && echo EVIL > "$W/dev/skills/b/SKILL.md" && push_all newskill; run $((NOW - 8 * DAY)); run "$NOW"
check "a new skill with a finding blocks" eval 'says "🚫" && says "b/SKILL.md" && at "$PIN"'

setup; upstream SKILL.md "BOOM"; run $((NOW - 8 * DAY)); run "$NOW"
check "a failed scan doesn't update" eval 'says "scan failed" && at "$PIN"'

setup; mkdir -p "$W/dev/shared" && echo EVIL > "$W/dev/shared/x.sh" && push_all shared
git -C "$W/repo" fetch -q && git -C "$W/repo" checkout -q --detach origin/main; PIN=$(head_of repo)
mkdir -p "$W/dev/skills/shared" && echo EVIL > "$W/dev/skills/shared/x.sh" && push_all newskill; age
check "a new skill named like a top-level folder doesn't borrow its findings" eval 'says "🚫" && at "$PIN"'

setup; upstream SKILL.md "BOOM"; mkdir -p "$T/noguard"; GUARD=$T/noguard age
check "a guard that can't be imported is a failed scan" eval 'says "scan failed" && at "$PIN"'

# --- the scanned tree is the checked-out tree, all of it
setup; echo "skills/a/run.sh export-ignore" > "$W/dev/.gitattributes"; upstream run.sh "EVIL"; age
check "export-ignore doesn't hide a file from the scan" eval 'says "🚫" && says "skills/a/run.sh" && at "$PIN"'

setup; mkdir -p "$W/dev/scripts" && echo EVIL > "$W/dev/scripts/x.sh" && push_all outside; age
check "a finding outside skills/ blocks" eval 'says "🚫" && says "scripts/x.sh" && at "$PIN"'

# A target that exists nowhere. One skills-sync can't read (the bot's home) makes the scan itself fail
# on a permission error: also not taken, but the status says "scan failed".
setup; ln -s /nonexistent-zz/dev/x.sh "$W/dev/skills/a/run.sh" && push_all abslink; age
check "an absolute symlink blocks" eval 'says "symlink_outside_repo" && at "$PIN"'

setup; ln -s ../../../../etc/passwd "$W/dev/skills/a/run.sh" && push_all rellink; age
check "a relative symlink leaving the repo blocks" eval 'says "symlink_outside_repo" && at "$PIN"'

setup; ln -s ../a/SKILL.md "$W/dev/skills/a/same.md" && push_all inlink; UP=$(head_of dev); age
check "a symlink inside the repo doesn't block" eval 'says "skills updated" && at "$UP"'

setup; ln -s ../../../new/skills/a/SKILL.md "$W/dev/skills/a/leak.md" && push_all scandirname; age
check "a link leaving the repo blocks even if it comes back through the scan folder's name" eval 'says "symlink_outside_repo" && at "$PIN"'

# Attributes: A sets UTF-7 for *.md and is taken; B drops that and adds PIPE|. Checkout writes B's
# SKILL.md with B's attributes (plain), so the scan must read it that way too, not with A's.
setup; echo "*.md working-tree-encoding=UTF-7" > "$W/dev/.gitattributes"; upstream SKILL.md "benign"; A=$UP
run $((NOW - 20 * DAY)); run $((NOW - 10 * DAY))
git -C "$W/dev" rm -q .gitattributes && upstream SKILL.md "PIPE|"; run $((NOW - 9 * DAY)); run "$NOW"
check "the scan reads a file with the attributes checkout uses" eval 'says "🚫" && at "$A"'

setup; upstream SKILL.md "a|b"; run $((NOW - 20 * DAY)); run $((NOW - 10 * DAY))
echo "*.md working-tree-encoding=UTF-7" > "$W/dev/.gitattributes" && push_all attrs; UP=$(head_of dev); age
check "a new .gitattributes rewrites files it didn't change, as the scan saw them" eval 'at "$UP" && grep -qF "a+AHw-b" "$W/repo/skills/a/SKILL.md"'

setup; python3 - "$W/dev" <<'PY'
import subprocess, sys
d = sys.argv[1]
blob = subprocess.run(["git", "-C", d, "hash-object", "-w", "--stdin"], input=b"x", capture_output=True).stdout.decode().strip()
lines = "".join(f"100644 {blob}\tskills/a/many/f{i:04d}\n" for i in range(200))
subprocess.run(["git", "-C", d, "update-index", "--add", "--index-info"], input=lines.encode(), check=True)
PY
git -C "$W/dev" commit -qm many && git -C "$W/dev" push -q "$W/up.git" HEAD:main
SKILLS_MAX_FILES=100 age
check "a tree over the file cap is not unpacked (tiny blobs, many names)" eval 'says "files (cap 100)" && at "$PIN"'

setup; echo EVIL > "$W/dev/skills/a/@everyone <@123> [click](http:__x.example) x.sh"
for i in $(seq 1 30); do echo EVIL > "$W/dev/skills/a/$(printf 'n%.0s' $(seq 1 100))$i.sh"; done; push_all spam; age
check "the status stays short and carries no mentions or links" eval 'says "🚫" && [ ${#out} -le 1500 ] && ! says "@" && ! says "<" && ! says "]("'

setup; head -c 3000000 /dev/zero > "$W/dev/skills/a/big.txt" && push_all big; UP=$(head_of dev)
SKILLS_MAX_MB=2 age
check "a tree over the size cap is not unpacked" eval 'says "MB (cap 2)" && at "$PIN"'

# --- upstream trouble
setup; upstream SKILL.md "x"; run $((NOW - 8 * DAY))
git -C "$W/dev" checkout -q --orphan other && git -C "$W/dev" commit -qm rewritten && git -C "$W/dev" push -qf "$W/up.git" HEAD:main
run $((NOW - 7 * DAY - 60)); run "$NOW"
check "rewritten upstream history is refused" eval 'says "history rewritten" && at "$PIN"'

setup; git -C "$W/repo" remote set-url origin "$W/missing.git"; run "$NOW"
check "a failed fetch is reported" eval 'says "fetch failed" && at "$PIN"'

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
