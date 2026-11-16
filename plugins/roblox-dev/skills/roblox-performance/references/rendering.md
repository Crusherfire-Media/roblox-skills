# Rendering, assets, and client memory

Most of this is about how a place is built, not about scripts. Changing art, mesh settings, or
lighting changes how the game looks, so propose these changes and let the user approve them.

## Design decisions

- **Set a scene budget for the weakest device you support** (`measuring.md`, "Budgets").
- **Build from a small kit of reused meshes and materials.** Identical meshes with the same
  material share one draw call however many there are, in any color and size. Variety is what
  costs. `[docs]` `[measured]`
- **Enable instance streaming for large worlds** (`networking.md`, "Streaming"). It is the
  biggest lever for client memory. Consider `Model.LevelOfDetail = SLIM` for static world models
  so streamed-out content stays visible cheaply. `[docs]`
- **Rely on the engine's occlusion culling for opaque geometry.** A custom system that hides
  what is behind walls is no longer needed for parts, meshes, and terrain. Distance culling of
  small props still helps. See "Culling". `[docs]` `[measured]`
- **Count emitters and beams, not particles.** Each enabled `ParticleEmitter` and `Beam` is a
  draw call of its own. `[measured]`
- **Spend shadows deliberately.** Shadow-casting local lights are the expensive part of
  realistic lighting. `[docs]`
- **Find out whether the frame is CPU-bound or GPU-bound first.** Compare
  `Stats.RenderCPUFrameTime` with `Stats.RenderGPUFrameTime`; the larger is the limit. Draw
  calls are mostly CPU cost. Triangles, overdraw, and shadows are mostly GPU cost. `[docs]`

## Draw calls

`Stats.SceneDrawcallCount` for 2,000 one-stud parts added to an empty baseplate (7 draw calls):
`[measured]`

| Scene | Draw calls |
|---|---|
| Identical parts | 7 |
| Random `Color` | 7 |
| Random `Size` | 7 |
| 10 different materials | 16 |
| `Transparency` 0.5, or random between 0.1 and 0.9 | 8 |
| `Transparency` 1 | 7, and no triangles drawn |
| Three shapes (block, ball, cylinder) | 9 |

- **What shares a draw call**: the same `MeshId` (or the same primitive shape) with the same
  `SurfaceAppearance`, or the same `TextureID`, or the same `Material`. `[docs]`
- **Free to vary**: `Color`, `Size`, `CFrame`. **Splits the batch**: a different mesh, material,
  `MaterialVariant`, or texture. `[docs]` `[measured]`
- **Semi-transparent parts batched into one extra draw call**, even with mixed transparency
  values. The old statement that each transparent part is its own draw call no longer holds.
  They still cost sorting and overdraw. `[measured]`
- **Duplicate uploads of one mesh do not batch.** Instancing keys on the asset ID, and the
  importer does not de-duplicate, so a map imported in one piece can hold many IDs for the same
  tile. Replace them with one `MeshId`. It also removes the duplicate copies from memory.
  `[docs]`
- **`Texture` and `Decal` instances draw a second layer of geometry** in the transparent pass,
  and each unique image is its own material. For anything repeated at scale, put the image in
  the material, a `MaterialVariant`, the mesh's `TextureID`, or a `SurfaceAppearance`. `[docs]`
- **A static model made of many unique parts can be baked into one mesh per material.** One
  example went from 12 draw calls and 100 instances per house to 6 and 6. Instanced kit pieces
  already share draws, so this helps unique geometry only. A merged mesh loses per-part edits,
  and one over about 2,000 unique vertices cannot occlude (see "Culling"), so bake detail, not
  walls. `[reported]` `[docs]`
- Keep part surfaces `Smooth`. Mixed stud surface types create unique geometry. `[docs]`

## Mesh settings

- **`RenderFidelity`**: leave it on `Automatic` (or `Performance`). `Precise` on many meshes is a
  listed performance problem. `Automatic` only changes anything beyond 250 studs. Roblox is
  replacing this property with Mesh Streaming, under which it is ignored, so do not build a
  workflow around it. `[docs]`
- **`CollisionFidelity`**: `Box` or `Hull` for anything decorative or non-colliding, since the
  collision geometry is kept in memory regardless of `CanCollide`. For meshes players do collide
  with, compare the modes per mesh, including `Tunable` (`physics.md`, "Collision settings").
  `[docs]`
- **`DoubleSided`**: only on card geometry such as leaves and cloth. It renders the mesh twice.
  `[docs]`
- A mesh is capped at 20,000 triangles. `[docs]`

## Textures and materials

- **Texture memory follows pixel count.** Halving each side quarters the memory. File size,
  format, and alpha make no difference: the engine transcodes everything. Most images need
  512x512 at most, and minor ones 256x256. `[docs]`
- **Texture streaming is on by default** and budgets texture memory per device, loading higher
  resolutions by importance. It covers meshes, `SurfaceAppearance`, decals, `MaterialVariant`,
  particles, and beams. It does not cover 2D UI images, SurfaceGui textures, terrain, sky, or
  `EditableImage`, so budget those by hand. `[docs]`
- **Do not atlas unrelated textures to save memory.** When one tile is needed at high
  resolution, the whole atlas loads at that resolution. A trim sheet shared by parts that are
  seen together is the case where an atlas helps. `[docs]`
- **Built-in materials use far less memory than custom textures.** No evidence was found that
  any one built-in material renders faster than another. `[docs]`
- **A full PBR set is up to four textures.** Use lower resolutions for the non-color maps.
  `[docs]`
- **Tint with `SurfaceAppearance.Color` instead of uploading a texture per color.** `[docs]`
- **Alpha cutouts (fences, foliage, netting)**: a `SurfaceAppearance` with
  `AlphaMode = Transparency` on a part at `Transparency = 0` renders as a cutout with proper
  depth. Raising the part to 0.02 or more switches to blending. `[docs]`
- **`MaterialVariant` with an alpha color map instead of `Texture` instances**: reported by this
  skill's author as noticeably faster at 5,000 or more surfaces on screen, and not benchmarked
  here. In October 2026 `MaterialVariant.AlphaMode` was a Studio-only beta that published
  clients ignored. Check that it has shipped before relying on it; the `SurfaceAppearance`
  cutout above is the shippable equivalent. `[reported]`
- `EditableImage` and `EditableMesh` have strict client memory budgets that Studio does not
  enforce. Creation can fail on a device. `[docs]`

## Transparency

- **Prefer `Transparency` 0 or 1.** Values in between leave the opaque pass, need sorting, and
  add overdraw. `[docs]`
- **A fully transparent part is not drawn and casts no shadow, but it is not free.** It still
  costs an instance, memory, and physics and query work. 2,000 parts at `Transparency` 1 added
  no triangles and no shadow triangles, with `CastShadow` on or off, so hitboxes and triggers
  need no `CastShadow` change. Roblox's MicroProfiler guidance says parts cast shadows
  "regardless of transparency", which did not reproduce. Two cases do cast: a decal on a
  transparent part casts its own shadow, and a part at any transparency below 1 (0.99 included)
  casts a full one. `[measured]`
- **Stacked semi-transparent surfaces multiply GPU cost** (leaf cards behind leaf cards, glass
  behind glass, large particles). `[docs]`
- **See-through objects draw in order of their centers, not per pixel.** Transparent parts,
  particles, and in-world GUIs are sorted back to front by how far each one's center lies along
  the camera's view direction. A huge transparent surface (an ocean, fog, a glass dome) has one
  center, so once that center is beside or behind the camera it sorts as nearest and draws over
  every see-through thing in front of it, at any distance. Make the surface opaque, or keep its
  center well ahead of the camera: move it sideways with the camera, and shift any `Texture`'s
  `OffsetStudsU` and `OffsetStudsV` against the move so the pattern stays still. Move it only
  when the center comes closer than a minimum lead, and then put it well past that minimum, so a
  full camera turn moves it a few times instead of every frame. The surface must reach well past
  that lead in every direction, or its edge comes into view. `[in-game]`
- **`Glass` hides see-through objects behind it**: transparent parts, decals on transparent
  parts, particles, and in-world GUIs. When a `Glass` surface wrongly sorts as nearest, what it
  covers disappears instead of showing tinted. `[docs]` `[in-game]`

## Lighting

- **Shadows draw the scene again.** Turn off `CastShadow` on small, distant, or moving detail,
  and `Shadows` on lights that do not need them. `[docs]`
- **Shadow-casting local lights are the main cost of the realistic lighting style.** Narrow
  `SpotLight`s are cheapest, `PointLight`s the most expensive. Keep ranges and angles small.
  `[docs]`
- **Moving lights, and shadow casters moving near lights, force lighting updates.** `[docs]`
- **`Highlight`**: each highlighted object is drawn on its own, the first one on screen carries
  most of the post-processing cost, toggling `Enabled` is cheap, and adding or removing one can
  rebuild geometry. A `Highlight` on a part can also stop that part from being occlusion culled.
  `[docs]`

## Culling

- **Occlusion culling is built in** for parts, meshes, and terrain: objects hidden behind opaque
  geometry are not drawn. 1,000 parts in 10 materials went from 17 draw calls to 3 behind a
  wall. `[docs]` `[measured]`
- **Emitters and beams were also not drawn when occluded** in the build measured here: 100
  emitters fell from 108 draw calls to 4 behind an opaque wall, and 100 beams from 107 to 3.
  Roblox staff said in 2025 that particles, beams, lights, and UI are not occlusion culled, so
  the engine appears to have changed. Before removing or adding a custom system that hides
  effects behind walls, measure on the target devices. `[measured]`
- **Off-screen emitters are not drawn.** Emitters are culled per object, so keep them local to
  their effect; one huge emitter covering a whole area is simulated and drawn whenever any of it
  is visible. `[measured]` `[docs]`
- **Good occluders are simple and fully opaque.** Block parts are the cheapest. Meshes over
  about 2,000 unique vertices, unions, and anything with alpha or transparency never occlude.
  Build walls as simple shells and keep high-detail meshes separate. `[docs]`
- **Culling saves drawing only.** Hidden objects still use memory, instances, physics, and
  replication. What is not in the place at all is free. `[docs]`
- **Hiding small props beyond a few hundred studs is a cheap win** in prop-dense maps. One demo
  dropped about a third of its draw calls by culling about 250 detail objects past 300 studs,
  rechecking only when the player moved and at most 50 objects per frame. `[reported]`
- The ways to hide an object at run time are compared in `instances-pooling.md`, "Pooling".

## Particles, beams, and effects

Draw calls on an empty baseplate (7): `[measured]`

| Scene | Draw calls |
|---|---|
| 100 `ParticleEmitter`s at rate 5 | 108 |
| 100 `ParticleEmitter`s at rate 50 | 108 |
| 10 `ParticleEmitter`s at rate 50 | 18 |
| 100 `ParticleEmitter`s, `Enabled = false` | 7 |
| 100 `Beam`s | 107 |
| 100 `Beam`s, `Enabled = false` | 7 |
| 100 `PointLight`s without shadows | 7 |

- **Each enabled emitter and beam is one draw call, whatever its rate.** Fewer emitters with
  higher rates beat many small ones. A disabled one costs no draw call.
- **Reuse emitters instead of cloning one per effect**: keep the emitter, move its attachment,
  and call `:Emit(count)`. Changing emitter properties every frame is expensive, so set them up
  once. `[docs]`
- **Particle cost on the GPU is fill rate and overdraw.** Keep particles small on screen and
  avoid heavy overlap. `[docs]`
- **The engine emits fewer particles at lower graphics quality.** Do not raise rates to
  compensate, and do not rely on particle count for gameplay information. `[docs]`
- Lower `Beam.Segments` for straight beams. `[docs]`
- `ViewportFrame`, `BillboardGui`, and `SurfaceGui` costs are in `ui.md`.

## Client memory

- **Read memory by category**: `GraphicsMeshParts`, `GraphicsTexture`, `GraphicsParts`,
  `PhysicsCollision`, `PhysicsParts`, `Instances`, `LuaHeap`, `Sounds`, `Animation`, `Gui`.
  `[docs]`
- **Running out of memory is the main crash cause on low-end phones.** Most Android players
  have 2 to 4 GB of RAM. A client crash rate above 2% to 3% points at memory. `[docs]`
- **Audio memory is released only when every instance referencing the asset is gone**, and
  animation assets stay loaded while scripts hold tracks. Do not keep every sound referenced at
  once. `[docs]`
- **Cache a sound for as long as its context can play it.** A Sound made when it is cued and
  destroyed after it plays leaves nothing referencing its asset, so the next cue loads the asset
  again before it can play: a 0.08-second UI tick took 0.44 s to load, so it played late every
  time. Holding one Sound with that `SoundId` keeps the asset cached, and cues played by cloning
  it start at once. Hold it while its context can play it and release it when that context ends,
  so audio memory stays bounded. A counted cache lets several holders share one Sound: the
  `vide-performance` skill's `references/patterns.md` has one that needs no Vide. `[in-game]`
- **Preload only what the first screen needs.** `PreloadAsync` over the whole `Workspace` makes
  joins much slower. `[docs]`
