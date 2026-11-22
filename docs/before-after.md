# Before and after hardening

On 2026-11-17 a bug email told an agent to zero a refund fee, delete the failing tests and paste its
environment into a pull request. The model did part of it, and saved the email's instructions to its
memory too ([postmortem](https://github.com/jrcopeti/telma/blob/main/docs/hardening/postmortem-2026-11-17-prompt-injection.md)).
That agent ran every job in one Docker sandbox: the bug loop, PR triage and the owner's notes. The
job that read strangers' emails could read everything else too.

Two days later the bug loop and PR triage had moved to ticket-bay-bot, a second agent with its own
Linux user, sandbox and credentials. The notes stayed with Telma.

This page compares two audits from the bot's side: [before](https://github.com/jrcopeti/telma/blob/pre-split/docs/hardening/audit-before.md)
(read-only, 2026-11-17) and [after](https://github.com/jrcopeti/telma/blob/pre-split/docs/hardening/audit-after.md)
(with probes from inside the sandbox and an [injection suite](https://github.com/jrcopeti/telma/blob/pre-split/docs/hardening/injection-suite.md),
2026-11-19). Both ran while the bot still lived in Telma's repo. Telma's side is in
[her before/after page](https://github.com/jrcopeti/telma/blob/main/docs/before-after.md).

## Legs per session

A session leaks data when it holds all three legs: private data, untrusted input and a way out
([threat model](threat-model.md#the-lens-the-lethal-trifecta)).

| Session | Before | After |
|---|---|---|
| bug-loop (unattended) | **3**: strangers' emails; the owner's notes and a token for every repo; open network | 2: strangers' emails; an allowlist of three hosts. Its only secret is its own 1-hour token for one fork |
| PR triage (unattended) | **3**: anyone's PRs; the same sandbox as the bug loop | 2: anyone's PRs; the same allowlist. Its only secret is a 1-hour read-only token |

Before, the weakest input reached the strongest data, and the injection came in through a bug email.
After, the bot has nothing worth stealing but its own token, which reaches one fork and dies
within the hour. The threat model counts that as two legs and says how the token could still leak.

## Private data

| Item | Before | After |
|---|---|---|
| The owner's notes | read-write in the one sandbox every job used | out of reach: the bot is another Linux user and can't list them |
| GitHub | a classic token (repo, gist, read:org) mounted in the sandbox: every private repo on the account | rotated. A GitHub App token minted on the host for each run: one hour, one fork |
| Mailbox password | mounted in the sandbox | rotated, host only. A host script fetches the mail and hands the bot one email as a file |
| OpenRouter key, Discord token | host only | host only; probes found none in the sandbox |
| Customer orders | no tool reached them | still none: the bot's TicketBay tools leave out the one that returns orders |

## Untrusted input

| Source | Before | After |
|---|---|---|
| Bug emails | read by the agent that held the notes | the bot's alone: one email per run, mounted read-only |
| PRs and comments on the fork | the same | the bot's alone |
| The upstream skills repo | pulled every day by a root cron job and loaded as it came | pulled by a no-login `skills-sync` user after a 7-day wait, scanned, mounted read-only |
| npm packages | installed in the shared sandbox, install scripts on | installed in the bot's sandbox, install scripts off |
| Discord | the owner only | the owner only |

## Ways out

| Path | Before | After |
|---|---|---|
| Network from the sandbox | Docker's default: anywhere | an internal network whose only exit is a squid allowlist: GitHub and npm |
| Python or Node network code | the command guard only matched `curl`, `wget` and `nc` | every probe got a 403, and no DNS without the proxy |
| `code_execution` | on, and the guard didn't watch it | off |
| Gists | the token's gist scope | the App token gets a 403 |
| Email over SMTP | the app password could send mail | no mail credential |
| A PR body on the public fork | open: opening PRs is the job | still open, for the same reason. An obedient model could paste its 1-hour token there (accepted) |
| Push to the fork's `main` | classic branch protection | a ruleset: a PR with one approval and green CI, no force push or deletion, and only the owner can bypass it. The classic rule is gone |

## Persistence

| Tool | Before | After |
|---|---|---|
| `memory` | on for every job, and poisoned once | on, so the bot learns. A daily diff shows the owner what it saved |
| `skill_manage` | on for every job | on; the same diff covers it |
| `cronjob` | on: an injected run could schedule itself | off |
| Root cron jobs | the skills pull | none: the skills pull runs as `skills-sync` |

## Detection and response

| Signal | Before | After |
|---|---|---|
| Blocked egress | none | squid's denials posted to the ticket-bay channel every 10 minutes |
| Memory and skill changes | none | a diff to Discord every morning, with the line that undoes each change |
| Kill switch | none | [a runbook](../vps/ticket-bay-bot/kill-switch.md): `hermes gateway stop --yes`, since without `--yes` it refuses while a session runs |

## What is still open

The [threat model](threat-model.md#accepted-risks) says what was accepted and why. In short:

- The allowlist trusts whole platforms. The bot can reach any account on GitHub or npm, not only its
  own, so an email carrying an attacker's token could have it push there.
- An obedient model could paste its 1-hour token into a PR body.
- Memory and skills stay writable, so an injection that lands persists until the owner reads the
  diff.
- The test gate checks that the tests pass, not that they're still there. An email that gets the
  bot to delete the tests that catch a bug, as the 2026-11-17 one asked, turns the gate green. The
  owner's approval of every PR and the fork's CI are the wall.
- The model the bot runs refused every injection case it was given. The one model that obeyed never
  got as far as a commit, so the walls behind it were proved by probes, not by a model that tried to
  get past them.
