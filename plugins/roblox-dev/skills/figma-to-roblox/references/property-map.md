# Figma properties in Roblox

What each Figma property becomes. Numbers are in offsets at the reference size (SKILL.md, step 1).
Visuals that SKILL.md's "Native or baked" table sends to an image are not repeated here; they go
to `images.md`.

## Contents

- [Frames, sizes, and constraints](#frames-sizes-and-constraints)
- [Auto layout](#auto-layout)
- [Fills and gradients](#fills-and-gradients)
- [Strokes and corners](#strokes-and-corners)
- [Shadows](#shadows)
- [Opacity and clipping](#opacity-and-clipping)
- [Text](#text)
- [Lines and images](#lines-and-images)
- [Components and variants](#components-and-variants)
- [Prototype and motion](#prototype-and-motion)

## Frames, sizes, and constraints

| Figma | Roblox |
|---|---|
| Frame, group, rectangle with a fill | `Frame` |
| Frame with no fill (a holder) | `Frame` with `BackgroundTransparency = 1` |
| Width and height | `Size` in offsets |
| X and Y | `Position` in offsets, measured from the parent's top-left |
| Constraint left | `AnchorPoint` X 0, `Position` X offset = left |
| Constraint right | `AnchorPoint` X 1, `Position` X = (1, -right) |
| Constraint left and right | `Size` X = (1, -(left + right)), `Position` X offset = left |
| Constraint center | `AnchorPoint` X 0.5, `Position` X = (0.5, offset from center) |
| Constraint scale | `Size` and `Position` in scale |
| Top, bottom, top and bottom, center, scale | The same rules on Y |
| Locked aspect ratio | `UIAspectRatioConstraint` |
| Min and max width or height | `UISizeConstraint` |
| Overlapping siblings | Explicit `ZIndex`, highest for the layer at the top of Figma's layer list |
| Rotation | `Rotation`, about the center (layouts ignore it: the `roblox-dev:vide` skill's `references/layout-quality.md`) |

## Auto layout

| Figma | Roblox |
|---|---|
| Direction horizontal or vertical | `UIListLayout.FillDirection` |
| Gap between items | `UIListLayout.Padding` |
| Gap set to auto (space between) | `HorizontalFlex` or `VerticalFlex` = `SpaceBetween` |
| Padding | `UIPadding` |
| Alignment | `HorizontalAlignment` and `VerticalAlignment`; `ItemLineAlignment` for the cross axis of each line |
| Child set to hug contents | `AutomaticSize` on that axis, with the other axis sized |
| Child set to fill container, along the layout | `UIFlexItem` with `FlexMode = Fill` |
| Child set to fill container, across the layout | `Size` scale 1 on that axis |
| Child with a fixed size | `Size` in offsets |
| Wrap | `UIListLayout.Wraps = true`. Compare the gap between wrapped lines with the design; where it must differ from the item gap, use a vertical list of horizontal rows |
| Grid auto layout | `UIGridLayout` with `CellSize` and `CellPadding`, or a wrapping list |
| Item order | `LayoutOrder`, with `SortOrder = LayoutOrder` |
| Child set to absolute position | A sibling outside the layout: a layout places every GuiObject child it has, so put the layout's children in their own frame and the absolute child beside it |
| Strokes included in layout | A border `UIStroke` takes no layout space: add the stroke width to the padding, or draw the stroke `Inner` |

## Fills and gradients

| Figma | Roblox |
|---|---|
| Solid fill | `BackgroundColor3`, with `BackgroundTransparency = 1 - alpha` |
| Layer opacity | Fold it into each transparency: `transparency = 1 - (1 - transparency) * opacity` |
| Linear gradient | `UIGradient` with `Type = Linear` |
| Radial gradient | `UIGradient` with `Type = Elliptical` (fits the box) or `Radial` (a circle) |
| Angular gradient | `UIGradient` with `Type = Conical`; `Rotation` sets the start angle |
| Gradient handles that don't span the box | `Scale` and `Offset` on the `UIGradient` |
| Several stacked fills | Stacked frames, one per fill that changes on its own; otherwise bake |
| Image fill: fill, fit, crop, tile | `ImageLabel` with `ScaleType` `Crop`, `Fit`, `ImageRectOffset` and `ImageRectSize`, or `Tile` with `TileSize` in offsets |

- **A gradient multiplies its parent's color.** Set the parent's `BackgroundColor3` (or the
  stroke's `Color`, or `TextColor3`) to white so the gradient's colors show as designed.
- **Angles.** `Rotation` is clockwise from left to right. A CSS angle (what Figma's generated code
  uses) maps to `Rotation = angle - 90`. The end points snap to the box edges, so check diagonals
  on boxes that aren't square against the screenshot.
- Color and transparency sequences hold at most 20 keypoints; keep a gradient to a few stops.

## Strokes and corners

| Figma | Roblox |
|---|---|
| Stroke | `UIStroke`; `ApplyStrokeMode = Border` on a text object, so it outlines the box |
| Stroke inside, center, outside | `BorderStrokePosition` `Inner`, `Center`, `Outer` |
| Stroke weight, color, opacity | `Thickness`, `Color`, `Transparency = 1 - alpha` |
| Several strokes | One `UIStroke` each, ordered by `ZIndex`, with `BorderOffset` for one drawn away from the edge |
| Gradient stroke | A `UIGradient` under the `UIStroke` |
| Corner radius | `UICorner` with `CornerRadius` in offsets; `UDim.new(1, 0)` for a pill or circle |

A surface inside a rounded frame and a stroke inside a clipping frame both need care: the `roblox-dev:vide`
skill's `references/layout-quality.md` covers them.

## Shadows

| Figma | Roblox |
|---|---|
| Drop shadow | `UIShadow`: X and Y to `Offset`, blur to `BlurRadius`, spread to `Spread`, color to `Color`, alpha to `Transparency = 1 - alpha` |
| Several drop shadows | One `UIShadow` each; `ZIndex` (negative) orders them |
| Inner shadow | `UIShadow` with `Inset = true`. Text has no inner shadow: `Inset` does nothing in text mode |
| Shadow on text | `UIShadow` with `Mode = Text` |
| Shadow on a see-through layer | `ShowBehindParent = false`, so the shadow doesn't tint what shows through |

A `UIShadow` takes the shape of its parent's box, rounded by its `UICorner`. Figma and Roblox draw
blur and spread differently: start from the Figma numbers and tune `BlurRadius` and `Spread`
until the edge matches the screenshot.

## Opacity and clipping

| Figma | Roblox |
|---|---|
| Opacity on a frame with children | Fold it into each child's transparency (Fills, above). Where overlapping children must fade as one picture, a `CanvasGroup` with `GroupTransparency` (with Vide, the `roblox-dev:vide-performance` skill: a CanvasGroup only while it is drawn) |
| Clip content | `ClipsDescendants`, which clips to the square box |
| Clip content on a rounded frame | A `CanvasGroup` with a `UICorner`, or round the children themselves |

## Text

| Figma | Roblox |
|---|---|
| Font family, weight, italic | `FontFace` via `Font.new` or `Font.fromName` with an `Enum.FontWeight` and `Enum.FontStyle`. Use a family Roblox ships; when the design's isn't one, pick the nearest and tell the user |
| Font size | `TextSize` |
| Line height | One line: the label's height. Wrapped text: `LineHeight` = line height divided by font size |
| Letter spacing | No equivalent; leave it out |
| Text case | `<uc>` with `RichText = true`, or uppercase the display string after localization (`string.upper` changes only ASCII letters) |
| Underline, strikethrough, highlight | `RichText` with `<u>`, `<s>`, or `<mark>` |
| Mixed styles inside one text layer | `RichText` with `<font>`, `<b>`, `<i>` tags |
| Horizontal and vertical alignment | `TextXAlignment` and `TextYAlignment` |
| Auto width | `AutomaticSize = X` with a height set |
| Auto height | `TextWrapped = true`, `AutomaticSize = Y`, width set |
| Fixed size | `Size` set, with `TextWrapped` or `TextTruncate` deciding what happens to long text |
| Truncate text | `TextTruncate = AtEnd` |
| Paragraph spacing | Separate labels in a list, or a blank line |
| Text stroke | `UIStroke` with `ApplyStrokeMode = Contextual` |
| Gradient text | A `UIGradient` on the label |

Text sizing, strokes, and gradients on text all have costs and rules in the `roblox-dev:vide` skill's
`references/screens.md` and the `roblox-dev:roblox-performance` skill's `references/ui.md`.

## Lines and images

| Figma | Roblox |
|---|---|
| Straight line | A 1-pixel `Frame` |
| Simple stroked path | `Path2D`, though a baked image is usually simpler |
| Icon or glyph from a sprite sheet | `ImageLabel` with `ImageRectOffset` and `ImageRectSize`, tinted with `ImageColor3` |
| Placeholder photo of a player or item | A thumbnail content id (`rbxthumb://type=AvatarHeadShot&id=…&w=150&h=150`) |

## Components and variants

| Figma | Roblox |
|---|---|
| Component set | One component (a function or module) |
| Variant property | A string-enum prop |
| Boolean property | A boolean prop |
| Text property | A string prop |
| Instance swap property | A prop that takes the child (an icon sprite, a component) |
| States the game sets (selected, disabled, owned) | Props on the one element, so nothing jumps or reflows when the state changes |
| Interactive states (hover, pressed, focused) | The component's own pointer and selection state, not props the caller drives |
| Nested component instances | The child component, called with the overrides as props |

## Prototype and motion

| Figma | Roblox |
|---|---|
| Transition with a duration and easing | With Vide, a `spring` (the `roblox-dev:vide` skill); otherwise a tween with the same duration and the nearest `Enum.EasingStyle` |
| Spring with mass, stiffness, and damping | Period = 2π·√(mass / stiffness), damping ratio = damping / (2·√(stiffness·mass)) |
| Overlays (open as overlay) | A layer shown above the screen, with a scrim frame for the dim |
| Scroll overflow | `ScrollingFrame` with `AutomaticCanvasSize` |

Where the design's motion conflicts with the project's motion rules (the `roblox-dev:vide` skill prefers
damped motion for changes the game makes), ask the user which wins. Motion costs are in the
`roblox-dev:roblox-performance` skill's `references/ui.md`.
