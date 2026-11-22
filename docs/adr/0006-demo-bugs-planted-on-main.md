# 6. Demo bugs planted on `main`

Status: accepted, 2026-11-22

## Context

The bot's pull requests on the fork are the proof that it works. To show the bug loop end to end,
the fork needs real bugs to fix: a customer email describing a symptom, and the bot's PR fixing the
cause with a test.

The bugs could go on a separate `demo` branch. But the bug loop opens every PR against one base, so a
`demo` base would catch every other email too, and switching the base for a demo session is one more
thing to get wrong.

## Decision

At least eight small, realistic bugs go on the fork's `main`, each through a PR by the owner, each
reported by email. The bot fixes each in its own PR against `main`. The owner merges three, so a
reader sees the loop end in a merge. The rest stay open as evidence, so those bugs stay planted.
None is planted yet.

## Consequences

- One base for everything: the PR page reads "into main", and security patches
  ([ADR 4](0004-security-patches-not-renovate.md)) leave no demo branch to rebase.
- `main` will carry known bugs. The fork's README will list them, with the open PRs that fix them.
- The planting is the owner's work, never the bot's.
