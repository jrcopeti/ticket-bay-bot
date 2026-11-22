# Showcase: the public docs

**Goal:** a reader who lands on `jrcopeti/ticket-bay-bot` understands what the bot does, what
threatens it and why each control exists, without reading the devlogs. The fork `jrcopeti/ticket-bay`
is the other half of the showcase: the bot's real PRs live there, and they're the proof it works.
At least five of them fix bugs planted in the fork and reported by email.

**Why:** Telma's [showcase plan](https://github.com/jrcopeti/telma/blob/main/docs/showcase/PLAN.md)
gave this repo the bug-loop demo and the bot's before/after rows (the owner, 2026-11-19 and
2026-11-20), but nothing here tracked them. This repo has no README, threat model or ADRs, and the
fork's README doesn't say the bot works there.

**Done when:** the steps below are done, the fork holds at least five bot PRs that fix planted bugs,
and every item in Open is decided or done.

TicketBay and the bot's skills started from open-source repos, credited once in the README; they're
the owner's product now, and the docs treat them that way.

## Rules

- Agents draft the docs; the owner approves each one in its PR.
- One doc per branch and PR, in this order: personal-data net, threat model, before/after table,
  ADRs, the bot's live files, demo bugs, the fork's README section, this repo's README last, so each
  README links docs and PRs that exist.
- No secrets or personal data, in screenshots and GIFs too. Before each PR, an agent reads the whole
  diff for personal data the scan can't catch (names, private repo names, home paths, anything from
  an email), as a safety net on top of gitleaks.
- Changes to the fork (the demo-bug kit, the README section) are the owner's PRs, never the bot's.
- Every bug-loop run is started by the owner, or by the daily job the owner switched on. Agents ask
  first.

## Steps

| # | Doc | Notes | Status |
|---|---|---|---|
| 1 | **Personal-data net** | `.gitleaks.toml` already blocks email addresses, IPs, Discord IDs and webhooks, and Tailscale hosts, in the pre-commit hook and in CI. Add what it misses: local home paths (`/Users/<name>`), and the private repo names and other exact values from an untracked local list the hook reads, so the list itself never lands here. Images: strip EXIF and GPS data before a PNG or GIF is committed. | |
| 2 | **Threat model** | `docs/threat-model.md`: the lethal trifecta per job (bug-loop, PR triage, pull-repos, skills-sync), which leg each control cuts, and the accepted risks from the hardening plan's Decisions. Same shape as Telma's [threat model](https://github.com/jrcopeti/telma/blob/main/docs/threat-model.md). | |
| 3 | **Before/after table** | `docs/before-after.md`, from the rows parked in the brain inbox (`2026-11-20-bot-rows-from-telma-before-after.md`): the bot-only rows, plus the overlaps that also stay in Telma's table. Sources: Telma's audit-before, audit-after and injection suite at tag `pre-split`. | |
| 4 | **ADRs** | `docs/adr/`, short, one per decision the owner picks. Candidates: a GitHub App, not a machine account; egress through squid only; skills updated after a 7-day wait and the guard; security patches on the fork, not Renovate; memory and `skill_manage` on; demo bugs on a `demo` branch, not `main`. The split and one repo per agent link Telma's ADRs 2 and 3. | |
| 5 | **The bot's live files** | Copies of what runs on the VPS that this repo doesn't hold yet, so a reader sees the whole setup (Telma's step 5 is the same). Its `SOUL.md`; its `config.yaml` (models, fallback order, toolsets) with channel IDs and personal data removed; the hooks config that wires `guard-network.sh` and `verify-tests.sh` in `~/.hermes/agent-hooks/`; the cron prompts from `jobs.json` (bug-loop, PR triage, pull-repos, memory-diff, squid-denials), with the inbox address removed; and the skills the bot runs (`bug-triage`, `pr-triage`). Never memories, skills the bot saved itself, `auth.json`, `channel_directory.json`, the App's key or anything else in its home. The scripts and hooks already in `vps/` (mapped in `vps/host.md`) are covered and stay as they are. Each new copy gets a row in `vps/host.md`'s deploy table. Before the PR, the agent diffs every file in `vps/` with the VPS, old and new, so a stale copy shows; the known differences (the inbox address in `support-inbox`, comments in `memory-diff.sh`) are listed in `host.md`. | |
| 6 | **Demo bugs** | At least five bugs planted on the fork's `demo` branch, each sent as a customer email, each fixed by the bot in its own PR against `demo`, so `main` stays clean for readers. The bug-loop job on the VPS takes `demo` as its base (a VPS change the owner deploys). The PRs stay open as evidence and are never merged, so each bug stays planted for the next run. A `demo-bugs/` kit on `demo`: one folder per bug with its patch and its email, and a script that plants it. Recipe (the brain's demo-bug kit): one small, realistic mistake in `src/domain/` (one number or one operator), the tests that would catch it removed or loosened, and an email that describes the symptom with numbers, not the cause. Candidates, not yet checked against the code: refund window `<` vs `<=`, service-fee rounding, VAT on gross, early-bird cutoff off by one day, the group discount at exactly 10 tickets (lesson 8.5's bug). | |
| 7 | **The fork's README section** | A short section at the top of `jrcopeti/ticket-bay`'s README: ticket-bay-bot works here, PRs by `ticket-bay-bot[bot]` are its, the demo PRs target `demo`, the ruleset on `main`, and a link to this repo. | |
| 8 | **README** | Readable for a non-technical reader, per the brain's prose-docs guideline. Shows the bug loop (shot list below) and PR triage, the numbers below, links the bot's demo-bug PRs on the fork, its live files with `vps/host.md` as the map of the whole setup, Telma's repo, the threat model, ADRs and kill switch. | |

## Open

Decided (the owner, 2026-11-22):

- ~~Which numbers go in the README.~~ All the candidates: bug-loop runs, PRs the bot opened on the
  fork and how many were merged, PR-triage verdicts (✅/🤔/⚠️), cost per run (OpenRouter), and
  test-gate verdicts (`verify-tests.log`).
- ~~Which fork PRs a reader sees.~~ The open PRs from before (#11 to #13 under the owner's login,
  #16 by the bot) are closed before the README goes out; the README links only the demo-bug PRs.
- ~~Where the bugs are planted.~~ On a `demo` branch the bug loop uses as its base; `main` stays
  clean (step 6).
- ~~Merge the demo PRs or keep them open.~~ They stay open as evidence (step 6).

## Screenshot shot list (the owner captures)

PNGs, or one short GIF, into `docs/assets/`. An agent checks each one for personal data before it's
committed. Blur or crop: the inbox address, the sender's address, Discord server and channel names
other than the ticket-bay ones, user names and avatars other than the bot's and the owner's, IPs,
webhook URLs and URLs of private repos.

1. **The email:** a bug report sent to the support inbox.
2. **The ping:** the bot's 🎫 message in the ticket-bay channel when it claims the email.
3. **The PR:** the PR it opened on the fork, with its test and the test gate's verdict.
4. **PR triage:** a morning triage post in Discord.
5. **An alert:** a `🚫 squid blocked` post (crop the IP).
6. **Optional GIF:** 20 to 30 seconds of 1 to 3.
