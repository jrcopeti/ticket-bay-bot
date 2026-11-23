# 5. Memory and `skill_manage` stay on

Status: accepted, 2026-11-18; the diff runs hourly since 2026-11-23

## Context

Hermes gives an agent two ways to keep something between runs: `memory`, notes it reads at the start
of every session, and `skill_manage`, which lets it write or edit its own skills. With both, the bot
gets better at the fork: how its tests run, what a fix there usually looks like.

They are also how an injection outlives the run that read it. On 2026-11-17 a bug email got the
agent of the time to save its instructions to memory, and every session loaded them for about three
hours ([postmortem](https://github.com/jrcopeti/telma/blob/main/docs/hardening/postmortem-2026-11-17-prompt-injection.md)).

Turning both off would close that door, and the bot would start from zero every run.

## Decision

Both stay on, so the bot learns. Nothing blocks what it saves. Instead, a script with no model in it
(`memory-diff.sh`) snapshots the bot's memory and skills every hour and posts what changed to the
ticket-bay channel, with a restore command for the files it shows. A long diff is cut at 1,500
characters, with the command that shows the rest. It's silent when nothing changed.

## Consequences

- An injection that saves itself lasts until the owner reads the next post and undoes it. The post
  comes within the hour.
- Detection depends on the owner reading the channel. Nothing reverts a change on its own.
- In the injection suite (B5) the model refused to save the planted note, so the diff has not yet
  caught a real one ([threat model](../threat-model.md), threat 8).
