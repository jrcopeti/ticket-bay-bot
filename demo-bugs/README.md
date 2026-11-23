# Demo-bug pack

Eight small bugs to plant on the ticket-bay fork's `main`, each with the customer email that
reports it. The bot reads the email, finds the bug, and opens a PR that fixes it with a regression
test. Three of those PRs get merged; five stay open as evidence, so their bugs stay planted.

Each bug follows the same recipe: one small mistake in `src/domain/` (one number or one operator),
the tests that would catch it removed or loosened, and an email that describes what the customer
saw, with numbers, never the cause.

## The bugs

| # | Bug | The mistake | What the customer sees |
|---|---|---|---|
| 01 | `group-of-ten` | `n >= 10` became `n > 10` in `groupDiscount` | 10 tickets get 5% off, not 10% |
| 02 | `group-of-five` | `n >= 5` became `n > 5` in `groupDiscount` | 5 tickets get no group discount |
| 03 | `early-bird-end` | `EARLY_BIRD_DAYS` became `EARLY_BIRD_DAYS - 1` in `earlyBirdEndsMs` | the event page promises the early-bird a day longer than checkout gives it |
| 04 | `vat-on-top` | `/ (100 + rate)` became `/ 100` in `vatPortion` | the invoice shows 27% of the total as VAT, not the 27% included in it |
| 05 | `fee-cap` | `2001` became `20001` in `serviceFee` | fees above the €20 cap |
| 06 | `code-one-use-over` | `uses >= maxUses` became `uses > maxUses` in `codeStatus` | a code limited to 40 uses works 41 times |
| 07 | `tier-table-gap` | `[5, 9]` became `[5, 8]` in `priceTiers` | the price table has no row for 9 tickets |
| 08 | `tier-price-up` | `100 - percent` became `100 + percent` in `priceTiers` | the table's group prices are above the single price |

Each folder holds `plant.patch` and `email.md`. The emails quote the numbers a customer sees with
all eight planted. Once a fix is merged, another bug's numbers can shift. For example, 08's 10+ row
changes when 01 is fixed. The symptom stays the same.

## Why the pack lives here and not on the fork

The bot works in a checkout of the fork's `main`. If the patches were in that checkout, its first
grep for "group discount" would find the answer next to the question. This repo is out of its
working tree, and the bot never writes here.

## Planting

```sh
demo-bugs/plant.sh ~/code/ticket-bay 01-group-of-ten
```

`plant.sh` opens a PR on the fork from a temporary worktree off `origin/main`, so the local
checkout is left alone. The patches stack: plant them in order, each after the one before it is
merged. The plants loosen tests by dropping a test or an assertion, comparing fewer fields, filtering
the bug's case out of a generator, or moving an input off the boundary (6 tickets instead of 5).
None of them expects the buggy value, so the bot's fix needs no test edits to go green.

Seven of the eight plant PRs fail the fork's required `mutation (changed domain lines)` check, and
the owner merges them with the ruleset bypass. That's the gate working: in 01, 02, 06 and 08 a
surviving mutant is the fix itself, and in 03, 04 and 05 the survivors show the tests the plant
dropped. 07 passes, because Stryker has no mutator for number literals. The rest of CI passes with
all eight planted: unit and property tests, typecheck, integration, the HTTP API and Playwright.

## Sending the emails

The owner sends each `email.md` to the support inbox, one at a time. Each one starts a bug-loop
run, so an agent asks before sending.

Merge 04, 07 and 08: their fixes touch lines far apart from each other and from the rest. Don't
merge both 01 and 02, whose fixes touch adjacent lines. Leave 06 open: its plant deletes the
integration test for two checkouts racing for a code's last use, which a fix to `codeStatus`
won't bring back.

`test-plant.sh` tests `plant.sh` against a throwaway fork.
