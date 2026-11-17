---
name: html-kit
description: Write HTML pages (plans, reports, design notes, system diagrams, triage boards) with the html-kit, themed components instead of hand-written CSS and SVG. Load it before writing any HTML page or document the user will open in a browser, such as a plan for a Roblox system, and before editing a page that loads kit/kit.js.
---

# html-kit

`kit/kit.js` in this skill's folder holds the whole design: the dark plan-page theme (Bricolage
Grotesque headings, IBM Plex text, flat cards, mono labels), charts, diagrams, and boards. A page
carries only content, so it costs about as many tokens as markdown and every page looks the same.

## 1. Put the kit beside the pages

Pages go where the project keeps them (its CLAUDE.md says where). That folder's root holds one
`kit/` copy: `kit.js`, `md2html.cjs`, and `LICENSE`.

- No `kit/` there yet: copy this skill's `kit/` folder in.
- A `kit/` already there: compare the version on the first line of its `kit.js`
  (`/* html-kit X.Y.Z`) with this skill's copy, and replace the folder when the skill's is newer.

Done when the folder's `kit/kit.js` matches this skill's version.

## 2. Write the page

The first line, with the page's own title and the relative path to the kit (`../kit/kit.js` from a
subfolder):

```html
<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Daily Rewards Plan</title><script src="kit/kit.js" defer></script>
```

Then content only: components and plain `<h2> <h3> <p> <ul> <ol> <li> <b> <code> <a> <pre>
<footer>`. In any text, `**bold**`, `` `code` ``, status pills `[done] [progress] [blocked] [todo]
[warn]`, and IDs like `DR-12` are formatted. Luau in `<pre><code>` is colored; mark a block in
another language `<code class="language-sh">`. Pages are dark; add `data-theme="light"` to `<html>`
only when the user asks for light.

Pick the component by the question it answers: approaches to choose between are `rk-options`;
where instances live is `rk-tree`; who calls whom, in what order and on which side of the network is
`rk-sequence`; how systems connect is `rk-diagram`; what the reader must decide is `rk-decisions`.

```
<rk-header tag="Plan · Game · System" title="..." sub="one-sentence summary"></rk-header>
<rk-stats>                                   one stat per line: value | label | note
7 | days in one streak cycle | +up from 0    (a note starting + is green, ! is red)
</rk-stats>
<rk-table>                                   first line is the header, cells split by |
ID | Item | Status
DR-1 | Streak math | [done]
</rk-table>
<rk-callout kind="risk|warn|note|ok|lesson" title="Short title.">text</rk-callout>
<rk-diagram title="...">                         one edge per line: A -> B: label (labels of 1-4 words)
Player [user] -> ShopPanel: opens                 kinds: [user] [svc] [db] [queue] [cache] [ext]
</rk-diagram>                                     (the kit picks the layout that fits the column)
<rk-steps>                                   numbered steps, one per line: Title | detail
Write the spec first | day boundaries and the grace window
</rk-steps>
<rk-decisions>                               the reader's decisions, shown D1, D2...: Question | options
Grace window | 20 hours (recommended) or none
</rk-decisions>
<rk-options>                                 a card per option: Name [recommended] | summary
Server-owned streak [recommended] | the server grants rewards
+ a player can't grant themselves a reward  (+ pro, - con, ~ note; each under its card)
- needs a remote and a rate limit
Client-side streak | the client tracks the streak
</rk-options>
<rk-tree title="...">                         one instance per line, indented under its parent
ReplicatedStorage [Folder]                    Name [ClassName] | note
  + ShopService [ModuleScript] | new          (+ added, ~ changed, - removed by the plan)
</rk-tree>
<rk-sequence title="...">                     calls in order: A -> B: label; replies: B --> A: label
ShopPanel [client] -> BuyItem [remote]: FireServer(id)   lanes in first-use order; tag [user] [client]
BuyItem -> ShopService [server]: OnServerEvent           [remote] [server] [db] to draw the client|server line
note ShopService: checks the price on the server
</rk-sequence>
<rk-chart type="bar|line|hbar" title="..." unit="ms">   one point per line: Label: number (0 or more)
Day 1: 1000
</rk-chart>
<rk-board title="..." columns="Now,Next,Later">   drag-and-drop board with markdown export
ID | title | column (optional, items start in Inbox)
</rk-board>
<rk-cols><div>...</div><div>...</div></rk-cols>   side-by-side columns
```

Four or more `<h2>` sections give the page a contents rail. The kit computes the table's status bar,
the chart's average line, and the peak bar, so write only the data you were given.
`examples/plan.html` uses every component; read it when a component's lines are unclear.

## Parts the kit lacks

A game-UI mockup or a custom figure gets plain HTML for that part, styled by one `<style>` block
whose rules sit under a class of your own. Build it from the kit's tokens so it follows the theme:
`--bg --panel --ink --ink2 --muted --line --soft --accent`, the status pairs `--err/--err-bg
--warn/--warn-bg --info/--info-bg --ok/--ok-bg`, and the fonts `--f-display --f-body --f-mono`. The
rest of the page stays in components.

## Markdown instead

When the reader is an agent or a repo, write markdown; `node kit/md2html.cjs file.md` turns it into
a themed page (`--plain` for a plain render). The renderer adds:

- The first `# Title` becomes the page header; a line `stats: 7 days | 3 modules` becomes stat cells.
- Pills and IDs as above, in any text or table cell.
- Blockquotes starting `Risk:`, `Warning:`, `Note:`, `OK:`, or `Lesson:` become callouts.
- Fenced blocks by language: `chart` (optional `title:`, `type:`, `unit:` lines), `diagram`,
  `sequence`, and `tree` (each with an optional `title:` line), `steps`, `decisions`, `options`, and
  `board` (`title:`, `columns:`), each taking the same lines as its component. `luau` and `lua`
  blocks are colored.
