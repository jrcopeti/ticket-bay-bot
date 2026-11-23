# Devlog: hardening

Entries before 2026-11-19 are in jrcopeti/telma at tag `pre-split`
([DEVLOG](https://github.com/jrcopeti/telma/blob/pre-split/docs/hardening/DEVLOG.md)).

## Branches

| Branch | Step | State |
|---|---|---|
| `main` | import | first commit |
| `docs/unversioned-scripts` | after import | merged (#1) |
| `chore/own-host-scripts` | after import | PR to open |

## 2026-11-19: imported from jrcopeti/telma

- The bot's files were copied from jrcopeti/telma at `pre-split`, unchanged, with the same paths:
  `vps/ticket-bay-bot/`, `vps/skills-sync/` and `vps/ticket-bay-app/`.
- `memory-diff.sh` and its test moved from `vps/shared/` to `vps/ticket-bay-bot/`, and only their
  comments changed. The kill switch links to Telma's.
- New for this repo: `AGENTS.md`, `vps/host.md`, this plan and devlog, and CI with the bot's jobs only.
  The hooks, gitleaks rules and secret scan are Telma's, with the title changed.
- The VPS is unchanged: scripts are deployed by hand, and nothing on the host reads either repo.

## 2026-11-19: VPS checksum (read-only)

All 11 deployed files this repo holds match it byte for byte (bot scripts, skills-sync, egress,
app), except `memory-diff.sh`, whose deployed copy differs only in the header comment. The checksum
also found five deployed scripts in no repo (Open in [PLAN.md](PLAN.md)). The full check is in
jrcopeti/telma's [repo-split devlog](https://github.com/jrcopeti/telma/blob/main/docs/repo-split/DEVLOG.md).

## 2026-11-19: the bot's own host scripts

- Added `mint-gh-token.sh`, `bug-loop-pre.sh`, `pr-triage-pre.sh` and `set-secret`, copied from the
  VPS byte for byte (the owner: they work, don't change them). gitleaks found nothing: they read their
  secrets from files under `~/.config` and never hold one themselves. No tests yet: each one needs
  GitHub, Gmail or a terminal.
- `vps/host.md` now maps every file here to its path on the VPS.
- Three more files on the VPS (`guard-network.sh`, `verify-tests.sh`, `support-inbox`) stayed out of
  this step; the next entry adds them. `set-secret` was found next to `support-inbox`.

## 2026-11-19: the VPS-only scripts into the repo

- Added `guard-network.sh` (the terminal guard), `verify-tests.sh` (the test gate) and `support-inbox`
  (claims bug emails), copied from the VPS (mode 755). The owner: publish them.
- Read for secrets first. None: the scripts read their passwords from files. `support-inbox` held the
  bug inbox address, replaced here with a placeholder; the deployed copy keeps it. The other two match
  the VPS byte for byte. Telma's deployed `guard-network.sh` is identical (jrcopeti/telma#24).
- `vps/host.md` maps each to its VPS path. No tests: each needs a Hermes payload, Docker or Gmail.

## 2026-11-19: the sandbox Dockerfile into the repo

- Added `vps/ticket-bay-bot/sandbox/Dockerfile`, byte for byte from `~/sandbox/` on the VPS. A second
  checksum (jrcopeti/telma's repo-split devlog) found it in no repo. No secret; not code from the course.
  It differs from Telma's in one line: an `AGENT_EMAIL` build arg.
- Every deployed file now has a copy here or in Telma's repo. Differences: `memory-diff.sh` (comment
  lines) and `support-inbox` (the inbox address).

## 2026-11-19: the other agent renamed Telma

- Step 3 of jrcopeti/telma's [rename plan](https://github.com/jrcopeti/telma/blob/main/docs/rename/PLAN.md):
  her old name became Telma in all 7 files that named her, links included. The links work once that
  repo is renamed (its step 4).
- `guard-network.sh` and `verify-tests.sh` changed in comments only. Until step 5 redeploys them,
  their VPS copies differ from these in those comment lines. `guard-network.sh` is still byte for byte
  the same as Telma's.

## 2026-11-19: lessons 8.5 and 8.6 moved here

- They sat in Open in Telma's frozen hardening plan. They run on the bot, so they're tracked here now.

## 2026-11-23: memory-diff hourly

- The owner's call: memory-diff runs every hour instead of once a day, so something planted in the
  bot's memory or skills shows within the hour. It's a script, no model, and silent when nothing
  changed, so an hourly run costs nothing.
- `pull-repos.sh` no longer calls it; memory-diff gets its own Hermes no-agent job, like
  squid-denials. pull-repos still reports the skills update daily at 07:55.
- Not deployed yet: the VPS change (new hourly job, the two scripts copied) waits for the owner's yes.
- `/code-review` (default effort, all findings) found 11. Fixed, each with a test that fails on the
  old scripts: the undo and full-diff lines named `HEAD`, which moves on every hour, so they now name
  the run's own commit; a lock left by a killed run would fail every later run, so one older than 30
  minutes is removed; pull-repos's status path can be pointed at a test file; a test checks that
  pull-repos no longer runs memory-diff. `host.md` says the two scripts and the hourly job deploy
  together, and the kill switch says the undo line names its own snapshot.
- Not fixed: the docs say hourly before the VPS does; this PR merges after the deploy. The test that
  planted hooks don't run is kept as a guard, though pull-repos no longer runs git at all.
- Second `/code-review` (the owner asked) found 9, all fixed. memory-diff: every stale lock is
  cleared, not only `index.lock` (a killed commit leaves `HEAD.lock` or the branch's); a commit that
  keeps failing posts its diff once, not every hour; undo lines use the full SHA, and no undo line
  when it can't be read. The kill switch reads the snapshot's history instead of running
  memory-diff, which the hourly job has usually run already. `host.md` describes the setup instead
  of saying "not deployed"; the showcase plan's known VPS differences match it. The pull-repos
  tests clone only where the hook test needs it.
