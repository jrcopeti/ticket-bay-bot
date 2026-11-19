# Devlog: hardening

Entries before 2026-11-19 are in jrcopeti/tania at tag `pre-split`
([DEVLOG](https://github.com/jrcopeti/tania/blob/pre-split/docs/hardening/DEVLOG.md)).

## Branches

| Branch | Step | State |
|---|---|---|
| `main` | import | first commit |
| `docs/unversioned-scripts` | after import | PR to open |

## 2026-11-19: imported from jrcopeti/tania

- The bot's files were copied from jrcopeti/tania at `pre-split`, unchanged, with the same paths:
  `vps/ticket-bay-bot/`, `vps/skills-sync/` and `vps/ticket-bay-app/`.
- `memory-diff.sh` and its test moved from `vps/shared/` to `vps/ticket-bay-bot/`, and only their
  comments changed. The kill switch links to Tania's.
- New for this repo: `AGENTS.md`, `vps/host.md`, this plan and devlog, and CI with the bot's jobs only.
  The hooks, gitleaks rules and secret scan are Tania's, with the title changed.
- The VPS is unchanged: scripts are deployed by hand, and nothing on the host reads either repo.

## 2026-11-19: VPS checksum (read-only)

All 11 deployed files this repo holds match it byte for byte (bot scripts, skills-sync, egress,
app), except `memory-diff.sh`, whose deployed copy differs only in the header comment. The checksum
also found five deployed scripts in no repo (Open in [PLAN.md](PLAN.md)). The full check is in
jrcopeti/tania's [repo-split devlog](https://github.com/jrcopeti/tania/blob/main/docs/repo-split/DEVLOG.md).
