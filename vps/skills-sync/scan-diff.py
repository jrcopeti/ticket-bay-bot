"""Scan two checkouts of a skills repo with Hermes's skills guard and print the findings only the new one has.
Usage: python3 -I scan-diff.py <hermes-agent dir> <old checkout> <new checkout>
Exit 0: nothing new above low. Exit 1: new findings, one per line. Exit 2: the scan itself failed.
The whole repo is scanned as one unit: the bot's sandbox mounts all of it, and a skill can point at any file.
Findings are matched on pattern and path, not line, so moved code doesn't count as new."""
import os
import re
import sys
from collections import namedtuple
from pathlib import Path

Link = namedtuple("Link", "pattern_id severity file line")


# The guard rates a broken symlink medium. Here a link is resolved on the host, but the bot follows it
# in its sandbox, so one that leaves the repo or points nowhere could read anything there: high.
# "Leaves" is judged on the path text inside the repo, so `../../../new/x` can't pass by coming back
# through the scan folder's own name.
def links(repo):
    root = repo.resolve()
    for p in repo.rglob("*"):
        if p.is_symlink():
            to = os.path.normpath(os.path.join(os.path.dirname(p.relative_to(repo)), os.readlink(p)))
            if os.path.isabs(to) or to.split(os.sep)[0] == ".." or not p.exists() or not p.resolve().is_relative_to(root):
                yield Link("symlink_outside_repo", "high", str(p.relative_to(repo)), 0)


def findings(scan_skill, repo):
    out = {}
    for f in [*scan_skill(repo, source="dmoka/skills").findings, *links(repo)]:
        out.setdefault((f.pattern_id, f.file), f)
    return out


try:
    guard, old, new = (Path(a) for a in sys.argv[1:4])
    for d in old, new:
        if not d.is_dir():  # the guard scans a missing folder as clean
            raise FileNotFoundError(d)
    sys.path.insert(0, str(guard))
    from tools.skills_guard import scan_skill
    before, after = findings(scan_skill, old), findings(scan_skill, new)
except Exception as e:
    print(f"scan failed: {type(e).__name__}")  # not the message: it can quote a file's bytes
    print(repr(e), file=sys.stderr)
    sys.exit(2)

# The lines end up in a Discord post, and upstream picks the file names: keep them short, with no
# characters that make mentions, links or markdown.
def safe(name):
    name = re.sub(r"[^A-Za-z0-9._/-]", "?", name)
    return name if len(name) <= 80 else name[:77] + "..."


added = [f for k, f in sorted(after.items()) if k not in before and f.severity != "low"]
for f in added[:5]:
    print(f"{f.severity} {safe(f.pattern_id)} in {safe(f.file)}:{f.line}")
if len(added) > 5:
    print(f"and {len(added) - 5} more")
sys.exit(1 if added else 0)
