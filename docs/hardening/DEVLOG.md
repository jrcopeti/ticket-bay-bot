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
  VPS byte for byte (José: they work, don't change them). gitleaks found nothing: they read their
  secrets from files under `~/.config` and never hold one themselves. No tests yet: each one needs
  GitHub, Gmail or a terminal.
- `vps/host.md` now maps every file here to its path on the VPS.
- Three more files on the VPS come from the course kit, unchanged or nearly (`guard-network.sh`,
  `verify-tests.sh`, `support-inbox`). They stay out: the kit's license forbids republishing them.
  `set-secret` was found next to `support-inbox`; it isn't kit code.

## 2026-11-19: the VPS-only scripts into the repo

- Added `guard-network.sh` (the terminal guard), `verify-tests.sh` (the test gate) and `support-inbox`
  (claims bug emails), copied from the VPS (mode 755). José: publish them despite the course kit's
  license. Each is the kit's file with 4 to 8 lines changed.
- Read for secrets first. None: the scripts read their passwords from files. `support-inbox` held the
  bug inbox address, replaced here with a placeholder; the deployed copy keeps it. The other two match
  the VPS byte for byte. Telma's deployed `guard-network.sh` is identical (jrcopeti/telma#24).
- `vps/host.md` maps each to its VPS path. No tests: each needs a Hermes payload, Docker or Gmail.

## 2026-11-19: the sandbox Dockerfile into the repo

- Added `vps/ticket-bay-bot/sandbox/Dockerfile`, byte for byte from `~/sandbox/` on the VPS. A second
  checksum (jrcopeti/telma's repo-split devlog) found it in no repo. No secret; not course-kit code.
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
