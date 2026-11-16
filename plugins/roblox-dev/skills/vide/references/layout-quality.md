# Layouts that measure clean

Most layout defects in agent-built UI come from a handful of habits: a fixed width that assumed a
short string, a stroke nobody left room for, a gap typed twice with two values. Each section below
gives the habit to keep and why. Build to these, then measure the mounted UI by "Measuring the
result" at the end: the practices keep that check clean, and the check is the last catch, not the
design method.

Examples use the project's Vide functions as the main skill file does (`create`, `source`), and
named constants for every size.

## Rounded frames and the surfaces inside them

A surface inside a rounded frame (a page on a backing, a face on a lip, a fill in a bar) gets its
own `UICorner`, with a radius of the outer radius minus the inset. Without one its square corners
draw over the outer curve; with a radius that is too small the colored rim thins at the corners.

```lua
const OUTER_RADIUS = 16
const INSET = 3

create("Frame")({
    Name = "Backing",
    create("UICorner")({ CornerRadius = UDim.new(0, OUTER_RADIUS) }),

    create("Frame")({
        Name = "Page",
        Position = UDim2.fromOffset(INSET, INSET),
        Size = UDim2.new(1, -2 * INSET, 1, -2 * INSET),
        create("UICorner")({ CornerRadius = UDim.new(0, OUTER_RADIUS - INSET) }),
    }),
})
```

- `ClipsDescendants` clips to the square box and ignores `UICorner`, so it never rounds children.
  A `CanvasGroup` with a `UICorner` does, at a texture-memory cost (`roblox-dev:vide-performance` skill).
- A patch in the outer frame's own color that squares one corner on purpose (a spine, a tab
  joint) is fine: it reads as part of the frame.
- Keep both radii and the inset as named constants next to each other, so changing one shows
  that the others depend on it.

## Strokes inside lists and clipping frames

A border `UIStroke` draws outside its frame's box. Inside a `ScrollingFrame`, a frame with
`ClipsDescendants`, or a `CanvasGroup`, the part past the clipping edge is cut off: the left and
right of every card, the top of the first one, and the bottom of the last.

- Pad the clipping frame by the stroke thickness on every side (a `UIPadding`), and add the same
  amount to whatever sizes the list, so the outer gap still matches the design.
- Or draw the stroke inside the box with `BorderStrokePosition = Enum.BorderStrokePosition.Inner`,
  when a slightly smaller face is acceptable.
- A card that grows on hover or press needs room for its largest size, not its resting one.

## Scroll bars

A visible scroll bar draws over the content's edge unless the list leaves room for it, and
`VerticalScrollBarInset = ScrollBar` only moves the content flush against the bar.

```lua
const STROKE = 2
const SCROLL_BAR = 6
const SCROLL_GAP = 6

create("ScrollingFrame")({
    ScrollBarThickness = SCROLL_BAR,
    VerticalScrollBarInset = Enum.ScrollBarInset.None,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),

    create("UIPadding")({
        PaddingLeft = UDim.new(0, STROKE),
        PaddingTop = UDim.new(0, STROKE),
        -- Only while the list can scroll; a list that fits keeps its sides even.
        PaddingRight = function()
            return UDim.new(0, STROKE + if scrolls() then SCROLL_BAR + SCROLL_GAP else 0)
        end,
        PaddingBottom = UDim.new(0, STROKE),
    }),
})
```

- Use `AutomaticCanvasSize` instead of computing `CanvasSize` from a count and a pitch: a hand
  computed canvas goes stale the first time a row's height or the padding changes.
- Leave a gap of 4 or more between the content and the bar.

## Text that fits

- Budget a text column from what shares its row: the row's width minus the controls beside it
  and the gaps. A row with a small switch gives its text more room than a row with a wide
  slider; one fixed text width for every row type cuts the short-control rows for no reason.
- Size for the longest real string, not the sample. Give every story a long-text control, so the
  cut case is one control away (the `roblox-dev:vide-ui-labs` skill).
- Decide what happens to text that can still run long: wrap it into a box that grows
  (`TextWrapped` with `AutomaticSize.Y`), or cut it (`TextTruncate.AtEnd`) and show the rest in a
  tooltip. Text with neither spills past its box.
- A tooltip that shows the full text marks its label with a `FullTextTooltip` attribute set to
  true, so a layout check knows nothing is lost. A shared tooltip component sets it on the
  GuiObject it attaches to whenever it shows that object's own text. Touch screens have no hover,
  so on touch prefer wrapping, or show the same text on press.
- Give a label's box at least one line of height (`TextSize` times `LineHeight`) plus its
  vertical padding.
- `AutomaticSize` grows the axes it names from the size you set. A label with
  `AutomaticSize.X` and a `Size` of 0 on Y is squashed to nothing; give the other axis a size.
- `TextScaled` without a `UITextSizeConstraint` draws a short string huge and a long one tiny.
  Prefer a fixed `TextSize` with truncation or wrapping.

## Labels that share a row

- Place a label and its value, or a title and a badge, with one `UIListLayout` (or size the first
  to its text) instead of fixed offsets that assume how wide the first one's text is.
- A badge, icon, or notice dot near text either gets room reserved in the row or rides outside
  the text, over the frame's corner.
- An opaque element that is drawn later covers what is under it, whatever the tree looks like:
  check `ZIndex` and sibling order when two things share space.

## Gaps between related tiles

- Space every member of a group from one gap constant: the `Padding` of one `UIListLayout` or
  `UIGridLayout`, or offsets computed from that constant.
- Rows built as separate frames (a header row above two rows of two) need the same gap between
  the rows as inside them. Two layouts with their own `Padding` values drift apart.
- Keep a container's inset equal on opposite sides unless the design asks otherwise, and subtract
  the scroll bar's room before comparing them.

## Hit areas

- A see-through frame drawn on top with `Active = true` (a full-screen tint, a cutscene cover, a
  drag catcher) takes every click under it, even after it fades out. Bind its `Visible` or
  `Active` to whether it is showing.
- A larger press area around a small button should be the button: one `GuiButton` that wraps the
  visible art, not a second button stacked over the first.

## Images and rotation

- Icons and sprites use `ScaleType.Fit` (or `Crop`), or a size with the sprite's own aspect.
  `Stretch` is for art meant to stretch: strips, ribbons, and paper textures.
- A `UIListLayout` or `UIGridLayout` ignores `Rotation` on the children it places. Rotate an
  element inside a plain frame that the layout places.

## Whole-number offsets

Offsets with fractions truncate when drawn, so a row built from a width divided by a count comes
out short or runs over. Round computed offsets (`math.floor`, `math.round`), and give the
leftover pixels to one element.

## Measuring the result

Mount the UI where the engine lays it out, then run Luau in that session that walks its
GuiObjects and reads their measured boxes (`AbsolutePosition` and `AbsoluteSize`):

- In edit mode, mount a story with the loader from `roblox-dev:vide-ui-labs`'s
  `references/story-check.md` into a `Frame` sized like the story's preview, inside a ScreenGui
  under `CoreGui`, so nothing is saved with the place. Destroy the scope and the ScreenGui when
  done.
- In a playtest, measure the screen under the player's PlayerGui.

Report what it finds, and fix each finding or tell the user why it stays:

- **Cut or spilled text:** a text object whose `TextFits` is false, unless it carries the
  `FullTextTooltip` attribute.
- **Overlapping or covered text:** two visible text objects, or a text object and an opaque
  sibling drawn above it, whose boxes intersect.
- **Clipped outlines:** a border `UIStroke` drawn outside the box (`BorderStrokePosition`
  `Outer`) whose frame's box, grown by the stroke's `Thickness`, crosses the box of a clipping
  ancestor (`ClipsDescendants`, a `ScrollingFrame`, or a `CanvasGroup`).
- **Crowded scroll bars:** a `ScrollingFrame` whose canvas is taller than the frame while a child
  reaches within the bar's thickness plus 4 of the frame's right edge.
- **Corners:** a child that covers a rounded parent's corner without a `UICorner` of its own, or
  with a radius below the outer radius minus its inset.
- **Uneven gaps and insets:** related tiles whose edge-to-edge gaps differ, or a container whose
  opposite insets differ once the scroll bar's room is subtracted.
- **Fractional offsets:** a `Size` or `Position` offset that is not a whole number.
- **Blocked input:** a see-through frame with `Active = true` covering buttons while it shows
  nothing.

Then look at the screenshot: the measurement finds broken boxes, and the user judges the look.
