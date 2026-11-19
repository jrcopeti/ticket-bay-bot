# The host, from the bot's side

ticket-bay-bot shares one VPS with Tania. Tania's repo describes the same host from her side:
[jrcopeti/tania vps/host.md](https://github.com/jrcopeti/tania/blob/main/vps/host.md).

## Users on this side

| User | What it runs |
|---|---|
| `ticket-bay-bot` | The bot: its own Hermes install (`~/.hermes/hermes-agent`), rootless Docker, linger on. Its sandbox reaches the internet only through the squid in [egress/](ticket-bay-bot/egress/). |
| `ticket-bay-app` | TicketBay with seed data ([ticket-bay-app/](ticket-bay-app/)), rootless Docker, linger on. Built from a root-owned clone in `/opt/ticket-bay-app/src`, pinned to one commit. |
| `skills-sync` | System user, no login. Owns `/opt/dmoka-skills`, which the bot reads, and updates it after a scan ([skills-sync/](skills-sync/)). |

Tania runs as the user `agent`. Both agents' homes are `750`, so neither can read the other's files.

## Rules for the whole host

These rules are the same, word for word, in both repos.

- **Hermes moves in lockstep.** Both installs and `/opt/hermes-guard` stay on the same commit. A bump
  is by hand, in all three places.
- **A compromised host means both kill switches, then a rebuild.** Signs: a root login you don't know,
  a changed `/etc`, an unknown process. Run the
  [bot's](ticket-bay-bot/kill-switch.md) and
  [Tania's](https://github.com/jrcopeti/tania/blob/main/vps/tania/kill-switch.md) kill switches, then
  rebuild the VPS.
- **Scripts are deployed by hand.** Nothing on the host clones either repo. A change here reaches the
  VPS only when José says yes and copies it.
