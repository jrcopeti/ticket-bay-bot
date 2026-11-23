# Devlog: hardening

Entries before 2026-11-19 are in jrcopeti/telma at tag `pre-split`
([DEVLOG](https://github.com/jrcopeti/telma/blob/pre-split/docs/hardening/DEVLOG.md)).

## Branches

| Branch | Step | State |
|---|---|---|
| `main` | import | first commit |
| `docs/unversioned-scripts` | after import | merged (#1) |
| `chore/own-host-scripts` | after import | merged (#2) |
| `chore/add-vps-only-scripts` | after import | merged (#5) |
| `chore/sandbox-dockerfile` | after import | merged (#6) |
| `chore/rename-telma` | after import | merged (#7) |
| `docs/lessons-8-5-8-6-open` | after import | merged (#8) |
| `chore/memory-diff-hourly` | memory-diff | merged (#14) |
| `hardening/revoke-token-after-run` | revoke token | merged (#16) |
| `docs/deploy-14-16` | deploy | merged (#17) |
| `fix/revoke-long-tokens` | revoke token | merged (#18) |
| `docs/required-checks` | ruleset | merged (#19) |
| `docs/deploy-18` | deploy | merged (#20) |
| `fix/publish-pr-review` | PR triage | PR open, on top of `docs/live-files` |

## 2026-11-19: imported from jrcopeti/telma

- The bot's files were copied from jrcopeti/telma at `pre-split`, unchanged, with the same paths:
  `vps/ticket-bay-bot/`, `vps/skills-sync/` and `vps/ticket-bay-app/`.
- `memory-diff.sh` and its test moved from `vps/shared/` to `vps/ticket-bay-bot/`, and only their
  comments changed. The kill switch links to Telma's.
- New for this repo: `AGENTS.md`, `vps/host.md`, this plan and devlog, and CI with the bot's jobs only.
  The hooks, gitleaks rules and secret scan are Telma's, with the title changed.
- The VPS is unchanged: scripts are deployed by hand, and nothing on the host reads either repo.

## 2026-11-19: VPS checksum (read-only)

All 11 deployed files this repo holds match it byte for byte (bot scripts, skills-sync, egress,
app), except `memory-diff.sh`, whose deployed copy differs only in the header comment. The checksum
also found five deployed scripts in no repo (Open in [PLAN.md](PLAN.md)). The full check is in
jrcopeti/telma's [repo-split devlog](https://github.com/jrcopeti/telma/blob/main/docs/repo-split/DEVLOG.md).

## 2026-11-19: the bot's own host scripts

- Added `mint-gh-token.sh`, `bug-loop-pre.sh`, `pr-triage-pre.sh` and `set-secret`, copied from the
  VPS byte for byte (the owner: they work, don't change them). gitleaks found nothing: they read their
  secrets from files under `~/.config` and never hold one themselves. No tests yet: each one needs
  GitHub, Gmail or a terminal.
- `vps/host.md` now maps every file here to its path on the VPS.
- Three more files on the VPS (`guard-network.sh`, `verify-tests.sh`, `support-inbox`) stayed out of
  this step; the next entry adds them. `set-secret` was found next to `support-inbox`.

## 2026-11-19: the VPS-only scripts into the repo

- Added `guard-network.sh` (the terminal guard), `verify-tests.sh` (the test gate) and `support-inbox`
  (claims bug emails), copied from the VPS (mode 755). The owner: publish them.
- Read for secrets first. None: the scripts read their passwords from files. `support-inbox` held the
  bug inbox address, replaced here with a placeholder; the deployed copy keeps it. The other two match
  the VPS byte for byte. Telma's deployed `guard-network.sh` is identical (jrcopeti/telma#24).
- `vps/host.md` maps each to its VPS path. No tests: each needs a Hermes payload, Docker or Gmail.

## 2026-11-19: the sandbox Dockerfile into the repo

- Added `vps/ticket-bay-bot/sandbox/Dockerfile`, byte for byte from `~/sandbox/` on the VPS. A second
  checksum (jrcopeti/telma's repo-split devlog) found it in no repo. No secret; not code from the course.
  It differs from Telma's in one line: an `AGENT_EMAIL` build arg.
- Every deployed file now has a copy here or in Telma's repo. Differences: `memory-diff.sh` (comment
  lines) and `support-inbox` (the inbox address).

## 2026-11-19: the other agent renamed Telma

- Step 3 of jrcopeti/telma's [rename plan](https://github.com/jrcopeti/telma/blob/main/docs/rename/PLAN.md):
  her old name became Telma in all 7 files that named her, links included. The links work once that
  repo is renamed (its step 4).
- `guard-network.sh` and `verify-tests.sh` changed in comments only. Until step 5 redeploys them,
  their VPS copies differ from these in those comment lines. `guard-network.sh` is still byte for byte
  the same as Telma's.

## 2026-11-19: lessons 8.5 and 8.6 moved here

- They sat in Open in Telma's frozen hardening plan. They run on the bot, so they're tracked here now.

## 2026-11-23: memory-diff hourly

- The owner's call: memory-diff runs every hour instead of once a day, so something planted in the
  bot's memory or skills shows within the hour. It's a script, no model, and silent when nothing
  changed, so an hourly run costs nothing.
- `pull-repos.sh` no longer calls it; memory-diff gets its own Hermes no-agent job, like
  squid-denials. pull-repos still reports the skills update daily at 07:55.
- Not deployed yet: the VPS change (new hourly job, the two scripts copied) waits for the owner's yes.
- `/code-review` (default effort, all findings) found 11. Fixed, each with a test that fails on the
  old scripts: the undo and full-diff lines named `HEAD`, which moves on every hour, so they now name
  the run's own commit; a lock left by a killed run would fail every later run, so one older than 30
  minutes is removed; pull-repos's status path can be pointed at a test file; a test checks that
  pull-repos no longer runs memory-diff. `host.md` says the two scripts and the hourly job deploy
  together, and the kill switch says the undo line names its own snapshot.
- Not fixed: the docs say hourly before the VPS does; this PR merges after the deploy. The test that
  planted hooks don't run is kept as a guard, though pull-repos no longer runs git at all.
- Second `/code-review` (the owner asked) found 9, all fixed. memory-diff: every stale lock is
  cleared, not only `index.lock` (a killed commit leaves `HEAD.lock` or the branch's); a commit that
  keeps failing posts its diff once, not every hour; undo lines use the full SHA, and no undo line
  when it can't be read. The kill switch reads the snapshot's history instead of running
  memory-diff, which the hourly job has usually run already. `host.md` describes the setup instead
  of saying "not deployed"; the showcase plan's known VPS differences match it. The pull-repos
  tests clone only where the hook test needs it.
## 2026-11-23: revoke the token when the run ends

- The owner, reviewing the before/after page: "dies within the hour" reads as harmless only because
  the fork is a demo; on a real repo an hour of write access is plenty. Options weighed: the host
  pushes and opens the PR, so the sandbox holds no token (about one PR of code plus a deploy), or
  revoke the token when the run ends. The owner's call: revoking is enough.
- Checked first: `mint-gh-token.sh` already narrows each token to the fork and to `contents` and
  `pull_requests` (read for triage), with no `workflows`.
- `revoke-gh-token.sh`, a Hermes `on_session_end` shell hook (in `VALID_HOOKS`; `turn_finalizer`
  fires it after every turn, failed or interrupted too). It acts only when `extra.platform` is
  `cron` (`cron/scheduler.py` sets it): a chat turn ending mid-run would kill the job's token. It
  truncates `~/.config/gh/hosts.yml` (the sandbox mounts the folder read-only), then sends
  `DELETE /installation/token` with the token on stdin, not argv. 401 counts as done.
- Gap found: a PR triage run with no open PR never starts the agent, so no session ends and the
  hook can't fire. `pr-triage-pre.sh` now calls the hook itself before it skips. The bug loop mints
  only after it has claimed an email, so its skips hold no token.
- Not deployed yet: the hook, the new `pr-triage-pre.sh` and the `hooks:` entry wait for the owner's
  yes (`host.md` has the line).
- `/code-review` (default effort, all findings) found 11. Checked on the VPS's Hermes first: a cron
  run is one `run_conversation` call and pre_verify nudges stay in its turn, so the hook fires once
  per run; a model-unreachable re-run is a new job run that mints again. Fixed, with tests:
  `pr-triage-pre.sh` revokes on every exit that doesn't wake the agent (a failing `gh` too), with a
  `--now` mode instead of a faked payload; the hook revokes before it empties the login and keeps
  an unrevoked token in `~/.config/github-app/unrevoked-token` for the owner; no API URL from the
  environment; first `oauth_token` only, quotes stripped; only a `ghs_` token is sent, so a 401
  means it's dead; the threat model's other "1-hour" cells; the open GitHub question is back.
- Not fixed: one `hosts.yml` for both jobs, so a cron run that ends while another runs revokes its
  token. Triage (08:00) and bug-loop (09:00) don't overlap; a run started by hand at the same time
  could. The jq-missing branch has no test (jq is on every host path the tests use).
- Second `/code-review` (the owner asked) found 8, about a hook that never fires or a revoke that
  fails. Fixed, with tests: the mint revokes any token left in the login before it writes a new one
  (a run killed before its hook); a token that can't be revoked is appended to
  `~/.config/github-app/unrevoked-tokens`, not overwritten, and the owner gets a ping in the
  ticket-bay channel; a token that doesn't look like an App token is kept there too, not dropped;
  trailing spaces and comments are stripped; both pre-scripts set the revoke trap before the mint.
  The diagram puts the revoke with the Hermes hooks.
- Not fixed, now with a better outcome: triage running past 09:00. The bug loop's mint revokes
  triage's token first, so triage fails and never holds the write token. Its hook then fires and
  revokes the bug loop's new token too, so that run fails as well: both fail closed, and the email
  stays claimed (the `bug-loop-pre.sh` gap in the showcase devlog).

## 2026-11-23: #14 and #16 deployed

- The owner's yes, after both merged (01:21 and 01:28). #14's entry said it would merge after the
  deploy; for those minutes `main` described a setup the VPS didn't run yet. Copied by hand at 01:30
  Berlin, before any job was due:
  `pull-repos.sh`, `memory-diff.sh`, `mint-gh-token.sh`, `bug-loop-pre.sh` and `pr-triage-pre.sh` to
  `~/.hermes/scripts/`, `revoke-gh-token.sh` to `~/.hermes/agent-hooks/`. Each deployed copy was
  diffed against the repo first: the differences were the PRs' changes and nothing else. The
  checksums now match the repo. The old copies are kept as `*.bak-deploy-20261123`, with
  `config.yaml`, the hook allowlist and `jobs.json`. They go once memory-diff and a triage run have
  run clean on the new files.
- New no-agent job `memory-diff`, every 60 m, delivered to Discord. Nothing was run by hand.
- `on_session_end` entry added under `hooks:` in `config.yaml`. A cron run skips a hook that isn't
  in `~/.hermes/shell-hooks-allowlist.json`, and `hermes hooks` can only approve every hook at once
  (`--accept-hooks`), so the one entry was written by hand in Hermes's own format, under its lock.
  `hermes hooks doctor` passes it; the gateway registered it at 01:32.
- `hermes hooks doctor` warns about `guard-network.sh` and `verify-tests.sh`: approved 2026-11-17,
  redeployed 2026-11-19 at 21:53. Their checksums match the repo, so the 2026-11-19 entry's "until
  step 5 redeploys them" is out of date. A changed script only warns: the gateway still registers
  both (its log, each restart).
- `host.md` says the hook needs its allowlist entry; showcase step 5 copies the allowlist too.

## 2026-11-23: the revoke hook's first run rejected GitHub's newer tokens

- 08:00, the first PR triage after the deploy: two pings in the ticket-bay channel, "the login holds
  a token that doesn't look like an App token". One came from the mint, cleaning up the 2026-11-22
  token; the other from the hook when the run ended. Both were `ghs_` tokens, but 390 characters
  long with `.` and `-`, and the check allowed only `[A-Za-z0-9_]`. The hook failed closed as built:
  login emptied, token kept host-side, owner pinged. Neither was revoked, so each lived its hour; at
  09:47 both answered 401. The bug loop at 09:00 claimed no email, so it minted nothing.
- Fix: the check takes `ghs_` plus letters, digits, `_`, `.` and `-`, in the C locale. Test with a
  token of the shape seen, matched exactly.
- `/code-review` found the secret scan had the same blind spot: gitleaks' default App-token rule
  wants exactly 36 alphanumerics after the prefix, so a new-format token with an early `_`, `.` or
  `-` went through. `.gitleaks.toml` has a rule for the long format now, with a hook test, and the
  full history scans clean with it.
- Second `/code-review` (the owner asked) found 9; 8 fixed, with tests. The first review's
  `[[:graph:]]` was too wide. A `ghs_` value with junk glued on (a tab-separated comment, a `,`,
  a non-ASCII letter) got a 401 and passed for revoked, with no ping; it's kept and reported again.
  The gitleaks rule got keywords and a test that names the rule; its first try without `\b` is
  replaced below. `PLAN.md`'s Open says the hook doesn't revoke yet.
- Not fixed: a review proposed the mint record that it wrote an App token, so the revoke wouldn't
  guess from the shape. A format change now fails closed with a ping, which is enough for now.
- Third `/code-review`, of that fix only (the owner asked), found 7, all fixed with tests. The value
  lost its spaces, tabs and quotes from anywhere in it before the check, so `ghs_x junk` became
  `ghs_xjunk` and still passed for revoked on a 401. Now only the ends are trimmed (a comment after
  whitespace, surrounding space, one pair of quotes), and junk inside fails closed. Without `\b`
  the gitleaks rule caught `laughs_…` in plain words; it now wants no letter or digit before the
  prefix, so `GH_ghs_…` is still caught. The locale test sets `LC_ALL`, which wins over `LANG`.
- Not deployed yet: the new `revoke-gh-token.sh` waits for the owner's yes. Until then, each run's
  token lives its hour and each run pings twice.
- Fourth `/code-review`, of that fix only (the owner asked), found 9, all fixed. Three rounds had
  patched the sed that trimmed the value, and each found a new quote or comment case, so the
  trimming is gone: the hook takes the value as the mint and gh write it (bare, no quotes, no
  comment), drops only a trailing space or CR, and any other shape is kept and reported. Tested
  with quotes, comments, `# none` and junk. The gitleaks rule no longer looks at the character
  before the prefix (it missed `\nghs_…` in a JSON log and `tokenghs_…`); it wants 80 or more
  token characters instead, which tokens have and snake_case words don't. Tests cover four
  neighbours. The locale case runs under `en_US.UTF-8` where it exists: on glibc (the VPS, CI) `é`
  falls inside `[A-Za-z]` there, and dropping the script's `LC_ALL=C` fails the test (checked on the
  VPS); macOS never puts it in the range, so there the case can't fail.

## 2026-11-23: every CI check required

- The owner's call. The ruleset on `main` required only `gitleaks`; it now requires all eight CI
  jobs: `gitleaks`, `hooks`, `skills-update`, `memory-diff`, `pull-repos`, `revoke-gh-token`,
  `squid-denials`, `egress`, each pinned to GitHub Actions. No workflow has a path filter, so each
  runs on every PR and none can block one by never reporting.
- A job renamed or added later has to be changed in the ruleset by hand: a required name that no
  longer runs blocks every PR.

## 2026-11-23: #18 deployed and tested

- Smoke test before the deploy, in a throwaway home on the VPS (no job, no live file): the mint
  wrote a real read token, 390 characters; GitHub answered 200 with it, the new
  `revoke-gh-token.sh --now` exited 0 and emptied the login, and GitHub answered 401 after.
- Deployed at 10:19 with the owner's yes; the checksum matches the repo. The new script's mtime
  made `hermes hooks doctor` warn, so its allowlist entry was re-approved the same way as the
  first time.
- The owner asked for a live run: `hermes cron run` on `pr-triage-morning`. The agent woke for the
  open PR, the triage went to Discord, and the login was emptied in the same second the turn ended
  (10:21:05). No ping, no hook warning, nothing kept in `unrevoked-tokens`.
- Clean-up, the owner's call: memory-diff had run 8 hours clean and the triage was clean, so the
  `*.bak-deploy-20261123*` backups are gone (scripts, hook, `config.yaml`, allowlist, `jobs.json`),
  and so is `unrevoked-tokens`, which held the two tokens from 08:00, both expired. The older
  `.bak-*` files from earlier steps stay.
- Still to see: the first scheduled triage at 08:00 tomorrow, and the first bug-loop run that
  claims an email (it mints a write token, so its hook is the one that matters most).

## 2026-11-23: publish-pr-review and the bug-loop prompt

Found by `/code-review` on showcase step 5, which copied both from the VPS.

- `publish-pr-review` deleted yesterday's tour pages before rendering today's. Under `set -e`, one
  failed render left the old index linking pages that were gone, and the Discord post linked them
  too. A tour with no PR number was written as `-pr-null.html`, and two tours for one PR overwrote
  each other. Tours now render into a staging folder in the output folder; yesterday's pages, the
  queue and the index change only when every tour rendered. A missing number or a repeated one
  stops the run with a message, which the prompt reports in its answer.
- Each page, the queue too, replaces its old one in a single rename: the tours first, so the queue
  never links a tour that isn't there yet, then the queue, and closed PRs' pages last.
- One run at a time (`flock`, in the sandbox image); a second run stops and changes nothing. With
  the lock held, a staging folder left by a killed run is removed. The PR number must be a JSON
  number, so `"007"` and `7` can't become two pages for one PR.
- Its header pointed to a config excerpt no repo has; it now points to `docker_volumes` in
  `config.yaml`. `OUT` and `RENDER` can be set from the environment, for the new test
  (`tools/test-publish-pr-review.sh`, 15 cases, a CI job). Its fake renderer wants `kind: "tour"`,
  like pr-tour's `render.mjs`.
- Not handled: tours from several repos, whose PR numbers can clash, and another repo whose name
  starts with `ticket-bay-pr`. The job triages one repo, so a clash stops the run.
- The bug-loop prompt said "Never touch other folders in /workspace/dev", while every other path in
  it is `/home/ticket-bay-bot/dev`: the same folder, mounted twice. It now names both.
- To deploy, with the owner's yes: `publish-pr-review` to `~/tools/`; the prompt to `~/tools/` and
  into `bug-loop`'s prompt in `~/.hermes/cron/jobs.json`. The new CI job goes into the ruleset.

