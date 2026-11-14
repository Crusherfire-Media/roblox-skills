---
name: roblox-testing
description: Jest Roblox specs for Luau game code and shared pesde packages, run in Studio through a connected Studio MCP and in CI through Open Cloud Luau Execution. Load it before planning or writing a spec, working test-first, adding a regression test for a bug fix, adding test coverage to existing systems, setting up Jest in a place or in CI, acting on a failing spec run in Studio or CI, or pruning a suite that has grown large.
---

# Roblox testing

Game code is tested with **specs**: Jest Roblox test modules that live in the place and run in
the edit DataModel of a Studio place, and in CI on a server through Open Cloud. Each test pins one
**behavior**, observed at a **seam**: a public interface where behavior is observed without
reaching inside. Every behavior is tested once, so the suite stays small enough to maintain. The
loop is red → green, one **vertical slice** at a time.

Jest Roblox is not JavaScript Jest (`.never` replaces `.not`, `jest.fn()` returns two values,
every global comes from `JestGlobals`, and more). Read
[references/jest-api.md](references/jest-api.md) before writing the first spec in a session.

## Layout

```
ServerScriptService
└─ Tests                 Studio-only: no LOAD_MODULE tag, no loader attributes
   ├─ Packages           Jest Roblox (Jest, JestGlobals, _Index)
   └─ Specs              jest.config, plus specs mirroring the Modules tree
      ├─ DataCatalogs
      │  └─ FoodCatalog.spec
      └─ Integration     specs that run several systems together, one per journey
         └─ CollectCookSell.spec
```

- If `Tests.Packages.Jest` or `Tests.Specs["jest.config"]` is missing, follow
  [references/setup.md](references/setup.md) before anything else.
- A spec for `Modules/<path>/<Name>` is the ModuleScript `Specs/<path>/<Name>.spec`. A spec that
  runs several systems together is `Specs/Integration/<Journey>.spec`.
- Nothing under `Modules` ever requires anything under `Tests`.
- In a Rojo repo (a `default.project.json` at its root), specs are files: read
  [references/rojo-mode.md](references/rojo-mode.md) before writing or running one. It replaces
  the `PackageLink` rule for pesde packages, and moves the whole-suite run to CI.
- A shared package's own behavior is specced in its package repo, outside every package folder.
  Read [references/package-repo.md](references/package-repo.md) before writing or running a spec
  there. It replaces this layout.

## Behaviors and seams

You can't test everything. Testing effort goes to the behaviors a player, the economy, or another
system depends on: the critical paths and the complex logic, not every function or edge case.

A behavior is a rule you can state as a sentence a player or caller would recognize: "a purchase
the player can't afford changes nothing", "a golden pickup credits its base ingredient". A
function is not a behavior. Name tests after behaviors.

Seams in this architecture, from widest to narrowest:

- **Journey**: several systems working together through their mediators, such as collect, cook,
  then sell. An integration spec runs the real SystemPackages and mediators involved.
- **System**: a SystemPackage's public API, meaning its services' methods and the classes it
  exposes to other systems (`.new` and methods). Most behaviors are tested here. A class used only
  inside its system is an internal, covered through the service that owns it.
- **Rule module**: a pure module whose job is a calculation (pricing, odds, capacity) with more
  input combinations than the system's API reaches cheaply.
- **Catalog**: invariants a catalog documents that a data edit can break, such as unique names,
  references that resolve, or prices above zero.

**One behavior, one test.** Test each behavior once, at the seam that owns it: a rule within one
system at that system's API, a rule that crosses a mediator in a journey spec, and a rule module's
combinations in that module's table. Before writing a case, search the specs for its rule: a rule
another test already pins has its owner.

- **A wider seam runs one case.** A system, journey, or UI spec that reaches a rule another seam
  owns runs one case of it, to show it applies the rule or that a mediator hands off. A helper
  behind a system method is covered through the method. A component built on a provider (an input
  stack, a modal group) leaves the provider's rules to the provider's spec.
- **A mirror gets one parity test.** A client or UI module that mirrors a server rule gets one
  test that runs the rule's cases through both and collects every case where they disagree.
- **One row per distinct case.** Variations of one rule form one `it.each` table, holding each
  side of each boundary and each kind of input the rule treats differently. Rows on one case are
  one row: points on one straight line or formula (keep the ends and each clamp); enum values,
  tiers, rarities, or levels the rule treats alike; the middle steps of a ladder (a list of
  values indexed by level). A table over 8 rows names the case each row stands for in step 1's
  list.
- **Bad input once per remote handler.** When a handler's guard is a single call to a validator
  library (such as the `t` package's `t.number` or `t.integerPositive`), one bad-input row per
  handler shows the guard is there; the kinds of bad input the validator rejects are that
  library's tests. A guard the code writes itself (its own NaN or range check) gets a row per
  branch. A guard every method shares, such as an unloaded profile, is one test that collects
  the methods that fail to refuse.
- **One test per catalog rule.** A rule every catalog entry or map part must satisfy is one test
  that collects the offenders (see Writing a spec). Tuning numbers in an expectation come from
  the module that owns them, or the rule is tested with a fixture catalog.

**Fake only the boundary.** The boundary is what the game doesn't own or can't run in edit mode:
packaged systems (anything with a `PackageLink` ancestor), remotes, Player instances, engine
services that reach saved data, purchases, the network, or the live session (`DataStoreService`,
`MarketplaceService`, `MessagingService`, `Players`), time, and randomness. A module-local
`Random.new()` cannot be faked: test odds through the rule that maps a roll to an outcome, or
propose a seam, never by sampling many rolls. Every other game module runs for real, including the
other systems a SystemPackage reaches. Feed fakes through the same registration and injection APIs
a setup would call. `jest.mock` a module only when it sits on the boundary or cannot load in edit
mode. Prefer a shared fake that implements the module's whole public API with its real semantics,
kept beside the specs, so a refactor that switches which member the code calls still passes.
Assert on what the fake holds afterward (profile data, bag contents), not on how it was called. A
call is the thing to assert only when the behavior promises it, such as a remote fired to a client
or a notification shown.

Leave these to playtests and to the user's eyes:

- Presentation: layout, animation, springs, colors, sounds, and text sizing, also when it lives
  in a pure module: cutscene and transition timelines, tables of flashes and shakes, sound cues,
  sizes and positions measured across devices, transparency, and whether text fits. UI specs
  cover what a view shows for given data and the view state the server doesn't compute. UI Labs
  stories cover the rest.
- Setups that only mount or connect things, with no rule of their own.
- Replication, DataStores, physics, and anything else that needs a running game.

## The loop

1. **Agree the behaviors.** Before writing any spec, list the behaviors you intend to test, each
   with the one seam it is tested at, each table's rows, and the number of tests the work adds,
   and confirm the list with the user. No spec is written for an unconfirmed behavior. For a bug
   fix, the behavior is the correct one the bug breaks, at the public call that shows it.
2. **Red.** Write one spec for one behavior. Run it alone, filtered to that spec (see Running
   specs). It must fail on its assertion, for the reason you expect. A spec that failed to load
   is not red: it never ran, so fix the load error first.
3. **Green.** Write only enough code to pass that spec, and run it again until it passes. Follow
   the `luau-style-guide` and `game-architecture` skills for the code.
4. **Next slice.** Repeat from step 2 with the next behavior. Each spec is a tracer bullet that
   responds to what the last cycle taught you, never a batch written up front.
5. **Finish.** Sweep the specs of every module you touched, not only the spec files you edited:
   each test pins a behavior no other test pins and passes the refactor test (see Anti-patterns).
   Rewrite or delete any test that fails either check, and delete tests of behavior the change
   removed. Scaffolding tests of internals, written only to learn the code, are throwaway rather
   than specs: delete them here. Run the affected specs (see Running specs): every test passes
   except the red bug specs, which you list by full test name in your report. Analyze every
   module and spec you changed (`luau-lsp analyze`, or the Studio MCP's script analysis).

Refactoring is not part of the loop; it belongs to review, with the suite as its safety net. A
refactor adds no tests: code it moves or extracts stays covered by the behavior tests that already
reach it. When a refactor that keeps behavior turns a test red, the test is at fault: rewrite it
through the seam or delete it, rather than updating its expectations to follow the new internals.

When the code already exists, as when adding coverage to existing systems, follow
[references/existing-code.md](references/existing-code.md) for steps 1 to 4. To prune a suite
that has grown large, follow [references/pruning.md](references/pruning.md).

## Running specs

**In Studio**, through whatever Studio MCP is connected: run Luau in the place's edit session
that calls Jest's `runCLI` with a path or name filter and returns a short summary. The script, the
filters, and how to read its result are in
[references/running-in-studio.md](references/running-in-studio.md); read it before the first run
in a session. When the MCP offers its own run-the-specs action, it does the same job.

- **The spec in progress** runs alone (steps 2 and 3).
- **The affected specs** close a slice, in one run whose path filter selects the spec of each
  module you changed, every spec that requires one of those modules (search `Specs` for the
  module's name), and the Integration spec of each journey the change touches: usually 1 to 10
  spec files. A refactor of one system and a performance safety net run the same set.
- **The whole suite** runs once per feature, after its last slice. In a repo with CI, CI runs it on
  every pull request, and that is the whole-suite run: open the pull request, read CI's result,
  and rerun a spec file CI reports failing in Studio by its path. Without CI, run it in Studio with
  no filters, in batches by folder when one run takes too long.

**In CI**, the workflow uploads a build to a CI place and runs the whole suite there in one Open
Cloud Luau Execution task. Before setting up, changing, or debugging that job, or when a spec
passes in Studio and fails in CI, read [references/ci.md](references/ci.md).

## Anti-patterns

- **Implementation-coupled**: reads `_` private members, mocks the module's own internals,
  asserts on its internal calls (counts or order), or checks a side channel instead of the
  interface. It breaks on refactors that keep behavior. The **refactor test** finds it: picture the
  module's internals rewritten with the same behavior (helpers inlined or split, collaborators
  called in another order or through another member). A test that would go red is coupled, and
  mocks with call expectations are the usual cause. A seam added for testing is a public method a
  real caller could use, proposed to the user before it is added, never a private helper made
  reachable; for the shape of a better interface, consult the `mattpocock-skills:codebase-design`
  skill when it is installed.
- **Tautological**: the expected value is computed the way the code computes it, so the spec
  can never disagree. A table that restates a catalog or template field by field is one too.
  Expected values come from an independent source: a literal worked out by hand, a documented
  rule, a known-good example.
- **Redundant**: one behavior tested at two seams, once per function along one call path, or
  twice in one table (two rows from the same case). Keep the test at the seam that owns it, one
  row per case, and delete the rest.
- **Over-specified**: pins what the behavior doesn't promise, such as message wording, tuning
  values no documented rule states, or call counts. `toEqual` on a whole view or state table
  pins every field; assert the fields the behavior is about. A refusal test asserts the refusal
  and that nothing changed. A rule whose inputs are tuning data is tested with a fixture catalog.
- **Horizontal slicing**: all specs first, then all code. The specs end up testing imagined
  behavior.

## Writing a spec

Specs follow the `luau-style-guide` skill like any other script:

```lua
--!strict
const JestGlobals = require("@game/ServerScriptService/Tests/Packages/JestGlobals")
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const FoodCatalog = require("@game/ServerScriptService/Modules/DataCatalogs/FoodCatalog")
const IngredientCatalog = require("@game/ServerScriptService/Modules/DataCatalogs/IngredientCatalog")

describe("FoodCatalog", function()
	it("builds every recipe from ingredients that exist", function()
		local missing = {}
		for enumName, food in FoodCatalog:GetEntries() do
			for _, ingredient in food.Ingredients do
				if not IngredientCatalog:GetEntryByEnumName(ingredient) then
					table.insert(missing, enumName .. " needs " .. ingredient)
				end
			end
		end

		expect(missing).toEqual({})
	end)
end)
```

- Require every Jest global you use from `JestGlobals`, and the code under test by its absolute
  `@game/...` path.
- When a rule must hold for many entries (every catalog entry, every map part), write one test
  that loops over them, collects the offenders into a table, and asserts it equals `{}`: the
  failure then lists every offender instead of stopping at the first. An `it.each` fed by rows
  built from the catalog turns that one rule into a test per entry; loop inside one `it` instead.
- Name a spec's `describe` after the module (or the journey, for an integration spec) and each
  `it` after the behavior it checks.
- Each test reads given, when, then: set up the state, perform one action through the seam, and
  assert the outcome, with a blank line between the three.

## Edit-mode rules

Specs run in the real edit DataModel of the open place, not a copy.

- Anything a spec creates, it destroys. Build instances unparented, or under a folder the spec
  removes in `afterEach`. Never change or delete existing content of the place.
- Jest loads the spec and every module it requires fresh through `loadstring`, so edits show up
  on the next run and module state never leaks between spec files. Inside one spec file,
  modules stay loaded across tests.
- The unit of isolation is the test, not the module: no test depends on another test's leftovers.
  Share fixtures (fixture catalogs, installed fakes, the module under test) across a file's tests,
  and give each test fresh state, such as a new fake player or a new profile, so specs run
  quickly. Call `jest.resetModules()` in `beforeEach` only when the module's own state must start
  fresh, because every reset reloads the whole require graph. Install mocks before the first
  require of the code under test.
- `RunService:IsRunning()` is false, so require-time setup gated behind it is skipped. The loader
  never runs either: no `Init` or `Start` has been called. Call what the behavior under test
  needs yourself, or test functions that need no lifecycle.
- `RunService:IsServer()` is false and `IsClient()` is true, so code that branches on realm takes
  its client path. A remote factory that creates remotes on the server waits for them here
  instead: fake it. CI runs specs on a server, where `IsServer()` is true and `IsClient()` is
  false, so a spec that depends on edit mode passes in Studio and fails in CI.
- Player instances cannot be created: fake players with a table, backed by an unparented Instance
  when the code uses attributes or children. In a Team Create session `Players` holds the real
  collaborators and `Players.LocalPlayer` is the real Studio user, so leave any `Init` or `Start`
  that observes players, tags, the map, or `RunService` uncalled, and test the per-player method
  it calls instead.
- A module that requires a runtime-relocated path (a legacy `ReplicatedStorage` require of code
  that lives in `ServerScriptService` in edit mode) cannot load in a spec.
- Use fake timers instead of real waits (`jest.useFakeTimers()`; advance in milliseconds).
