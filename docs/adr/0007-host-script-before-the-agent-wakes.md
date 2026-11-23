# 7. A host script runs before the agent wakes

Status: accepted, 2026-11-18

## Context

The bug loop and PR triage run on a schedule. Each needs some setup that holds a secret: reading the
support inbox needs the mailbox password, and talking to GitHub needs a token minted with the App's
private key. If the agent did that itself, those secrets would sit in the sandbox that reads
strangers' text.

Most scheduled runs also find nothing to do. Starting the model anyway costs money and posts noise.

## Decision

Before each run, a script on the host, outside the sandbox, does the setup and decides whether the
agent wakes at all:

- **Bug loop** ([bug-loop-pre.sh](../../vps/ticket-bay-bot/bug-loop-pre.sh)): claims the oldest
  open bug email, writes it to a file the sandbox mounts read-only, posts the picked-up ping, and
  mints a 1-hour write token. An empty inbox stops there.
- **PR triage** ([pr-triage-pre.sh](../../vps/ticket-bay-bot/pr-triage-pre.sh)): mints a 1-hour
  read-only token and counts the fork's open PRs. No open PR stops there.

When it stops, Hermes skips the run: no model call, no message. A skipped run ends no session, so
the revoke hook wouldn't fire; the script revokes the token it minted on any exit that doesn't wake
the agent (since 2026-11-23).

## Consequences

- The mailbox password and the App's key never enter the sandbox. The agent gets one email as a file
  and a token that is revoked when the run ends.
- Quiet days cost nothing.
- The script checks that there is work. It doesn't read the email for injections: the email reaches
  the model as written, and the sandbox's walls are what contain it.
