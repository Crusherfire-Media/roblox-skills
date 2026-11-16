---
name: figma-to-roblox
description: Porting a Figma design into Roblox UI - which visuals to rebuild with UI instances and which to bake into images, per-property translation, and exporting baked art. Load it before building or reskinning Roblox UI from a Figma design or a screenshot of one, before exporting icons, sprite sheets, tiles, or 9-slice art from Figma for Roblox, and when recreating a Figma effect in Roblox. Load it even for a single component.
---

# Figma to Roblox

A Figma frame is a picture of UI at one size, in one state, with placeholder text. A Roblox port
rebuilds it as GuiObjects that resize, change state, and show real data on every screen. Each
visual in the design either becomes UI instances (**native**) or is exported once as an image
(**baked**), and that choice is made per visual before anything is built.

This skill covers the translation from Figma. How the UI code itself is written comes from the
project's UI skills: with Vide, load `roblox-dev:vide` and `roblox-dev:vide-ui-labs` alongside this one.

| Read | Before |
|---|---|
| [references/property-map.md](references/property-map.md) | Translating any Figma property: constraints, auto layout, fills, strokes, effects, text, opacity, components, motion |
| [references/images.md](references/images.md) | Exporting, sizing, and uploading baked art, and choosing a sprite sheet or single images: icons, tiles, 9-slice frames |

## Steps

1. **Read the design.** For everything in scope, collect the layer tree with sizes and auto layout,
   the tokens (color, text, and effect styles or variables), every variant and state (hover,
   pressed, disabled, selected, empty, loading, error), every device frame, and the designer's
   notes, with a screenshot of each frame and state as the reference.
   - Save it to files in the project's docs folder, or a folder the user names: the tokens, one
     file per component and screen, and the screenshots. Later steps and sessions read the files
     instead of querying Figma again.
   - Record the **reference size**: the size the project authors UI at. With Vide that is offsets
     for a screen 1080 pixels tall, grown on larger screens by one `UIScale` (the `roblox-dev:vide` skill's
     `references/screens.md`). Convert a desktop frame by 1080 divided by its height (a
     1920x1080 frame is 1, a 3840x2160 frame is 0.5). Take a phone or tablet frame's numbers as
     they are: they become that layout's metrics at scale 1.
   - With a Figma MCP server connected, load the skills it names before calling its tools. The
     code it generates targets the web: read it as a spec of structure and sizes.

   Done when every frame, variant, state, and token in scope is on disk, each with its screenshot
   saved or its node id recorded so it can be fetched again.

2. **Put the tokens in one theme module.** Colors as a color plus a transparency (Figma alpha `a`
   becomes transparency `1 - a`), text styles as font, weight, size, line height, and case, plus
   radii, stroke widths, spacing, and shadows, named as the design names them. Done when every
   color and size a component needs has a token.

3. **Sort every visual into native or baked** with the table below. The baked list is step 4's
   export list. Done when every layer in scope has a destination.

4. **Export and upload the baked art** by [references/images.md](references/images.md). Done when
   every baked visual has an asset id (and a sprite rect where it shares a sheet) in one module,
   and each one loads at the size it shows.

5. **Build components, then screens.** Build the smallest components first, one per Figma
   component set, translating each property by the property map; then assemble screens from
   them. Port the look and leave game behavior alone unless the design changes it. Every
   component gets the project's preview (a UI Labs story with Vide) with a control for each
   variant and state. Done when every component set in scope is one component with a prop per
   variant, its preview shows every state, and every screen is built from those components.

6. **Compare against the design.** At the reference size, set each component and screen to each
   state in turn and compare it with its screenshot: the `AbsoluteSize` and `AbsolutePosition` of
   each element against the layer boxes saved in step 1, then color, text, and alignment by
   sight. Check the other device frames by the UI skill's screen checks, and run the project's
   layout checks (with Vide, "Measuring the result" in `roblox-dev:vide`'s
   `references/layout-quality.md`). Done when every measured box matches to within 2
   pixels and every remaining difference is written down for the user, with a list of what they
   should check by eye.

## Native or baked

Rebuild a visual natively when a UI instance draws it as designed, or when it has to change with
state, size, or data. Bake it when Roblox has no instance that draws it, or when imitating it would
take a stack of instances for decoration that never changes.

| Visual | Destination |
|---|---|
| Solid fills and see-through fills | native: background color and transparency |
| Rounded corners, one radius on every corner | native: `UICorner` |
| A different radius per corner | baked as 9-slice, or native: round every corner and cover the square ones with a patch in the frame's color |
| Smoothed corners (squircles) | baked as 9-slice, or native `UICorner` when plain rounding is close enough |
| Solid strokes, inside, center, or outside | native: `UIStroke` |
| Strokes on some sides only | native: a thin frame per side |
| Dashed or dotted strokes | baked: a tiled or 9-slice image |
| Linear, radial, and angular gradients | native: `UIGradient` |
| Diamond gradients | baked |
| Shadows on frames, rounded frames, and text | native: `UIShadow` |
| Shadows and glows on icons, illustrations, and other shapes | baked into the image |
| Background blur (frosted glass) | native approximation: a darker, more opaque fill. A `BlurEffect` blurs the whole 3D view, not what lies behind one frame |
| Layer blur, blend modes, non-rectangular masks | baked, or approximated with color and transparency |
| Repeating patterns: grids, hexagons, stripes, noise, hatching | baked: one seamless tile, repeated by the image |
| Ornate borders and panels that stretch | baked: a 9-slice image |
| Icons and glyphs | baked: a sprite sheet per family that shows together, else an image each (`images.md`) |
| Logos, photos, and illustrations | baked: an image each |
| Text the game sets or translates | native: a text label |
| Player avatars, item and game thumbnails | native: a thumbnail content id |

- **One image beats a stack of instances.** A hexagon grid drawn with dozens of frames costs layout
  and draw calls every frame it shows; one tiled image costs a single small texture.
- **Native beats an image for anything a state changes.** A fill that recolors on hover, a bar
  that resizes, a corner that animates: build these from instances. An icon or tile that only
  changes color is baked in white and tinted with `ImageColor3`.

## Rules for the whole port

- **Reuse before building.** In a reskin, map each Figma component to the project's existing one
  and restyle it; add a component only where none exists.
- **Build for real data.** The frame shows one string at one width. Size text and lists for the
  longest real value and the empty case, by the UI skill's layout rules.
- **One instance per thing that draws or lays out.** Drop the groups and wrappers that only
  organize the Figma file: every extra level is layout work.
- **Leave room for Roblox's own UI.** Figma frames don't show the topbar buttons or the touch
  controls. Place against them from the live screen insets (with Vide, `references/screens.md`).
- **Name the gaps.** For each design value Roblox can't reproduce (letter spacing, a blend mode, a
  font Roblox doesn't ship), use the nearest native result and tell the user the design value and
  what you used.
- **Fill missing states from the tokens.** When the design lacks a state the UI needs (disabled,
  empty, loading, a long name), build it from the design's existing tokens and list it for the
  user to review.
