# Devlog: showcase

## Branches

| Branch | Step | State |
|---|---|---|
| `docs/showcase-plan` | plan | PR #9 open |

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
