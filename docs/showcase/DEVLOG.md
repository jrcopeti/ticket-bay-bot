# Devlog: showcase

## Branches

| Branch | Step | State |
|---|---|---|
| `docs/showcase-plan` | plan | PR #9 merged |
| `ci/personal-data-net` | 1 | PR #10 merged |
| `docs/threat-model` | 2 | PR #11 open |

## 2026-11-21: plan

- Telma's showcase plan handed this repo the bug-loop demo and the bot's before/after rows, but no
  plan here tracked them. The owner asked for one, mirroring Telma's.
- The owner's calls: the fork `jrcopeti/ticket-bay` is part of the showcase, since the bot's PRs
  live there (a README section on the fork, now step 7); agents draft the public docs and the owner
  approves, here too; the docs say "the owner"; `AGENTS.md` no longer says only the owner pushes.
- Renamed to "the owner" in `AGENTS.md`, the hardening plan and devlog, `vps/host.md` and a comment
  in `memory-diff.sh`. The deployed `memory-diff.sh` already differed in its header comment; it now
  differs in one more comment line.
- The owner asked for at least five bot PRs from planted bugs sent by email: demo bugs, now step 6,
  with a `demo-bugs/` kit on the fork. Its candidate bugs come from the brain's demo-bug kit note and
  aren't checked against the code yet.
- The ADR list is candidates only, from the hardening plan's Decisions; the owner picks.

## 2026-11-22: plan review

- The owner decided the Open items: the candidate numbers go in the README; the old fork PRs (#11
  to #13, #16) are closed and the README links only the new demo-bug PRs.
- "How many were merged" would read 0 with every demo PR open, so the owner raised the demo to
  eight bugs: three PRs merged, five left open. The number stays.
- Where the bugs go, first `demo`, then `main`. Review found a `demo` base would also catch every
  other email, and the owner ruled out switching the base for a demo session, then left the call to
  Claude: `main`. One base, PRs read "into main" on the fork's PR page, and security patches leave
  no demo branch to rebase. Cost: `main` carries the bugs; the fork's README section lists them.
- The brain's demo-bug kit note was Telma's, from before the split. A ticket-bay-bot kit is captured
  in the brain inbox (2026-11-22) and step 6 points to it. Step 3 points to the before/after rows in
  the brain's `sources/`, where triage moved them.
- README step: dropped the `crafting-effective-readmes` skill; the brain's prose-docs guideline
  covers how the README is written.
- `dmoka/ticket-bay` and `dmoka/skills` are out of the steps: TicketBay and the skills are the
  owner's product now, and one sentence under the goal says they started as open source and get
  credited once in the README.
- New step 1, personal-data net. `.gitleaks.toml` already had rules for emails, IPs, Discord IDs,
  webhooks and Tailscale hosts; the step adds home paths, an untracked local list of exact values
  (private repo names), and EXIF stripping for images. A new rule has an agent read each PR's
  diff for what no regex catches.
- New step 5, the bot's live files, mirroring Telma's step 5: `SOUL.md`, a redacted `config.yaml`,
  the hooks config, the cron prompts from `jobs.json`, and the `bug-triage` and `pr-triage` skills.
  Memories and self-saved skills stay off. The exact file names on the VPS aren't checked yet; the
  step's agent lists them before copying.
- The scripts already mirrored (`mint-gh-token.sh`, `bug-loop-pre.sh`, `pr-triage-pre.sh`,
  `set-secret`, `support-inbox`, `guard-network.sh`, `verify-tests.sh`) stay as they are. Step 5
  now diffs every file in `vps/` with the VPS, old and new, before its PR. The README links
  `vps/host.md` as the map of the setup.

## 2026-11-22: step 1, personal-data net

- `.gitleaks.toml` gets a `home-path` rule for `/Users/<name>` and `/home/<name>`, relative ones
  (`../../Users/<name>`) too. The bot's VPS users (`ticket-bay-bot`, `telma`) and `/Users/Shared`
  are allowed; a path glued to a variable (`$W/home/dev`, `${W}/home/dev`) isn't a home path.
- Gotcha: gitleaks' default allowlist drops any secret matching `^/(?:bin|etc|home|...)/...$`, so a
  rule whose secret is the whole `/home/...` path never fires. The rule's secret is the user name.
- `.githooks/private-values` reads `.git/info/private-values`, the owner's untracked list, and
  blocks a staged line, file name or commit message (the new `commit-msg` hook) that holds one of its
  values, in any case. No list: it warns and lets the commit through, so a fresh clone still works.
  CI can't run it: the list lives only on the local machine.
- `.githooks/image-metadata` blocks a staged image whose bytes change when exiftool strips it (EXIF,
  GPS, XMP, comments; the colour profile stays). It reads the staged blob, not the working copy.
  CI runs it on every tracked image, since `--no-verify` skips the hook.
- `.githooks/test-hooks.sh` drives both hooks in a throwaway repo; a new `hooks` job in
  `secret-scan.yml` runs it. The full history passes the new rule.
- A `pre-merge-commit` hook runs the same checks, since a merge commit skips `pre-commit`.
- `/code-review` (default effort, all findings) found 11; 9 fixed, each with a test that fails on
  the old hooks: `++` lines skipped, `commit -v` diffs read as the message, untrimmed list values,
  relative and `${W}` paths, merges unchecked, exiftool errors reported as metadata, a `-name.png`
  read as an option, the JFIF message, a silent setup failure in the test. Not fixed: a staged
  rename rescans the whole file and binary files aren't scanned for values (a rename only finds
  what's already there; no binary docs here), and one `git diff` per file (the repo is small).

## 2026-11-22: step 2, threat model

- `docs/threat-model.md`, same shape as Telma's: assets, trust boundaries, legs per session,
  13 threats with the control, the leg it cuts and the proof, accepted risks, detection, out of scope.
- Proof is from the B1 to B9 injection cases and probes at Telma's tag `pre-split`; each row says
  when the model refused and the wall was proved by a probe only. B7 was never run.
- Checked against the fork's ruleset (API, read-only): `main` needs a PR with one approval and six
  CI checks; only the owner's user bypasses it. So the bot can't merge its own PR, and the threat
  model says so instead of "PR required".
- Found while writing: the test gate goes green if an email gets the bot to delete the tests that
  catch the bug (B1's obedient run did exactly that, before committing). Listed as an accepted risk;
  the owner's approval and the fork's CI are the wall.
- Branched off `main` while step 1 (PR #10) was open, then rebuilt as one commit on `main` after #10
  merged. A merge of `main` didn't work: `pre-merge-commit` diffs against the branch, so it flagged
  lines that came from `main` (`test-hooks.sh`, step 1's entry here) as new. Step 1's hooks need a
  follow-up for that and for the 3-character list value below.
- `/code-review` (default effort, all findings) found 7, all fixed: the skills repo's name and path
  are on the private-values list, so the doc says "the skills repo" (they're still in `vps/host.md`
  and older docs, where step 1's hook doesn't look at old lines); the "no session holds three legs"
  line now says the token is the only private data; npm's `ignore-scripts` is named and marked as
  VPS config not in this repo; the ruleset sentence names the owner's bypass; Telma moved inside the
  VPS box in the diagram; this plan's row had an extra cell.
- Not changed: review read `support-inbox`'s comment ("inside the sandbox the password is mounted at
  `/opt/secrets`") as a mail password in the sandbox. The pre-split probes found only the 1-hour
  token in the sandbox, and `bug-loop-pre.sh` runs `support-inbox` on the host, so the comment is
  stale. The script stays byte for byte the VPS copy; step 5's diff with the VPS can settle it.
- Step 1's private-values check, run by hand on this diff (its hook isn't on `main` yet), matched
  a common English word in the lens ("off the m…", as Telma's doc says it): a 3-character value on
  the local list is a substring of it. The lens now says "off the server". The same match blocks
  the brain's docs guideline phrase "the local m…", so the list or the hook's substring match needs
  a look in PR #10.
