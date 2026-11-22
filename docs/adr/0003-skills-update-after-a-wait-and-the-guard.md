# 3. Skills update after a 7-day wait and the guard

Status: accepted, 2026-11-18

## Context

The bot's skills, the instructions for fixing a bug and reviewing a PR, come from an upstream skills
repo the owner doesn't control. Before the split, a root cron job pulled it every day and the agent
loaded whatever arrived. One bad upstream commit would have been in the next run.

Reading every upstream diff by hand was the other option. It's safe, but it doesn't get done.

## Decision

A system user, `skills-sync`, with no login, owns the bot's copy of the skills in `/opt`. It fetches
every day, but takes a commit only once it has waited 7 days, counted from its own fetch log because
commit dates can be backdated. Then Hermes's skills guard scans the incoming commit, and any finding
the current copy doesn't already have blocks it. The bot's sandbox mounts the skills read-only.

## Consequences

- A planted commit has a week to be noticed and reverted upstream before the bot sees it.
- The skills update without the owner reading each diff. The daily status in the ticket-bay channel
  says whether a commit was taken, blocked, or the fetch failed.
- The guard matches patterns. A finding it doesn't know gets through, and so does a second hit on a
  pattern in a file where the current copy already has one.
- No real update or block has been seen yet: the proof so far is the
  [tests](../../vps/skills-sync/test-skills-update.sh).
