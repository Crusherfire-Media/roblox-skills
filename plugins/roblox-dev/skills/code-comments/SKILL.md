---
name: code-comments
description: Code comments - the rules for each comment you write, keep, or review, and a cleanup pass that prunes existing ones. Load before writing or reviewing comments in Luau or Roblox code. Also load when the user asks to clean up, prune, or audit the comments in a file, diff, or PR in any language, says code has too many or too verbose comments, or asks to tidy comments before committing.
---

# Code comments

Default to no comment. Code already shows *how*; a comment earns its line only by carrying a *why* the code cannot show. Two branches use these rules:

- **Writing or reviewing code**: apply the writing rules below to each comment you add, touch, or review.
- **Cleanup pass** (on request: clean up, prune, or audit the comments in a file, diff, or PR): read [references/cleanup-pass.md](references/cleanup-pass.md) and run it.

## Writing rules

1. **Write a comment only for a *why*.** A why is a non-obvious constraint or invariant, a deliberate deviation, a gotcha, a workaround, or the reason a tempting simpler version breaks. Names, types, and the code itself carry the steps.
2. **Write for a reader who opens the file fresh.** Describe the code as it stands. What changed, and why it changed, goes in the commit message; that includes changelog lines in a file header.
3. **Apply Occam's razor to every comment you keep.** Keep the one non-obvious fact a reader needs at that line, placed next to the line it governs. Cut the mechanism the code shows, where a value is used downstream, the consequence of the consequence, and the justification of the justification. Carrying a real why and being worded minimally are separate tests, and a comment must pass both. A five-line block almost never survives intact, and the razor's answer is sometimes zero.
4. **Make each comment stand on its own with any link removed.** State the substance itself. A durable address may trail it as a breadcrumb: a ticket ID, an RFC, a permalink, a wiki page, or a maintained doc at a stable path. Specs, design docs, and section numbers ("spec §7") get superseded, so write the requirement they hold.
5. **Move system-level narrative to a maintained doc.** "Why it's built this way" belongs in a README or doc, extracted whole. Inline keeps only the local detail a reader needs at that line. A comment whose whole content is a pointer to the doc gets deleted.
6. **Delete dead code.** Version control keeps the history.
7. **Document functions by their contract.** A one-line summary on a public function or endpoint is welcome. A doc comment earns more lines only for what the signature can't show: units, valid ranges, side effects, failure behavior, preconditions. A single clear line inside a body stays uncommented.
8. **TODOs need no issue ID.** A TODO marks work beyond the current task; finish the work that is in scope.
9. **Write comment text as plain American prose.** Punctuate with commas, colons, parentheses, or a new sentence, and keep em dashes and a bare `--` used as a dash out of the text. Use American spelling (color, center, behavior, canceled, license, initialize), in comments and in the names you write.
10. **In Luau, put `--[[` and `]]` each on its own line**, with the text on the lines between.

A file's existing section banners and file header are the user's convention: keep them through normal edits, and in a cleanup pass keep a set the file uses consistently as structure and delete stray or nested ones.

### Comments worth their line

These carry a why that is easy to mistake for noise:

- **A constraint the code can't show:** `-- Must stay below the autosave interval, or saves overlap`
- **A cross-file sync obligation:** `-- Keep in sync with BLOCK_COSTS in ShopServer`. The link is the why: it stops two copies drifting apart.
- **The meaning of a literal:** units, order, or encoding, such as `local RESPAWN_DELAYS = { 3, 5, 8 } -- seconds, by death count`.
- **A format contract:** output pinned to an external expectation, such as a leaderboard that shows whole numbers with thousands separators.
- **A surprising but essential line:**

  ```lua
  -- amount ~= amount catches NaN, which passes every range check
  if typeof(amount) ~= "number" or amount ~= amount then
  	return
  end
  ```

- **The source of a copied algorithm**, with its license when it has one.

### Directives are code

Comments that steer a tool stay exactly as they are: Luau's `--!strict` and `--!native`, `-- selene: allow(lint_name)`, `-- stylua: ignore`, and their kin in other languages (`# type: ignore`, `# noqa`, `// eslint-disable-next-line`, shebang lines). A lint suppression may carry a short why when the reason isn't obvious.
