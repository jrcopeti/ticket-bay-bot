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
| `ticket-bay-bot/hermes/SOUL.md` | `~/.hermes/` |
| `ticket-bay-bot/hermes/config.overrides.yaml` | merged by hand into `~/.hermes/config.yaml` (below) |
| `ticket-bay-bot/tools/publish-pr-review`, `bug-loop-prompt.txt`, `pr-triage-prompt.txt` | `~/tools/`, which the sandbox mounts read-only at `/opt/tools` |
| `ticket-bay-bot/egress/compose.yaml`, `squid.conf` | `~/egress/` |
| `ticket-bay-bot/sandbox/Dockerfile` | `~/sandbox/` |
| `ticket-bay-bot/systemd/pr-review-http.service`, `hermes-gateway.service.d/rootless-docker.conf` | `~/.config/systemd/user/`, the same paths; enable the unit, the drop-in needs only `daemon-reload` (the gateway unit itself comes from Hermes's installer) |
| `skills-sync/skills-update.sh`, `scan-diff.py` | `/usr/local/lib/skills-sync/` |
| `skills-sync/skills-pull.cron` | `/etc/cron.d/skills-pull` |
| `ticket-bay-app/Dockerfile`, `Dockerfile.dockerignore`, `compose.yaml` | `/opt/ticket-bay-app/` |

The deployed `support-inbox` differs from this copy in one line: it holds the bug inbox address.
The deployed `pr-triage-prompt.txt` has the tailnet host name where this copy says `<tailnet-host>`.
The deployed `skills-update.sh` and `skills-pull.cron` differ in comments only.

Most of `~/.hermes/config.yaml` is Hermes's own defaults, written by its installer.
[`config.overrides.yaml`](ticket-bay-bot/hermes/config.overrides.yaml) holds only the settings
chosen for the bot: the model and its free fallbacks, the Docker sandbox with its mounts, network and
proxy, the disabled toolsets, memory on and the user profile off, the external skills folder,
approvals, the three hooks under `hooks:`, and the TicketBay MCP server with its tool include-list.
Three of them equal Hermes's defaults and are pinned on purpose. Every key in it must match the live
file.

## The skills

The bot runs the skills of [dmoka/skills](https://github.com/dmoka/skills) (MIT), checked out in
`/opt/dmoka-skills` and mounted read-only into the sandbox at the same path. This repo pins the
commit and holds no copy.

| Pinned commit | Checked |
|---|---|
| [`1a6af1f`](https://github.com/dmoka/skills/tree/1a6af1f2657fd4c9d8fe5bdb04f3e57156546c11) | 2026-11-23 |

| Skill | Used by |
|---|---|
| `bug-triage` | the bug-loop job |
| `pr-triage` | the morning PR triage |
| `pr-tour` | `publish-pr-review`, which renders one tour page per open PR |
| `adversarial-tester` | the owner only, on request (`SOUL.md`) |

`skills-sync` moves the checkout forward after a 7-day wait and the skills
guard. So the pin is the commit seen when last checked; on the host,
`git -C /opt/dmoka-skills rev-parse HEAD` shows the one running now.

## The bot's jobs

Each prompt is the job's prompt in `~/.hermes/cron/jobs.json`, kept as a file in `~/tools/` too.
Scripts are in `~/.hermes/scripts/`. Every job posts to the ticket-bay Discord channel.

| Job | When (Berlin) | Script | Agent | Skill and prompt |
|---|---|---|---|---|
| `pull-repos` | 07:55 | `pull-repos.sh` | no | — |
| `pr-triage-morning` | 08:00 | `pr-triage-pre.sh` | yes | `pr-triage`, [pr-triage-prompt.txt](ticket-bay-bot/tools/pr-triage-prompt.txt) |
| `bug-loop` | 09:00 | `bug-loop-pre.sh` | yes | `bug-triage`, [bug-loop-prompt.txt](ticket-bay-bot/tools/bug-loop-prompt.txt) |
| `squid-denials` | every 10 min | `squid-denials.sh` | no | — |
| `memory-diff` | hourly | `memory-diff.sh` | no | — |

`memory-diff.sh` runs as its own hourly no-agent job, and `pull-repos.sh` no longer calls it. Deploy
the two together with that job: the new `pull-repos.sh` alone would stop memory-diff, silently.

`revoke-gh-token.sh` is wired in `~/.hermes/config.yaml` under `hooks:`, as
`on_session_end: [{command: /home/ticket-bay-bot/.hermes/agent-hooks/revoke-gh-token.sh, timeout: 15}]`.
`mint-gh-token.sh`, `bug-loop-pre.sh` and `pr-triage-pre.sh` call it too, so deploy all four with
the hook entry. A cron run skips a hook missing from `~/.hermes/shell-hooks-allowlist.json`, silently,
so the entry needs its approval there too; `hermes hooks doctor` shows whether it has one. Hermes
writes that file when a hook is approved, with timestamps, so this repo holds no copy: all three
hooks (`guard-network.sh`, `verify-tests.sh`, `revoke-gh-token.sh`) need an approval.

## The bot's services

All are user units of `ticket-bay-bot`, enabled, and start at boot because linger is on. The two
the owner wrote are in [systemd/](ticket-bay-bot/systemd/); the other two are generated and kept
as their tools wrote them, so this repo holds no copy.

| Unit | What it runs | Written by |
|---|---|---|
| `docker.service` | The bot's rootless Docker: the sandbox and the egress proxy run on it. | `dockerd-rootless-setuptool.sh install`, unchanged |
| `hermes-gateway.service` | The bot: Discord, the cron jobs and the hooks. The kill switch disables it. | Hermes's installer, unchanged; it names the Node and npm versions in `PATH`, so it changes with each Hermes bump |
| `hermes-gateway.service.d/rootless-docker.conf` | Starts the gateway after `docker.service` and sets `DOCKER_HOST` to the bot's own socket, so each sandbox runs in the bot's Docker, never in root's. | the owner |
| `pr-review-http.service` | Serves the review pages (below). | the owner |

The gateway restarts 5 s after any stop, with no limit, and has no systemd hardening
(`NoNewPrivileges`, `ProtectSystem` and the like): it runs as the bot user with that user's rights.

## The review pages

The morning triage ends with `publish-pr-review`, which writes the queue, one tour page per open PR
and an index into `~/pr-review/`, which the sandbox mounts read-write at the same path.

- [`pr-review-http.service`](ticket-bay-bot/systemd/pr-review-http.service), a user unit of the bot, serves
  the folder with `python3 -m http.server` on `127.0.0.1:8481`, so nothing outside the host reaches
  it.
- Tailscale publishes it to the tailnet only, over HTTPS on port 8443, with
  `sudo tailscale serve --bg --https=8443 http://127.0.0.1:8481`. No Funnel: the pages hold the
  fork's PR content and never reach the internet. `tailscale serve status` shows the setting.
- The Discord post links the queue and each tour at `https://<tailnet-host>:8443/`, so a link opens
  only on a device in the tailnet.

To install the unit: copy it, then, as the bot, `systemctl --user daemon-reload` and
`systemctl --user enable --now pr-review-http`. Linger is on for the bot (see the users table), so the server comes back after
a reboot without a login.

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
