# Comment cleanup pass

A comment-only editing pass over a target the user names: a file, a folder, a diff, or a PR. Walk every comment in it, keep the few that carry a *why*, and delete or trim the rest. The writing rules in `SKILL.md` are the standard every comment is measured against. For a diff or PR, the pass covers the comments the change adds or edits.

Before the first pass in a session, read [worked-examples.md](worked-examples.md): one delete, one rewrite, one razor trim, and one keep.

## Scope

Edit comments only; the code stays byte-identical. That holds even when a comment exists because the code is unclear: such a comment may survive (it does real work, badly), and the code goes in the report as a candidate refactor. Refactors are a separate task the user can ask for. Commented-out code counts as a comment, so the pass deletes it. Tidy the blank lines a deleted comment leaves behind.

## Delete by default

A comment survives only by carrying a why a reader needs at that line, and every survivor is trimmed to the fewest words. When a comment seems to guard a constraint you can't verify, keep a trimmed version and flag it in the report.

## The pass

Apply these steps to every comment, in order. The first step that matches decides the outcome.

1. **Narration: delete.** It restates the code, describes the steps ("loop over the players", "parse the request body"), restates names, types, or signatures, or marks a block end (`end -- if`). This is the bulk of agent-written noise. The code under it was fine all along; leave it as it is.
2. **Change narration: delete.** It speaks to the reviewer of a diff: "updated to use the v2 client", "removed the old fallback", "added per feedback", "fixed the off-by-one", or a changelog line in a file header. Test: would it make sense to someone reading the file a year from now who never saw the PR? Change history belongs in the commit message.
3. **A moving target: rewrite or delete.** "See spec section 3", "per the requirements doc", "see the design doc". Delete it when the annotated line needed no comment at all (meeting a spec never does). Otherwise rewrite it to state the requirement itself. The address it cites decides what may stay as a breadcrumb:
   - **Durable** (may trail a comment): ticket and issue IDs (`GAME-1234`), wiki pages, RFCs and standards, permalinked sources, and a maintained doc or README at a stable path, which updates alongside the code.
   - **Ephemeral** (rewrite): "the spec", "the requirements", a design doc (a point-in-time artifact that gets superseded), and any section number of any document ("spec §7", "section 4.2"). A section number is ephemeral whatever document it indexes into.

   Even a durable address is only a breadcrumb: the comment must read correctly with it removed. This step applies inside doc comments and docstrings exactly as in line comments.
4. **A why that is bloated or misplaced: trim, split, or extract.** Work through these in order:
   - *Does it belong in a doc?* System-level narrative (an architecture decision, a benchmark result, a lifecycle overview) reads better in a maintained doc. If a durable doc already carries it, delete the inline copy and leave no signpost. A comment that only restates a decision the code already reflects ("1 vCPU is deliberate", "right-sized from prod") is dead weight even when it points at the doc, because the doc is where anyone questioning the value looks first. If no such doc exists yet, keep the comment and flag it as worth extracting; writing the doc is outside this pass. After extraction, inline keeps only a local fact a reader needs at that line: a non-obvious constraint ("timeout must stay below the interval") or a sync obligation ("keep in sync with X").
   - *Apply the razor.* Keep the single non-obvious fact a reader needs at that line, in the fewest words. Cut the mechanism the code shows, where a value is used downstream, the consequence of the consequence, restated names and types, and the justification of the justification. A real why still fails this test when it runs three times longer than it needs to. Some rationale has several genuine parts (a workaround, the bug it works around, and when to remove it); keep each part a maintainer needs to avoid breaking or "simplifying" the code, and cut the rest.
   - *Split a header block.* A block covering several points serves better as short comments, each next to the line it governs. Proximity keeps comments true: a comment beside its line gets updated when the line changes, and a block three screens up drifts.
5. **Stale: delete or correct.** It describes code that no longer exists or behavior that has changed. Correct it when the point still holds and earns its line; otherwise delete it. A wrong comment misleads more than a missing one.
6. **A tight why: keep it unchanged.** Rewording a comment that is already minimal adds noise to the diff. "Already tight" means correct *and* minimal; a correct but long comment goes back to step 4.

The kinds of why listed under "Comments worth their line" in `SKILL.md` are the ones most often deleted by mistake. Cross-file sync pointers, literal semantics, and format contracts survive this pass.

## Section banners

- **Luau:** apply the banner rule in `SKILL.md`. Keep the seven top-level banners, correct a banner's format when it drifts (dash length, capitals, the blank line under the function banners), and delete banners below the top level or beyond the seven. Flag a file that seems to want deeper sections as a candidate to split.
- **Other languages:** keep top-level banners that follow the file's house style, and delete banners inside functions, classes, and other nested scopes.

Text in a banner beyond its label is protected like any other why.

## Directives

Tool directives (`--!strict`, `-- selene: allow(...)`, `-- stylua: ignore`, `# type: ignore`, `// eslint-disable-next-line`, shebang lines) are code. They stay byte-identical.

## TODOs

Keep TODO and FIXME comments; they need no issue ID. Two exceptions:

- A TODO describing work that has visibly been done is stale: delete it (step 5).
- A TODO that hides unfinished work, such as `-- TODO: handle errors` on a path that plausibly should already handle them: keep it and flag it, since deleting it would hide real incompleteness.

## Doc comments and docstrings

Every step applies inside doc comments, including step 3's rules on references. A doc comment that only repeats the function name and parameter types is narration: delete or reduce it. One that documents what the signature can't show (units, valid ranges, side effects, failure behavior, invariants, what has already been done to the inputs) is a contract: keep it. Condense a doc comment to one line only when everything cut was signature restatement; preconditions, boundary ownership, and cross-module behavior are contract. A one-line summary on a public function, endpoint, or API surface stays, since other teams read those without reading the body.

## Report

After editing, report briefly:

1. **Counts:** comments deleted, rewritten, and kept, per file.
2. **Flags:** what the pass could not fix within its scope:
   - comments compensating for unclear code (candidate refactors)
   - TODOs that hide unfinished work
   - comments kept because their correctness couldn't be verified
   - narrative worth extracting into a doc
3. **Judgment calls:** each borderline keep or delete, one line each, so the user can overrule it.

Leave the deleted narration out of the report; removing it is the point of the pass.
