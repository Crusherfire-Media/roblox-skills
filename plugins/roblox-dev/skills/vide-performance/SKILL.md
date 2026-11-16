---
name: vide-performance
description: Keeping Vide UI fast in Roblox, and its sounds cached so they play on time. Load it with the roblox-dev:vide skill before building UI that opens and closes often, keeps pages or tabs, holds hundreds of instances or a long scrolling list, uses a CanvasGroup, or plays sounds; when a panel, tab switch, list, or world board stalls a frame or stays slow while it animates; when a closed panel still costs time; when a UI sound plays late; when UI flickers, draws blank at low graphics quality, or blinks white for a frame; and when asked to profile or optimize Vide UI.
---

# Vide performance

This skill is how Vide UI's costs look in Vide code, the patterns that remove them without
changing the look, and how to find them.

It builds on two skills. Load them too:

- `roblox-dev:vide` for how Vide works (scopes, `show`/`indexes`/`values`, `derive`, springs, `cleanup`).
- `roblox-dev:roblox-performance` for the ground rules (no number, no optimization; same workload before and
  after; revert what does not move the number; behavior-changing levers need the user's
  approval; the report format), for measuring in general and reading MicroProfiler dumps
  (`references/measuring.md`), and for the engine facts about UI (`references/ui.md`). This
  skill links to those facts instead of repeating them.

**Evidence.** Every number here is `[in-game]` (the evidence tags in `roblox-dev:roblox-performance`) unless
the rule says otherwise. That game ran Vide 0.4 with a local patch that makes unsubscribing a
dependent constant-time, so destroying large subtrees cost less there than in stock Vide. Measure
in your place before relying on a number.

## Where Vide UI time goes

| Symptom | Usual cause | First measurement |
|---|---|---|
| One long frame when a panel, tab, or page opens, or a world board comes into range | A rebuild: hundreds of instances created in one frame | Instances added per frame beside frame times |
| Several slow frames while a panel grows or scales in | Layout of everything parented under the panel, every frame, plus size listeners | Layout probe after a scale change |
| Slow while the UI is closed or scrolled away | Per-frame work in hidden UI | Script profiler with the panel closed |
| Slow while text counts or timers tick | Bindings rerunning every frame, or text that really changes every frame | Text changes per frame, then the profiler's callers of `TextLabel.Text` |
| UI flickers or draws blank at low graphics quality | Too many CanvasGroups for the quality level's texture budget | CanvasGroups that exist and that are drawn |
| A UI sound plays late, the first time or every time | Nothing kept it cached, so it loads its asset when cued | `IsLoaded` on the Sound at the moment it plays |

`references/finding-costs.md` has the probe for each row and the traps that faked results.

## Rules

This section is the one place that decides when Vide UI gets these patterns.

- **Always:** "A kept view comes back the way a new one arrives", "Per-frame work runs only while
  its UI is on screen", "A UI's sounds stay cached while it can play them", "CanvasGroups exist
  only while they are drawn", and "Keys for `indexes` and `values` come from one measurement".
  Skipping these makes the UI wrong or late, or keeps it working while nobody can see it. A UI
  with neither per-frame work nor sounds needs no showing flag.
- **When a cost is named:** "Keep UI that comes and goes", "Take what nobody can see out of the
  tree", "Animations that scale a panel lay out all of it on every frame", and "Rerun a binding
  only when its output changes". Apply them when a profile names the cost, or when a design-time
  estimate does: a build of hundreds of instances on every open, switch, or visit. Otherwise
  write plain Vide as the `roblox-dev:vide` skill teaches. Keeping instances costs memory for as long as
  they live (`roblox-performance/references/instances-pooling.md`).

### Keep UI that comes and goes

Tabs, pages, cards, pickers, world boards, and tickets that are rebuilt on every switch or visit
cost a whole build each time. Build each once and keep it: mark it off screen, hide it, or reuse
it with new data. What keeping saved in one game is in `references/patterns.md`, "What keeping
saved".

- Key `indexes` by a visited map, every key seen so far mapped to whether it is the one on show,
  so keys never leave and Vide never destroys a page. A pool of views that take new data works for
  items that only ever replace each other. Both are in `references/patterns.md`.
- Keeping moves the cost to the first build, which still stalls. Spreading a first build over
  several frames changes when things appear, so it needs the user's approval.
- A kept view keeps state a fresh one would not have. Reset what a new one would show (a list
  scrolled back to the top), stop following network data while it is away (a board stops
  following server data while out of range), and stop its per-frame work (see below).
- In one panel that grew in from near 0, kept pages built at the start of the grow-in and hidden
  with `Visible` kept wrongly measured text, which showed only once a page was shown
  (`roblox-performance/references/ui.md`, "Layout"). For a panel that grows in that way,
  `keptPage` in `references/patterns.md` gives each kept page its own `UIScale`, 1 while it shows
  and 1.0001 while hidden, so showing it changes a scale above its text and the engine measures
  that text again. A panel that fades or slides in instead never measures its text at a tiny
  scale, but changing the entrance is the user's call.

### A kept view comes back the way a new one arrives

Vide's `present` flag starts false and turns true right after the builder runs, and entrance
springs depend on that. A view that is kept stays present, so its entrance does not play again.

- A kept page's own presence flag starts false and turns true once it is built. Passing `true`
  from the start made every first visit appear in place, without its slide.
- A view reused across visits takes a visit counter. On each change, after the host's other
  updates for that showing have landed, it snaps its springs to the values an entrance starts
  from and resets one-shot state (flights, idle timers, collapsed panels).
- Check by sampling the moving element's `Position` every frame after a return visit and
  comparing it with a first visit.

### Take what nobody can see out of the tree

`Visible = false` stops drawing but not layout (`roblox-performance/references/ui.md`). Hiding a
kept page is still the cheap default: a hidden page costs layout only when something above it
lays out again, such as a panel scaling in, and setting `Visible` is far cheaper than reparenting.

- **Kept pages:** hide them with `Visible` until a layout probe shows hidden pages in the cost.
  Then move the pages that are not on show out of the tree through a host `Folder` each, the way
  rows do below, and measure what reparenting a page costs on each switch before keeping the
  change.
- **Lists of hundreds of rows** whose rows carry state or animations: keep each row built, but
  parent it only while it is within a row of the scroll window, through one `Folder` per row that
  the list manages. That took one panel from 2,844 GUI objects to 417 and its grow-in from
  12.7 ms a frame over idle to 2.7. The canvas height has to come from the data, not from the
  children.
- **Longer lists**, past the size `roblox-performance/references/ui.md` names for a row pool:
  keep a pool of rows the size of the window and fill them from the scroll position, as that file
  says. Keeping every row built would cost more memory than the layout it saves.
- Parenting a big kept subtree back lays all of it out again. Whether a ScreenGui with
  `Enabled = false` skips layout, which would make disabling it a cheaper way to hide one, was
  not measured.

### Per-frame work runs only while its UI is on screen

A panel with per-frame work or sounds tells what it builds whether it is on screen, through a
Vide `context`, and every per-frame connection or animation clock inside goes through that flag.
Hiding the instance is not enough: its per-frame connection keeps running.
`references/patterns.md` has the helpers. Use the project's own showing helpers if it has them.

- Stripes drifting on progress bars scrolled out of view cost 400 ms of script per 10 seconds,
  and 21 ms once they checked the flag.
- World UI that exists once per place (boards, signs) stops its clocks and its data following
  past its draw distance.
- A kept page is on screen while it is present or still sliding out.

### A UI's sounds stay cached while it can play them

Each UI keeps the sounds it plays cached, so each cue plays at once from the cache instead of
loading its asset again and playing late (the engine fact and the measured delay are in
`roblox-performance/references/rendering.md`, "Client memory"). Cache them by holding them
through a counted cache scoped by the showing flag, so screens that play the same sound share
one cached copy. `references/patterns.md` has the cache and the hold. Use the project's own
counted sound cache and holds if it has them.

- A panel, page, world board, or in-world area holds the sounds it plays from its component body,
  inside its showing scope, so they are cached while it is open and released when it closes.
  Outside any showing scope the same hold lasts the component's whole life.
- UI that can sound at any moment holds for its whole life, so even its first sound is on time:
  toasts, and the always-up HUD, which also holds the shared sounds every screen's buttons play.
  Each screen's own list sits beside the code that plays it and leaves those shared sounds out.
- A sequence shown in one place but started from another (an overlay mounted at startup and
  started from a shop or by an automatic repeat) takes a prop for when it could start soon, and
  holds while that or its own active flag is true.
- A hold whose condition reads several sources goes through `derive`, so a rerun that gives the
  same answer never releases and re-holds the sounds.
- The hold does nothing while the game is not running, so a story caches nothing
  (`roblox-dev:vide-ui-labs`, "Keep UI safe to run in edit mode").
- Check with the probe in `references/finding-costs.md`.

### CanvasGroups exist only while they are drawn

The budget CanvasGroups share, what happens past it, and what cutting idle ones did for one game
are in `roblox-performance/references/ui.md`. The Vide side is when each one exists.

- Give the component a transparent host `Frame` and build the CanvasGroup inside it with `show`:
  while an effect plays (button ripples), while lit (rays), while its page is on screen, or for
  the length of a burst effect (made and destroyed by the function that starts and stops it).
- **Make and remove a CanvasGroup only while its own `GroupTransparency` is near 1.** One can
  draw a white frame at both moments, and content faded out inside it does not hide that frame.
  Let a fade from nothing drive the group's own transparency, or hold it nearly clear
  (`references/patterns.md`, with what the hold covers). Never move existing content into a
  temporary CanvasGroup and back.
- A CanvasGroup inside a panel that scales in is resized, and its texture made again, on every
  frame of the animation, which `roblox-performance/references/ui.md` says to avoid. Where the
  design allows, build it once the scale-in ends, held as above; building it later changes what
  shows during the scale-in, so that is the user's call. Otherwise count it in the scale-in's
  cost.
- Replace one with plain UI only when the look is identical. `ClipsDescendants` clips to the
  rectangle and ignores `UICorner`, and rotated objects under a clipping ancestor lose their clip
  or their rotation, so spinning rays, tumbling pieces, and tilted marks clipped to rounded
  shapes need a CanvasGroup. A group fade looks different from per-element fades wherever partly
  transparent pieces overlap, which shows during the fade.

### Animations that scale a panel lay out all of it on every frame

Why a scale animation costs layout, text shaping, and size-listener time on every frame is in
`roblox-performance/references/ui.md`. In Vide:

- Taking off-screen content out of the tree (above) cuts the cost most, since it grows with what
  is parented.
- A `changed("AbsoluteSize")` listener that only needs a scale-free value (a ratio, a count)
  feeds a `derive`, so a scale step writes nothing.
- New UI moves or fades in instead of growing, as `vide/references/screens.md` sets out. Changing
  an existing scale-in to a fade or a slide removes its per-frame layout, but it changes the look,
  so it is the user's call.

### Rerun a binding only when its output changes

Vide writes a binding's result every time the binding reruns. A write of an unchanged value is
cheap for the engine (`roblox-performance/references/luau.md`), so the cost is the rerun itself
and the write it makes.

- A binding whose input changes every frame but whose output rarely does (formatted text, a
  rounded number, a color step) goes through `derive`, which reruns its readers only on a real
  change.
- Text that really changes every frame pays a text write each time (the cost with `AutoLocalize`
  is in `roblox-performance/references/ui.md`). Whether it may change less often is a question
  about what it shows, so it is the user's call.
- Many elements that animate from time read one shared clock source and `derive` what they show,
  instead of each connecting its own per-frame event. Drive the clock from `PreRender`, which
  runs once per drawn frame; `Heartbeat` and the physics events can fire several times per drawn
  frame (`roblox-performance/references/physics.md`, "Moving things").

### Keys for `indexes` and `values` come from one measurement

A count or key built from two measured sizes wobbles while they update a frame apart, and every
wobble destroys and rebuilds instances. Measure once, from one instance, and let a count that
only grows stay grown.

## Finding the cost

Before profiling or optimizing Vide UI, follow the steps at the top of
[references/finding-costs.md](references/finding-costs.md): numbers taken the way players get them,
the frame named, one change measured on the same workload, and the look checked afterward.

## Common problems

When a symptom from the table in "Where Vide UI time goes" or a visual glitch from these patterns
shows up (a kept page that appears in place or loses its text, a reused view that does not animate
in, a white blink, a label that changes several times per frame), find it in
[references/common-problems.md](references/common-problems.md).
