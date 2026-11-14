# Baked art: export, size, upload

How to turn the visuals SKILL.md marks baked into Roblox images. The first section and the last
two apply to every image; the middle three are one kind each. Image memory and draw-call costs
are in the `roblox-dev:roblox-performance` skill's `references/ui.md`.

## Sizing every image

- **Size for the largest it shows.** Export at its size at the reference size times the project's
  largest UI scale, rounded up to a whole scale (a UI that grows to 2.5x on a 4K TV exports at
  3x). An image drawn larger than its pixels blurs; one far larger than it shows wastes memory.
- **Keep each side at 1024 pixels or under.** Roblox stores a larger upload scaled down to 1024 on
  its long side, so a 2048 sheet arrives at half resolution. Split art that needs more into
  several images, and check a large sheet's resolution after upload.

## Sprite sheets or single images

A sprite sheet is one uploaded image holding many small pieces of art; each `ImageLabel` shows one
piece through `ImageRectOffset` and `ImageRectSize`. The whole sheet loads as one texture, so a
sheet pays off only when its pieces show together.

| Art | Upload as |
|---|---|
| A family of small icons that show together: input prompts for one device, HUD glyphs, currency and stat icons, rarity badges | A sheet per family |
| Large art: backgrounds, illustrations, logos, splash art | An image each |
| Art shown alone or rarely, from a large set: one item portrait out of hundreds | An image each |
| Art added or changed often: catalog and product art | An image each |
| Tiles and 9-slice frames | An image each, so `ScaleType` `Tile` and `Slice` work on the whole image |

- **Why a sheet.** One fetch instead of many, so the family appears at once instead of icon by
  icon; one asset to moderate and track; and images from one sheet drawn next to each other share
  a draw call (`roblox-dev:roblox-performance` skill, `references/ui.md`).
- **Why not.** A sheet loads whole even when one piece shows, it is capped at 1024 pixels per side
  (Sizing, above), and changing one piece means re-uploading the sheet under a new asset id.
- **Split by when art shows, not by kind.** Keyboard, gamepad, and touch prompts are three
  sheets, since a player sees one device's set; a sheet of every prompt loads two sets nobody
  sees.

Laying out a sheet:

- **Cells of at least 64 by 64 pixels, larger when the art shows large.** Prefer 128 where the
  sheet's 1024 limit allows (64 icons per sheet): a small cell blurs as soon as the UI scales up
  for large screens, and leaves too few pixels for fine detail.
- Use a regular grid of equal cells, so each piece's rect is its column and row times the cell
  size, and record the rects in the asset module (Uploading, below).
- Leave a few transparent pixels between each piece and its cell edge: when the image is scaled,
  neighboring pixels bleed in.
- **Export one-color icons in white on transparent** and tint them with `ImageColor3`, so one
  piece serves every color and state. Multicolor art (controller buttons, item art) keeps its
  own colors.
- Draw each piece on an `ImageLabel` sized at its display size, with `ScaleType = Fit`. The rects
  are in pixels of the uploaded image.
- Check a sheet on a real phone before shipping it: developers have reported (2025 to 2026) rects
  landing on the wrong piece on some phones and consoles while desktop drew them right, with no
  confirmed cause.

## Patterns: tiles

- Export **one seamless tile**: the smallest piece of the pattern that repeats, with its edges
  matching so the seam disappears.
- Draw it with `ScaleType = Tile` and `TileSize` in **offsets**, equal to the tile's display size,
  so the pattern keeps its density as the frame resizes. A `TileSize` in scale stretches the
  tile with the frame.
- Export one-color patterns in white and set color and strength with `ImageColor3` and
  `ImageTransparency`, so one tile serves every theme.
- A pattern that fades out gets a `UIGradient` on the image's `Transparency`. One that fills a
  rounded frame gets its own `UICorner` with the frame's radius: a parent's `UICorner` does not
  clip children.

## Stretchy frames: 9-slice

- Use 9-slice for a frame or panel whose corners and edges must keep their shape while the frame
  resizes: an ornate border, a dashed outline, corners with different radii.
- Export the frame at a small size that still holds each corner whole, with a plain stretchable
  middle. Set `ScaleType = Slice` and `SliceCenter` to the rect, in image pixels, of the part
  that stretches.
- Corners draw at their pixel size times `SliceScale`; set `SliceScale` to the display size over
  the export size (0.5 for art exported at 2x).
- Keep the frame at least as large as its two corners together, or the corners overlap.

## Transparency and edges

- Transparent pixels are set to black when an image is uploaded, which shows as a dark fringe
  around soft edges once the image is scaled. Export with the edge color carried into the
  transparent pixels (alpha bleed, "dilate" in image tools).
- A shadow or glow that follows an image's shape is baked into that image, with its edge bled as
  above. Shadows on frames and text stay native (`UIShadow`).

## Uploading and recording

- Upload with what the setup offers: Studio's Asset Manager, Open Cloud, or an upload tool when an
  MCP server provides one. Without one, give the user the files and wait for the asset ids.
- Upload under the account or group that owns the experience, so the experience has permission
  to load the image. Images pass moderation before they load.
- Keep every asset id, sheet size, cell size, and sprite rect in **one module**, named the way the
  design names them, and draw images only through it. Re-exporting a sheet is then a one-place
  edit.
- Keep the exported files, and the Figma frames they came from, with the design files saved in
  step 1, so a re-export starts from the same source.
- Check each upload in the game: the image loads (`IsLoaded` on an `ImageLabel`), it draws sharp
  at its largest size, and each sprite rect lands on its icon.
