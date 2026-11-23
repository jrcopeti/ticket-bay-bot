# 2. Egress through squid only

Status: accepted, 2026-11-18

## Context

Before the split, the sandbox used Docker's default network: it could reach any host. The command
guard blocked `curl`, `wget` and `nc`, but a line of Python or Node walked past it. An injected
email could have sent anything the sandbox read to any server.

The bot needs only three hosts to do its job: GitHub's site and API to push and open PRs, and the npm
registry to install the fork's dependencies.

## Decision

The sandbox sits on an internal Docker network with no route out. Its only exit is a squid proxy
that allows TLS to `github.com`, `api.github.com` and `registry.npmjs.org`, and nothing else. npm
install scripts are off. A no-agent job posts squid's denials to the ticket-bay channel every 10
minutes.

## Consequences

- A probe from the sandbox got a 403 for Python, Node and a raw IP, and no name resolves without
  the proxy ([threat model](../threat-model.md), threat 1). [CI tests](../../vps/ticket-bay-bot/egress/test-egress.sh)
  check the squid config.
- A blocked request is the clearest sign of an injected run, and the owner sees it within 10
  minutes.
- Squid sees only the host name, so it trusts whole platforms: any account on GitHub or npm is
  reachable. An email carrying an attacker's token could have the bot push there. Narrowing that
  would take TLS inspection, or moving git to the host and npm behind a mirror. Accepted for now
  ([threat model](../threat-model.md#accepted-risks)).
