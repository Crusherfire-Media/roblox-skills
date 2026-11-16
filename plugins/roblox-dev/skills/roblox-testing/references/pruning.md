# Pruning a suite

A suite grows past its behaviors one reasonable-looking row at a time. Pruning finds every test
that guards a rule another test already guards, or no rule at all, and removes it without leaving
any rule untested. Everything in the main skill applies; this page is the order to work in.

1. **Count.** Get the test count per spec file: CI's summary (in a repo with CI) or one Studio
   run per folder for the totals, then each file's `it` calls plus its `it.each` rows. Note the
   tables built at runtime (`it.each(rows)` over a variable), since their rows don't show in the
   source. Done when every spec file has a count and the largest files are known.
2. **Split by domain, not by folder.** Group the spec files so each group holds a feature's
   system specs, rule modules, UI specs, and journey specs together, so one reader sees every seam
   a rule reaches. Spec files that test a shared package's module form their own group, compared
   against the package's specs in its package repo. Several agents can each read one group,
   read-only.
3. **Name each rule's owner.** For every rule a group tests, pick the one seam that owns it (the
   main skill's One behavior, one test) and mark every other test of it: a wider seam keeps one
   case, a mirror keeps one parity test, and a table keeps one row per distinct case. Mark
   presentation, catalog restatements, and tuning pins as well. Done when each marked test names
   the test that keeps its rule, or the reason no test should.
4. **Report and confirm.** Per file: tests now, the verdict (delete, trim, merge, move, rewrite),
   the tests removed, and why. Mark judgment calls. Confirm the plan with the user before changing
   a spec.
5. **Cut in slices**, by domain or by kind of cut: in a Rojo repo one pull request or commit per
   slice, so CI checks each; in a Studio-only place one slice at a time, run before the next. A
   table merged into one offender-collecting test proves it can fail: push one entry or fixture
   across the rule, see it fail, restore it. Package tests move to the package repo and land
   there before the game's copies are deleted.
6. **Verify.** Run the specs each slice changed (the main skill's Running specs), then the whole
   suite as Running specs says (CI's pull request run in a repo with CI). Done when every slice
   passes and the count per domain matches the plan.

Coverage gaps found along the way (a journey no spec reaches, a rule only reached through a wider
seam) go in the report as additions, written by [existing-code.md](existing-code.md).
