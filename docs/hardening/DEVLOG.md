# Devlog: hardening

Entries before 2026-11-19 are in jrcopeti/tania at tag `pre-split`
([DEVLOG](https://github.com/jrcopeti/tania/blob/pre-split/docs/hardening/DEVLOG.md)).

## Branches

| Branch | Step | State |
|---|---|---|
| `main` | import | first commit |

## 2026-11-19: imported from jrcopeti/tania

- The bot's files were copied from jrcopeti/tania at `pre-split`, unchanged, with the same paths:
  `vps/ticket-bay-bot/`, `vps/skills-sync/` and `vps/ticket-bay-app/`.
- `memory-diff.sh` and its test moved from `vps/shared/` to `vps/ticket-bay-bot/`, and only their
  comments changed. The kill switch links to Tania's.
- New for this repo: `AGENTS.md`, `vps/host.md`, this plan and devlog, and CI with the bot's jobs only.
  The hooks, gitleaks rules and secret scan are Tania's, with the title changed.
- The VPS is unchanged: scripts are deployed by hand, and nothing on the host reads either repo.
