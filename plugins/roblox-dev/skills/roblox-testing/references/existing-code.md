# Adding specs to existing code

The code already runs, so the loop starts from what it does instead of from a failing test. A map
of behaviors replaces the test-first list, and each test proves it can fail by seeing its input
pushed across the rule once.
Everything in the main skill still applies: behaviors, seams, one behavior per test, and fakes only
at the boundary.

1. **Map the behaviors.** For the systems in scope, read the doc comments, catalog comments, and
   what players see, and write each rule as a behavior sentence with its one seam. A rule that
   crosses a mediator maps to one integration spec, not to both systems. Search the existing specs
   for each rule before mapping it: a rule a test already pins stays off the map. Done when the map
   lists, once each, the behaviors a player, the economy, or another system depends on, and no two
   entries describe the same rule; a map organized by function or by module has not reached this
   bar yet.
2. **Confirm the map** with the user, as in the main loop's step 1.
3. **One slice at a time.** Write the test for one mapped behavior and run it: on working code it
   passes. Then change its given across the rule's boundary (or add a bad entry to the catalog the
   test loaded), leave the expectation alone, watch it fail on the assertion, and restore it.
   Breaking only the expected value proves the assertion runs, not that the test reaches the rule.
   Put it through the refactor test (see the main skill's Anti-patterns) before the next slice.
4. **Bugs.** When the code contradicts its own doc comment or a rule a comment states, or produces
   a result no reading could intend (a negative balance, a duplicated item), write the test for the
   correct behavior and leave it red; report the bug instead of changing the code. When no intent
   is documented, the behavior is a question for the user rather than a red test.
5. **Unreachable behavior.** When a behavior is reachable only through private code, or through an
   `Init` that would touch the running game (players, tags, the map, `RunService`), propose the
   smallest public seam on the system to the user before changing game code. A good seam is the
   method an `Init` callback already does the work of, made public. Keep the change
   behavior-identical, existing bugs included.
6. **Finish** with the main loop's step 5, the redundancy sweep included.

## Several agents

When the work is split across agents, one owner (the orchestrator or a single planner) builds and
dedupes the behavior map across every system first. Each writer then gets whole spec files and
the exact behaviors to cover in them, so no behavior is written twice and no spec file has two
editors.
