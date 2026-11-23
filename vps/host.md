# The host, from the bot's side

ticket-bay-bot shares one VPS with Telma. Telma's repo describes the same host from her side:
[jrcopeti/telma vps/host.md](https://github.com/jrcopeti/telma/blob/main/vps/host.md).

## Users on this side

| User | What it runs |
|---|---|
| `ticket-bay-bot` | The bot: its own Hermes install (`~/.hermes/hermes-agent`), rootless Docker, linger on. Its sandbox reaches the internet only through the squid in [egress/](ticket-bay-bot/egress/). |
| `ticket-bay-app` | TicketBay with seed data ([ticket-bay-app/](ticket-bay-app/)), rootless Docker, linger on. Built from a root-owned clone in `/opt/ticket-bay-app/src`, pinned to one commit. |
| `skills-sync` | System user, no login. Owns the skills checkout in `/opt`, which the bot reads, and updates it after a scan ([skills-sync/](skills-sync/)). |

Telma runs as the user `agent`. Both agents' homes are `750`, so neither can read the other's files.

## Where each file is deployed

Copied by hand; `~` is the bot's home, `/home/ticket-bay-bot`.

| In this repo | On the VPS |
|---|---|
| `ticket-bay-bot/pull-repos.sh`, `squid-denials.sh`, `memory-diff.sh`, `mint-gh-token.sh`, `bug-loop-pre.sh`, `pr-triage-pre.sh` | `~/.hermes/scripts/` |
| `ticket-bay-bot/set-secret`, `support-inbox` | `~/host-tools/` |
| `ticket-bay-bot/guard-network.sh`, `verify-tests.sh`, `revoke-gh-token.sh` | `~/.hermes/agent-hooks/` |
| `ticket-bay-bot/egress/compose.yaml`, `squid.conf` | `~/egress/` |
| `ticket-bay-bot/sandbox/Dockerfile` | `~/sandbox/` |
| `skills-sync/skills-update.sh`, `scan-diff.py` | `/usr/local/lib/skills-sync/` |
| `skills-sync/skills-pull.cron` | `/etc/cron.d/skills-pull` |
| `ticket-bay-app/Dockerfile`, `Dockerfile.dockerignore`, `compose.yaml` | `/opt/ticket-bay-app/` |

The deployed `support-inbox` differs from this copy in one line: it holds the bug inbox address.
The deployed `skills-update.sh` and `skills-pull.cron` differ in comments only.

`memory-diff.sh` runs as its own hourly no-agent job, and `pull-repos.sh` no longer calls it. Deploy
the two together with that job: the new `pull-repos.sh` alone would stop memory-diff, silently.

`revoke-gh-token.sh` is wired in `~/.hermes/config.yaml` under `hooks:`, as
`on_session_end: [{command: /home/ticket-bay-bot/.hermes/agent-hooks/revoke-gh-token.sh, timeout: 15}]`.
`mint-gh-token.sh`, `bug-loop-pre.sh` and `pr-triage-pre.sh` call it too, so deploy all four with
the hook entry. A cron run skips a hook missing from `~/.hermes/shell-hooks-allowlist.json`, silently,
so the entry needs its approval there too; `hermes hooks doctor` shows whether it has one.

## Rules for the whole host

These rules are the same, word for word, in both repos.

- **Hermes moves in lockstep.** Both installs and `/opt/hermes-guard` stay on the same commit. A bump
  is by hand, in all three places.
- **A compromised host means both kill switches, then a rebuild.** Signs: a root login you don't know,
  a changed `/etc`, an unknown process. Run the
  [bot's](ticket-bay-bot/kill-switch.md) and
  [Telma's](https://github.com/jrcopeti/telma/blob/main/vps/telma/kill-switch.md) kill switches, then
  rebuild the VPS.
- **Scripts are deployed by hand.** Nothing on the host clones either repo. A change here reaches the
  VPS only when the owner says yes and copies it.
