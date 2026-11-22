# 4. Security patches on the fork, not Renovate

Status: accepted, 2026-11-19

## Context

TicketBay is a fork. Its upstream decides which dependency versions it runs. The VPS runs the fork,
so a vulnerable dependency there is the owner's problem, but routine updates would make the fork
drift from upstream.

Renovate would open a PR for every new version, and the bot could review them. That suits a repo the
owner fully owns. Here it would be a steady stream of changes nobody needs.

## Decision

Dependabot alerts are on for the fork; version-update PRs are off. When an alert hits something the
VPS runs, the owner fixes it on the fork's `main` with the smallest version that closes it, by hand,
in one PR.

## Consequences

- The fork stays close to upstream, and each change on it has a reason.
- An alert waits until the owner gets to it.
- Security patches land on `main`, the bug loop's only base, so there's no second branch to keep
  patched ([ADR 6](0006-demo-bugs-planted-on-main.md)).
