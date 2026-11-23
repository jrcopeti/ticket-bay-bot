# Devlog: showcase

## Branches

| Branch | Step | State |
|---|---|---|
| `docs/showcase-plan` | plan | PR #9 merged |
| `ci/personal-data-net` | 1 | PR #10 merged |
| `docs/threat-model` | 2 | PR #11 merged |
| `ci/private-values-followup` | 1 | PR #12 merged |
| `docs/before-after` | 3 | PR #13 merged |
| `docs/adr` | 4 | PR #15 merged |
| `docs/stale-lines` | 4 | PR #21 merged |
| `docs/live-files` | 5 | PR #22 merged |
| `chore/trim-live-files` | 5 | PR #27 merged |
| `feat/demo-bug-pack` | 6 | PR open |

## 2026-11-21: plan

- Telma's showcase plan handed this repo the bug-loop demo and the bot's before/after rows, but no
  plan here tracked them. The owner asked for one, mirroring Telma's.
- The owner's calls: the fork `jrcopeti/ticket-bay` is part of the showcase, since the bot's PRs
  live there (a README section on the fork, now step 7); agents draft the public docs and the owner
  approves, here too; the docs say "the owner"; `AGENTS.md` no longer says only the owner pushes.
- Renamed to "the owner" in `AGENTS.md`, the hardening plan and devlog, `vps/host.md` and a comment
  in `memory-diff.sh`. The deployed `memory-diff.sh` already differed in its header comment; it now
  differs in one more comment line.
- The owner asked for at least five bot PRs from planted bugs sent by email: demo bugs, now step 6,
  with a `demo-bugs/` pack on the fork. Its candidate bugs come from the brain's demo-bug pack note and
  aren't checked against the code yet.
- The ADR list is candidates only, from the hardening plan's Decisions; the owner picks.

## 2026-11-22: plan review

- The owner decided the Open items: the candidate numbers go in the README; the old fork PRs (#11
  to #13, #16) are closed and the README links only the new demo-bug PRs.
- "How many were merged" would read 0 with every demo PR open, so the owner raised the demo to
  eight bugs: three PRs merged, five left open. The number stays.
- Where the bugs go, first `demo`, then `main`. Review found a `demo` base would also catch every
  other email, and the owner ruled out switching the base for a demo session, then left the call to
  Claude: `main`. One base, PRs read "into main" on the fork's PR page, and security patches leave
  no demo branch to rebase. Cost: `main` carries the bugs; the fork's README section lists them.
- The brain's demo-bug pack note was Telma's, from before the split. A ticket-bay-bot pack is captured
  in the brain inbox (2026-11-22) and step 6 points to it. Step 3 points to the before/after rows in
  the brain's `sources/`, where triage moved them.
- README step: dropped the `crafting-effective-readmes` skill; the brain's prose-docs guideline
  covers how the README is written.
- The upstream TicketBay and skills repos are out of the steps: TicketBay and the skills are the
  owner's product now, and one sentence under the goal says they started as open source and get
  credited once in the README.
- New step 1, personal-data net. `.gitleaks.toml` already had rules for emails, IPs, Discord IDs,
  webhooks and Tailscale hosts; the step adds home paths, an untracked local list of exact values
  (private repo names), and EXIF stripping for images. A new rule has an agent read each PR's
  diff for what no regex catches.
- New step 5, the bot's live files, mirroring Telma's step 5: `SOUL.md`, a redacted `config.yaml`,
  the hooks config, the cron prompts from `jobs.json`, and the `bug-triage` and `pr-triage` skills.
  Memories and self-saved skills stay off. The exact file names on the VPS aren't checked yet; the
  step's agent lists them before copying.
- The scripts already mirrored (`mint-gh-token.sh`, `bug-loop-pre.sh`, `pr-triage-pre.sh`,
  `set-secret`, `support-inbox`, `guard-network.sh`, `verify-tests.sh`) stay as they are. Step 5
  now diffs every file in `vps/` with the VPS, old and new, before its PR. The README links
  `vps/host.md` as the map of the setup.

## 2026-11-22: step 1, personal-data net

- `.gitleaks.toml` gets a `home-path` rule for `/Users/<name>` and `/home/<name>`, relative ones
  (`../../Users/<name>`) too. The bot's VPS users (`ticket-bay-bot`, `telma`) and `/Users/Shared`
  are allowed; a path glued to a variable (`$W/home/dev`, `${W}/home/dev`) isn't a home path.
- Gotcha: gitleaks' default allowlist drops any secret matching `^/(?:bin|etc|home|...)/...$`, so a
  rule whose secret is the whole `/home/...` path never fires. The rule's secret is the user name.
- `.githooks/private-values` reads `.git/info/private-values`, the owner's untracked list, and
  blocks a staged line, file name or commit message (the new `commit-msg` hook) that holds one of its
  values, in any case. No list: it warns and lets the commit through, so a fresh clone still works.
  CI can't run it: the list lives only on the local machine.
- `.githooks/image-metadata` blocks a staged image whose bytes change when exiftool strips it (EXIF,
  GPS, XMP, comments; the colour profile stays). It reads the staged blob, not the working copy.
  CI runs it on every tracked image, since `--no-verify` skips the hook.
- `.githooks/test-hooks.sh` drives both hooks in a throwaway repo; a new `hooks` job in
  `secret-scan.yml` runs it. The full history passes the new rule.
- A `pre-merge-commit` hook runs the same checks, since a merge commit skips `pre-commit`.
- `/code-review` (default effort, all findings) found 11; 9 fixed, each with a test that fails on
  the old hooks: `++` lines skipped, `commit -v` diffs read as the message, untrimmed list values,
  relative and `${W}` paths, merges unchecked, exiftool errors reported as metadata, a `-name.png`
  read as an option, the JFIF message, a silent setup failure in the test. Not fixed: a staged
  rename rescans the whole file and binary files aren't scanned for values (a rename only finds
  what's already there; no binary docs here), and one `git diff` per file (the repo is small).

## 2026-11-22: step 2, threat model

- `docs/threat-model.md`, same shape as Telma's: assets, trust boundaries, legs per session,
  13 threats with the control, the leg it cuts and the proof, accepted risks, detection, out of scope.
- Proof is from the B1 to B9 injection cases and probes at Telma's tag `pre-split`; each row says
  when the model refused and the wall was proved by a probe only. B7 was never run.
- Checked against the fork's ruleset (API, read-only): `main` needs a PR with one approval and six
  CI checks; only the owner's user bypasses it. So the bot can't merge its own PR, and the threat
  model says so instead of "PR required".
- Found while writing: the test gate goes green if an email gets the bot to delete the tests that
  catch the bug (B1's obedient run did exactly that, before committing). Listed as an accepted risk;
  the owner's approval and the fork's CI are the wall.
- Branched off `main` while step 1 (PR #10) was open, then rebuilt as one commit on `main` after #10
  merged. A merge of `main` didn't work: `pre-merge-commit` diffs against the branch, so it flagged
  lines that came from `main` (`test-hooks.sh`, step 1's entry here) as new. Step 1's hooks need a
  follow-up for that and for the 3-character list value below.
- `/code-review` (default effort, all findings) found 7, all fixed: the skills repo's name and path
  are on the private-values list, so the doc says "the skills repo" (they're still in `vps/host.md`
  and older docs, where step 1's hook doesn't look at old lines); the "no session holds three legs"
  line now says the token is the only private data; npm's `ignore-scripts` is named and marked as
  VPS config not in this repo; the ruleset sentence names the owner's bypass; Telma moved inside the
  VPS box in the diagram; this plan's row had an extra cell.
- Not changed: review read `support-inbox`'s comment ("inside the sandbox the password is mounted at
  `/opt/secrets`") as a mail password in the sandbox. The pre-split probes found only the 1-hour
  token in the sandbox, and `bug-loop-pre.sh` runs `support-inbox` on the host, so the comment is
  stale. The script stays byte for byte the VPS copy; step 5's diff with the VPS can settle it.
- Step 1's private-values check, run by hand on this diff (its hook isn't on `main` yet), matched
  a common English word in the lens ("off the m…", as Telma's doc says it): a 3-character value on
  the local list is a substring of it. The lens now says "off the server". The same match blocks
  the brain's docs guideline phrase "the local m…", so the list or the hook's substring match needs
  a look in PR #10.

## 2026-11-22: step 1 follow-up, whole words

- Found in step 2: a 3-character list value matched inside a common English word, so the hook
  blocked ordinary prose, and a merge of `main` into a branch failed on lines `main` already had.
- `private-values` now matches a value as a whole word, any case (`grep -w`): "secret-repo" still
  catches "Secret-Repo" and "(secret-repo)", not "secret-repos". Two new tests. Cost: a value glued
  to letters, digits or `_` slips through.
- Merges still check the other branch's lines. Tried checking only lines new to both parents: git
  gives `pre-merge-commit` no `MERGE_HEAD`, and parsing `GIT_REFLOG_ACTION` is fragile. A value that
  arrives from `main` is already public, so the stop is worth it.
- With whole words, three list values are still on `main` in tracked files: the skills repo's name
  in two forms (`vps/`, the hardening plan, this devlog), and a 3-character one in the hardening
  devlog, this plan and this devlog. Older lines, so no hook sees them. The owner decides: drop
  them from the list, or reword those files.
- `/code-review` (default effort, all findings) found 11, some in #10's code. Fixed, each with a test:
  an external diff tool or textconv hid the staged lines (`--no-ext-diff --no-textconv`); glob
  characters in a file name widened the diff (`--literal-pathspecs`); `grep -w` missed a value that
  starts or ends with punctuation (`@corp` in `jr@corp`), so values are now regexes with a word
  boundary only on a word-character edge; `#` lines in a `--cleanup=verbatim` message weren't read;
  CI checked only the images at the tip, now every image blob in history (`image-metadata
  --history`, full fetch); `AGENTS.md` said CI checks the private values; a test ignored the exit code.
- Not fixed: merges keep re-checking the other branch (above; `--no-verify` there skips gitleaks too,
  but CI still runs it); SVG and PDF stay out of the image check (exiftool can't write SVG, and
  stripping a PDF only appends an update, so the check would block or pass every one of them); a
  file name with a newline is split in two (no such names here); this devlog says where the listed
  values sit on `main` without naming them, so the owner can act on it.
- The owner's call on the listed values already on `main`: reword them. Docs and comments now say
  "the upstream skills repo", "a checkout in `/opt`" and "demo-bug pack". Three deployed scripts
  now differ from these copies in a comment line (`vps/host.md` lists them).
- Left as they are: two code lines that name the skills checkout, its path in `skills-update.sh`
  and the guard's source label in `scan-diff.py`. Changing them means renaming the folder on the VPS
  and redeploying, the owner's call. The values also stay in this repo's public history.

## 2026-11-23: step 3, before/after table

- `docs/before-after.md`, same shape as Telma's page, from the bot's side: legs per session, private
  data, untrusted input, ways out, persistence, detection, what is still open. Rows from the brain's
  parked bot rows, checked against Telma's audit-before, audit-after and injection suite at
  `pre-split`.
- Overlaps with Telma's page are written here too, from the bot's side (the owner's rule, 2026-11-20):
  the split, the rotated GitHub token and mailbox password, keys host only, Discord the owner only,
  no root cron, the kill switch.
- Left out: the test gate (it ran before the split as well, so it has no before/after) and the chats
  with the owner (the bot didn't exist before).
- The mailbox row says only that the password was mounted in the sandbox before: the audit doesn't
  say the sandbox read the inbox itself.
- The skills repo is "the upstream skills repo", since its name is on the private-values list.
- `/code-review` (default effort, all findings) found 6, all fixed: the legs cells now name each
  leg (untrusted input was missing from both columns), and the "after" count of 2 points to the
  threat model, which counts it that way only if the 1-hour token doesn't count; "refused most" is
  now "refused every case", as the threat model says; the test-gate risk joins What is still open;
  a sentence re-wrapped; the skills pull is still a system cron job, now as `skills-sync`, not root.
- The owner, in the PR: "nothing worth stealing but its own token" plays down an hour of write
  access, harmless only because the fork is a demo. Reworded; the owner's fix is to revoke the token
  when each run ends (hardening plan).
- Audit after #14, #16, #18 and #19 landed on `main`: merged `main` in (no conflict). The page
  still said "1-hour token" and a daily memory diff. Now: the token is revoked when the run ends
  (a hook since #16, fixed for GitHub's longer tokens in #18, deployed), so the legs, GitHub, PR
  body and What is still open rows say that, and the open risk names the ping and the full hour
  if the revoke fails; the memory diff is hourly and silent when nothing changed (#14). The owner's
  fix above is done. The kill-switch row still matches the runbook.

## 2026-11-23: step 4, ADRs

- The owner picked all six candidates and added a seventh: the host scripts that run before the bug
  loop and PR triage and decide whether the agent wakes. Seven ADRs in `docs/adr/`, same shape as
  Telma's (Status, Context, Decision, Consequences), and a README that links Telma's ADRs 2 and 3
  for the split and one repo per agent.
- The owner also moved memory-diff to hourly (PR #14, hardening devlog). ADR 5 says hourly, so this
  branch was stacked on #14; #14 is merged and deployed, and the PR now targets `main`.
- ADR 7 says what the pre-run scripts check: that there is work (an email, an open PR). They don't
  read the email for injections; the sandbox's walls contain it.
- Dates from Telma's hardening devlog at `pre-split`: the App and the pre-run scripts are step 1
  (2026-11-18), squid step 3, skills and memory step 4 (2026-11-18), security patches 2026-11-19,
  demo bugs on `main` 2026-11-22.
- Left out of ADR 4: which Dependabot alerts are open. It would go stale.
- `/code-review` (default effort, all findings) found 10. Fixed 6: ADR 6 in the future tense (no bug
  is planted yet) and "the rest stay open" (eight is a minimum); ADR 3 says low-severity findings
  never block (`scan-diff.py`); ADR 5's undo is one restore command per post, and long diffs are
  cut; ADR 2's probe result points to the threat model, the CI tests to the squid config.
- Not changed: ADR 5 says hourly before the VPS does, but this branch merges after #14, which
  merges after the deploy. The postmortem link uses Telma's `main`, like the threat model.
  "Accepted" is the decision's status; the owner approves the doc in the PR.
- Found, for the owner: `bug-loop-pre.sh` claims the email and posts the ping before it mints the
  token, so a failed mint leaves an email claimed with no run. A code change on the VPS, not this
  step's.
- Audit after #14, #16, #18 and #19 landed on `main`: merged `main` in (one conflict, in this plan's
  table: row 4 from this branch, row 5 from `main`). ADR 1 and ADR 7 said the token "dies within
  the hour"; since #16 and #18 a hook revokes it when the run ends, and the pre-run scripts revoke
  it when the agent doesn't wake. Both ADRs now say so, and ADR 1's status gives the date. ADR 5
  already said hourly, now true on the VPS. The claim-before-mint note above still holds.

## 2026-11-23: the bot's live files (step 5)

- Copied from the VPS, read-only: `SOUL.md`, `config.yaml` and `shell-hooks-allowlist.json` from
  `~/.hermes/`; `publish-pr-review` and the two prompt files from `~/tools/`; the `bug-triage` and
  `pr-triage` skills from `/opt/dmoka-skills/skills/`, with the skills repo's MIT license.
- `config.yaml` is copied whole. It holds no channel IDs (they're in `.env`) and no personal data.
  Its backups on the VPS show each change: step 1b set the model, sandbox, mounts and toolsets
  (Hermes wrote its gateway defaults then too), step 3 the MCP server, then the proxy, the hook
  timeout, step 4 the skills folder and memory on, GitHub telemetry off, and the revoke hook.
- The hooks config is the `hooks:` block in `config.yaml`; no separate file.
- Cron prompts: only `bug-loop` and `pr-triage-morning` have one; the other three jobs run a script
  with no agent. The bug-loop prompt holds no inbox address any more (the host claims the email).
  The PR-triage prompt's tailnet host is `<tailnet-host>` here. Both prompts equal the copies in
  `~/tools/`, so those files are what this repo holds; `host.md` lists the jobs.
- `publish-pr-review` wasn't in the plan's list, but the PR-triage job runs it, so it's here too.
  It renders tours with the `pr-tour` skill, which isn't copied.
- `pr-triage` is copied whole, with its 1.6 MB vendored mermaid bundle and its third-party licenses
  (the owner's call).
- The skills repo's name was on the private-values list, but the repo is public and MIT-licensed,
  and `skills-update.sh` has had its path since the import. The owner took it off the list, and a
  short value that matched a comment and minified names in the skill.
- `SOUL.md` audited against the Hermes guide (in the brain inbox): it said "no memory between runs"
  (memory is on since step 4) and "nothing leaves without approval" (the bot opens PRs), and named
  the owner. Rewritten with the owner's approval: identity, how it works, never, how it talks. The
  work and safety rules stay in it: a Discord task gets no cron prompt, the fork's `AGENTS.md` is
  about tests only, and SOUL.md is the one rules file the sandbox can't write (`~/dev` is mounted
  read-write). Deployed at 11:56 with the owner's yes; the old file is backed up next to it and the
  checksum matches this copy.
- Every file in `vps/` checked against the VPS: all equal, apart from the differences `host.md`
  lists.
- `/code-review` (default effort, all findings) found 6. Fixed 2: the bundle's gitleaks allowlist
  names its constants instead of skipping the file, and the bundle's size. Found, for the owner, in
  the live files (a change there is a VPS change): `publish-pr-review` deletes yesterday's tour pages
  before rendering, so one failed render leaves the index linking pages that are gone; a tour with no
  PR number is written as `-pr-null.html`; its header points to `config-pack/config.excerpt.yaml`,
  which no repo has (the mounts are in `config.yaml`); and the bug-loop prompt says "never touch other
  folders in /workspace/dev" while every other path in it is `/home/ticket-bay-bot/dev`, the same
  folder mounted twice.


## 2026-11-23: the live files trimmed to what the owner wrote (step 5 follow-up)

- An audit of #22 to #26 found four kinds of file that aren't the owner's work. Removed, the owner's
  call:
  - `vps/skills/`: byte-identical to `dmoka/skills` at `1a6af1f`, stale by design (`skills-sync`
    moves the checkout forward), and incomplete (`publish-pr-review` renders with `pr-tour`, never
    copied). `host.md` now pins the commit and lists which skill each job uses.
  - `config.yaml`: 2,539 lines, about 2,100 of them Hermes's comments. Replaced by
    `config.overrides.yaml`: the settings that differ from Hermes's `cli-config.yaml.example`, plus
    three defaults pinned on purpose (memory on, per ADR 5; the launch folder kept out of the
    sandbox; `allow_all_users: false`). Every key checked equal to the live file. The rest of the
    `gateway:` block Hermes's installer wrote is defaults and stays out.
  - `shell-hooks-allowlist.json`: Hermes writes it with approval timestamps and script mtimes, so it
    changes on every redeploy. `host.md` says which hooks need an approval.
  - `docker.service` and `hermes-gateway.service`: generated and unchanged; the gateway's names the
    Node and npm versions, so it changes with every Hermes bump. `host.md` keeps what they do.
- The gitleaks allowlists for the old `config.yaml` and the mermaid bundle stay: CI scans the whole
  history, and both files are still in it.
- Next: a way to track what's deployed and check the VPS against this repo (a manifest and a
  drift check, run from the local machine). Its own plan.


## 2026-11-23: the demo-bug pack (step 6)

- Eight bugs, built on a scratch branch of the fork off `main` (`e9da215`), one commit each, then
  exported as stacked patches to `demo-bugs/`: group of ten, group of five, early-bird end, VAT on
  top, fee cap, code one use over, tier-table gap, tier price up. Of the plan's candidates, the
  refund window (`<` vs `<=`) and service-fee rounding were left out. The refund path has the most
  tests in the repo, and a one-cent rounding error makes a weak email.
- Dropped after a probe: the last seat refused (`n >= seatsAvailable`) broke 15 integration tests,
  and a 2% refund fee typed as 20% broke 20 unit tests. Loosening that much would make the plant
  PR the story.
- The rule the plants follow: drop a test or an assertion, compare fewer fields, filter the bug's
  case out of a generator, or move an input off the boundary; never expect the buggy value. Checked: the original `src/domain/` with every loosened test
  is green (unit 358, integration and HTTP 274), so the bot's fix needs no test edits.
- With all eight planted, CI passes apart from the mutation check: unit and property tests,
  typecheck, integration, HTTP and Playwright (6/6). The mutation check (the fork's
  `mutate-changed.mjs`, run on each plant against the one before) fails on seven of the eight. In
  01, 02, 06 and 08 a surviving mutant is the fix; in 03, 04 and 05 the survivors show the dropped
  tests. 07 passes: Stryker has no number-literal mutator. The owner merges those seven with the
  ruleset bypass.
- The pack lives here, not on the fork as the plan said: on the fork's `main` the bot's grep would
  find each patch next to its email. `plant.sh` opens the plant PR on the fork from a temporary
  worktree; `test-plant.sh` runs in CI (`plant-demo-bug`).
- `/code-review` (default effort, all findings) found 10, all fixed: `plant.sh` now cleans up
  after any failure, refuses a re-run once its branch is pushed, pins `--repo` to origin (the
  fork's clone also has an `upstream` remote), applies with `--3way` and takes a trailing slash.
  The HTTP generators filter out only the bug's case instead of capping tickets at 9 and prices at
  €70. The README describes how the plants actually loosen tests. Email 05 quotes invoice lines, so
  the seed's early-bird dates don't change its numbers. 06 is no longer suggested for merge: its
  plant deletes the race test on a code's last use, which the fix won't restore. Merge 04, 07, 08.
- Smoke test: `plant.sh` ran all eight in order against a local copy of the fork, with each
  plant merged before the next and `gh` stubbed. Every patch applied, and the result is identical
  to the tested stack. `--repo` resolves to `jrcopeti/ticket-bay` from the fork's SSH and HTTPS URLs.
- Next: after the merge, add `plant-demo-bug` to the ruleset's required checks, plant 01 to 08 in
  order, and send the emails, one at a time, with the owner's yes for each run.

## 2026-11-23: the eight bugs planted, the emails sent

- With the owner's yes, `plant.sh` planted 02 to 08 in order, each merged with the ruleset bypass
  once its checks showed only the mutation check failing (07 passed it) and its changed lines
  matched its patch: #19 to #25 on the fork. 01 was #18. The fork's `main` carries all eight, and
  no PR is open. #16, the bot's earlier fix for the group-of-ten bug, was closed first.
- The first loop stopped on #20 because it read the checks before all six had reported, and the
  restart tried 02 again; neither changed anything on the fork.
- The owner gave the support address and said to send them all: the eight emails went out in one
  go, 06 included, from the owner's Gmail connector. 01 and 02's fixes touch adjacent lines, so
  the bot's PRs for those two may conflict.
- Next: the bug loop's first run on them (09:00 tomorrow), then the owner merges three fixes
  (04, 07, 08) and leaves the rest open. Still to see there: the new bug-loop prompt.
