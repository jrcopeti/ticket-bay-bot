# 1. A GitHub App, not a machine account

Status: accepted, 2026-11-18; tokens revoked when the run ends since 2026-11-23 (#16)

## Context

The bot pushes branches and opens pull requests on the ticket-bay fork, so it needs a GitHub
identity. Before the split, the agent used the owner's classic token (repo, gist, read:org), which
reached every private repo on the account. The token sat in the same sandbox that read strangers'
emails.

The usual alternative is a machine account: a second GitHub user for the bot, with a personal access
token stored where the bot runs. That token lives for months and works on any repo the account is
added to.

## Decision

`ticket-bay-bot` is a GitHub App owned by the owner's account and installed on the fork only. A host
script mints a token for each run: write for the bug loop, read-only for PR triage. Each token lasts
one hour at most: a hook revokes it when the run ends. The App's private key stays on the host,
outside the sandbox. Its pull requests show as `ticket-bay-bot[bot]`.

## Consequences

- The only GitHub secret the sandbox ever sees reaches one fork and is revoked when the run ends,
  minutes after the PR, not the rest of the hour. In the injection suite, the run's own token got
  a 403 on gists and on `/user`, and no rights on the upstream repo ([threat model](../threat-model.md), threat 2).
- The App can't approve its own pull requests, and the ruleset on `main` needs an approval, so
  nothing the bot writes reaches `main` without the owner.
- The App is never installed on this repo: the bot must not edit its own controls.
- An obedient model can still paste its token into a public PR, and it works until the run ends.
  If the revoke fails, the owner gets a ping and the token lives its hour. That's an
  [accepted risk](../threat-model.md#accepted-risks).
