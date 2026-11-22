# Hardening: ticket-bay-bot

**Goal:** ticket-bay-bot never holds all three legs of the lethal trifecta (private data, untrusted
input, a way out). Permissions, mounts and the network enforce every control. Prompts and command
regexes don't count as controls.

**History:** the bot was split from Telma by trust boundary on 2026-11-17 and hardened together with
her (steps 0 to 6). That work is in jrcopeti/telma at tag `pre-split`:
[PLAN](https://github.com/jrcopeti/telma/blob/pre-split/docs/hardening/PLAN.md),
[DEVLOG](https://github.com/jrcopeti/telma/blob/pre-split/docs/hardening/DEVLOG.md),
[audit after](https://github.com/jrcopeti/telma/blob/pre-split/docs/hardening/audit-after.md).
This repo was split from Telma's on 2026-11-19.

## Decisions in force

- **A repo of its own, along the trust boundary.** The bot never writes here: its GitHub App is
  installed on the ticket-bay fork only and is never added to this repo. `main` has a ruleset: PR
  required, no force push, no deletion, `gitleaks` required.
- **GitHub identity: an App, not a machine account.** `ticket-bay-bot` is a GitHub App owned by the
  owner's account and installed on the ticket-bay fork only. Its PRs show as `ticket-bay-bot[bot]`. A host-side
  script mints a 1-hour token for each run.
- **Its own OpenRouter key,** with its own credit limit.
- **No private data.** No brain, no long-lived secret in the sandbox. Email is fetched on the host and
  handed to the agent as a file. TicketBay's MCP server is connected with no key, and its tool
  include-list leaves out `my_orders`: customer data would bring back the private-data leg.
- **Egress through squid only.** The sandbox's only way out is a squid allowlist (`github.com`,
  `api.github.com`, `registry.npmjs.org`), with npm install scripts off. Squid's denials are posted
  to the ticket-bay channel every 10 minutes: a blocked request from the sandbox is the clearest sign
  of an injected run.
- **The allowlist trusts whole platforms, as an accepted risk** (the owner, 2026-11-19). Squid sees
  only the CONNECT host, so any account on the three hosts is reachable. An injected email carrying
  the attacker's own GitHub or npm token could have the bot push, open a gist or `npm publish` what
  it read, or pull a payload. Nothing denies or alerts on it. Narrowing it would take TLS inspection,
  or moving git and `gh` work to the host and npm behind a mirror: not now.
- **An obedient bot can paste its 1-hour token into a public PR, as an accepted risk** (the owner,
  2026-11-19, step 6's B9). The terminal guard blocks the plain ways (`hosts.yml`, `gh auth token`,
  `printenv`); a reworded command or the file tool gets past it. The token reaches the fork only and
  dies within the hour.
- **Skills come from `dmoka/skills`, gated.** A `skills-sync` user owns the bot's copy in
  `/opt/dmoka-skills`, which the sandbox mounts read-only. An upstream commit is taken after a 7-day
  wait, and only if Hermes's skills guard (`/opt/hermes-guard`) finds nothing new. Hermes is pinned.
- **The bot learns: memory and `skill_manage` on.** An injected run can save something every later
  run reads; that's accepted for the learning. A daily diff of its memory and skills goes to Discord,
  and the owner undoes what looks planted.
- **The ticket-bay fork gets security patches, not Renovate** (the owner, 2026-11-19). Upstream owns its
  dependency versions. A Dependabot alert on what the VPS runs is fixed on the fork's `main` with the
  smallest version that closes it, by hand, one PR.

## Open

- The test gate: Hermes stopped waiting for a hook after 30 s, so a red verdict came too late.
  Timeout raised to 300 s on 2026-11-18; check on the next bug-loop run that edits code.
- `zod` (< 4.6.6) and `source-map-js` Dependabot alerts on the fork stay open.
- Step 4 proof still to see: the first real skills update or block.
- Lesson 8.5 (email 2, steps 14 and 15) and 8.6: run them on the bot. Moved here from Telma's frozen
  hardening plan on 2026-11-19.
