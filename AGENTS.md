# ticket-bay-bot

Showcase repo for ticket-bay-bot, a Hermes agent on a VPS that runs the bug loop and PR triage on the
ticket-bay fork. It shares the host with Tania (jrcopeti/tania) and nothing else.

- **Start here:** `docs/hardening/PLAN.md`, then `DEVLOG.md` beside it. Keep both current. History
  before the split: jrcopeti/tania at tag `pre-split`.
- **The bot never writes here.** Its GitHub App is installed on the ticket-bay fork only; never add
  this repo to it. Only José pushes, through PRs.
- **Running agents:** ask José before resuming, triggering (`hermes cron run`) or switching on any job,
  every time. After an interrupted command, check what partly ran before saying nothing ran: remote
  commands keep running.
- **Hook setup, once per clone:** `git config core.hooksPath .githooks`. The pre-commit hook runs
  gitleaks on staged changes; CI runs it on the full history.
- **No secrets or personal data:** no keys, webhook URLs, inbox address, Discord IDs, IP addresses,
  private repo names.
- **Public prose** (README, threat model, ADRs, postmortem) is José's to write.
