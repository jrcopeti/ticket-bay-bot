# ticket-bay-bot

Showcase repo for ticket-bay-bot, a Hermes agent on a VPS that runs the bug loop and PR triage on the
ticket-bay fork. It shares the host with Telma (jrcopeti/telma) and nothing else.

- **Start here:** `docs/hardening/PLAN.md`, then `DEVLOG.md` beside it; for the public docs,
  `docs/showcase/`. Keep each plan and devlog current. History before the split: jrcopeti/telma at
  tag `pre-split`.
- **The bot never writes here.** Its GitHub App is installed on the ticket-bay fork only; never add
  this repo to it.
- **Running agents:** ask the owner before resuming, triggering (`hermes cron run`) or switching on
  any job, every time. After an interrupted command, check what partly ran before saying nothing ran:
  remote commands keep running.
- **Hook setup, once per clone:** `git config core.hooksPath .githooks`, and `brew install gitleaks
  exiftool`. The hooks block secrets and personal data (`.gitleaks.toml`), image metadata, and the
  values in `.git/info/private-values` (one per line: private repo names and other exact values,
  never committed). CI runs gitleaks on the full history and checks every image.
- **No secrets or personal data:** no keys, webhook URLs, inbox address, Discord IDs, IP addresses,
  private repo names.
- **Public prose** (README, threat model, ADRs, postmortem): agents draft it, the owner approves each
  doc in its PR.
