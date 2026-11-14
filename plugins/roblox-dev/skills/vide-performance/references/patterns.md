# Patterns

Generic versions of the patterns the rules in `SKILL.md` name. Each assumes the project's Vide
module is required as `Vide`, with the functions it uses pulled out the way the `roblox-dev:vide` skill
shows, and follows the project's style guide. `LOUD_SNAKE_CASE` names are the component's own
constants.

## A showing flag through context

Each panel says whether it is on screen, and everything built inside reads that. A component
built outside any panel, such as in a story, reads the default and counts as showing.

```lua
const showingContext = context(function(): boolean
	return true
end)

-- Whether the panel this is built in is on screen. Call it in a component body.
local function isShowing(): () -> boolean
	return showingContext()
end

-- Keeps <connect>'s per-frame connection only while the panel is on screen.
local function whileShowing(connect: () -> RBXScriptConnection)
	local showing = showingContext()
	effect(function()
		if not showing() then
			return
		end
		cleanup(connect())
	end)
end

-- Builds UI with <build>, on screen only while <isOn> and the panel around it are.
local function showingScope<T>(isOn: () -> boolean, build: () -> T): T
	local isOuterOn = showingContext()
	local isScopeOn = derive(function(): boolean
		return isOuterOn() and isOn()
	end)
	return showingContext(isScopeOn, build)
end
```

A panel that plays its own exit wraps its content in `showingScope` with a flag that stays true
until the exit finishes, so nothing stops mid-animation.

## A counted sound cache

One cached `Sound` per `SoundId`, kept while anything holds it. Every holder gets its own
release, so screens that share a sound share one cached copy, and the last release frees it.
`CACHE_FOLDER` is a folder under `SoundService`, created only while the game is running, and
`RunService` is the service.

```lua
local cachedSounds: { [string]: Sound? } = {}
local holdCounts: { [string]: number? } = {}

-- Keeps <soundId> cached until the returned release is called. Releasing twice is harmless.
local function holdSound(soundId: string): () -> ()
	if not RunService:IsRunning() then
		return function() end
	end

	holdCounts[soundId] = (holdCounts[soundId] or 0) + 1
	if not cachedSounds[soundId] then
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Parent = CACHE_FOLDER
		cachedSounds[soundId] = sound
	end

	local isReleased = false
	return function()
		if isReleased then
			return
		end
		isReleased = true
		local count = (holdCounts[soundId] or 1) - 1
		holdCounts[soundId] = if count > 0 then count else nil
		if count > 0 then
			return
		end
		-- Deferred, so a release followed at once by a new hold keeps the cached copy.
		task.defer(function()
			if holdCounts[soundId] then
				return
			end
			local sound = cachedSounds[soundId]
			cachedSounds[soundId] = nil
			if sound then
				sound:Destroy()
			end
		end)
	end
end

-- Keeps <soundIds> cached while the panel this is built in is on screen. Call it in a
-- component body.
local function holdSoundsWhileShowing(soundIds: { string })
	local showing = showingContext()
	effect(function()
		if not showing() then
			return
		end
		for _, soundId in soundIds do
			cleanup(holdSound(soundId))
		end
	end)
end
```

- Play a cue by cloning its cached `Sound`.
- A hold for a component's whole life is `cleanup(holdSound(soundId))` in its body.
- The deferred destroy also keeps strict mode's second run of the effect from dropping the cached
  copy between its release and its new hold.

## What keeping saved

Rebuilt on every switch or visit, then built once and kept, in one game (`[in-game]`):

| What was rebuilt | Idle frame there | Before | Kept |
|---|---|---|---|
| Shop tab page (710 to 836 instances) | 20 ms | 34 to 41 ms on every switch | 24 to 25 ms after its first visit |
| Recipe picker (471 instances) | 8 to 10 ms | 48 to 53 ms on every visit | 25 to 26 ms after the first |
| Four leaderboards coming back into range | - | 92 ms, 2,700 instances | nothing built after the first time |
| Order ticket (pool of two views) | - | 156 instances per order | 44 to 64 |

## Kept pages keyed by a visited map

`indexes` keeps a key's item while the key stays in the table and updates its value source when
the value changes. Keys that never leave mean pages that are never destroyed.

```lua
--[[
	A page kept once built. Its presence flag starts false and turns true once it is built, as
	Vide's own present flag does, so the first visit plays the entrance too.
]]
local function keptPage(isOnShow: () -> boolean, build: (present: () -> boolean) -> Frame): Frame
	local isBuilt = source(false)
	local function present(): boolean
		return isBuilt() and isOnShow()
	end

	local slide = spring(function(): number
		return if present() then 1 else 0
	end, PAGE_PERIOD)
	local page = showingScope(function(): boolean
		return present() or slide() > GONE_BELOW
	end, function(): Frame
		return build(present)
	end)
	-- Only in a panel that grows in from near 0. Showing the page changes a scale above its text,
	-- so the engine measures that text again.
	create("UIScale")({
		Scale = function(): number
			return if isOnShow() then 1 else HIDDEN_PAGE_SCALE
		end,
		Parent = page,
	})
	isBuilt(true)
	return page
end

local function pages(props: PagesProps): Frame
	-- Every page shown so far, each with whether it is the one on show.
	local visited: { [string]: boolean } = {}
	local function pageKey(): { [string]: boolean }
		local current = props.Selected()
		visited[current] = true
		local keys: { [string]: boolean } = {}
		for key in visited do
			keys[key] = key == current
		end
		return keys
	end

	return create("Frame")({
		Name = "Pages",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),

		indexes(pageKey, function(isOnShow: () -> boolean, key: string): Frame
			return keptPage(isOnShow, function(present: () -> boolean): Frame
				return page(props, key, present)
			end)
		end),
	})
end
```

- The page binds `Visible` to the same "present or still sliding out" test.
- `HIDDEN_PAGE_SCALE` is 1.0001, too small a change to see. The page's `UIScale` is there for
  text built while its panel grew in from near 0, which one panel's hidden pages kept at a wrong
  size until something re-measured it (`roblox-performance/references/ui.md`, "Layout"). Leave it
  out of panels that do not grow in that way: every switch then lays out and measures both the
  page coming in and the page leaving, a cost that was not measured.
- `visited` lives in the component, so a remount, such as a story reload, starts empty.
- `pageKey` writes to `visited` as it reads the selection. That is safe because a second call
  with the same selection returns an equal table, which strict mode's second run relies on.

## A pool of views

For items that only ever replace each other (an order ticket leaving as the next arrives), keep a
small pool of views, each holding a source with the item it shows.

- Size the pool from measured demand (two tickets were ever on screen at once).
- Claim a free view for a new item and set its sources; release a leaving one, let its exit play,
  then hide it and reset its sources to a blank item, guarded so a late reset cannot blank a view
  that was claimed again.
- Bind everything that changes per item to the view's sources, including `Name` when specs or
  callers find views by name.
- Key the view's inner lists by item and position (for example `id * 1000 + index`), so a new
  item's rows are new rows and not the last item's rows updated.

## Replaying an entrance on a visit counter

A view kept between visits takes a `Visit` source that the host bumps each time it shows the
view again, and each part of the view that has an entrance resets when it changes.

This is a deliberate exception to "effects stay pure" in the `roblox-dev:vide` skill: the reset reacts to an
outside event that reaches the view as a source, and it moves springs rather than setting sources
to feed others. The deferral lets the host finish its own updates for that showing first. Where
the host can call into the view directly, a reset function the view registers and the host calls
from its own event handler avoids the effect altogether.

```lua
--[[
	Runs <reset> each time <visit> changes, once the host's other updates for that showing have
	landed, so springs placed there start from where a newly built view's would.
]]
local function onVisit(visit: (() -> number)?, reset: () -> ())
	if not visit then
		return
	end
	local seenVisit = untrack(visit)
	local isAlive = true
	cleanup(function()
		isAlive = false
	end)
	effect(function()
		local current = visit()
		if current == seenVisit then
			return
		end
		seenVisit = current
		task.defer(function()
			if isAlive then
				reset()
			end
		end)
	end)
end

-- In a tile that slides in from one slot further out and fades in:
local position, placeTile = spring(slotTarget, SLIDE_PERIOD)
local presence, placePresence = spring(presenceTarget, PRESENCE_PERIOD)
onVisit(props.Visit, function()
	local at = slot()
	placeTile({ position = at + math.sign(at), velocity = 0 })
	placePresence({ position = 0, velocity = 0 })
end)
```

- Do not cancel the deferred reset from a `cleanup` inside the effect. Under strict mode the
  first run's cleanup runs before the second run and would cancel the reset, and the second run
  returns early because `seenVisit` has already moved, so the reset would never happen.
- One-shot state the view sets up when it is built (an item already in place, an idle timer, a
  collapsed state) needs the same reset, and the host bumps whatever wake signal the view already
  has.
- Shared helpers that hide a spring's control return it as a second value, so the view can place
  the spring.

## Rows out of the tree, still built

The list works out how far it is scrolled as a share of its scrollable height (the canvas minus
the window), which stays the same while the panel scales, and turns that into its own pixels.
Each row is placed from its index and parented only near the window.

```lua
local function list(props: ListProps): ScrollingFrame
	local canvasY = source(0)
	local canvasHeight = source(0)
	local windowHeight = source(0)

	-- The list's height in its own pixels, and how far down it is scrolled in the same units.
	local function contentHeight(): number
		return FIRST_TOP + #props.Ids() * ROW_STEP
	end
	local function scrollTop(): number
		local scrollable = canvasHeight() - windowHeight()
		local share = if scrollable > 0 then canvasY() / scrollable else 0
		return share * math.max(0, contentHeight() - VIEW_HEIGHT)
	end

	local function row(id: string, index: () -> number): Folder
		local rowTop = spring(function(): number
			return FIRST_TOP + (index() - 1) * ROW_STEP
		end, GLIDE_PERIOD)
		-- Give or take a row, so a fast scroll never shows a row before it is parented.
		local isInWindow = derive(function(): boolean
			local top = rowTop()
			local windowTop = scrollTop()
			return top + 2 * ROW_STEP > windowTop and top - ROW_STEP < windowTop + VIEW_HEIGHT
		end)

		local built = showingScope(isInWindow, function(): Frame
			return rowView({
				Id = id,
				Position = function(): UDim2
					return UDim2.fromOffset(PADDING, rowTop())
				end,
			})
		end)

		-- The engine lays out hidden UI too, so a row off screen leaves the list instead of hiding.
		local slot = create("Folder")({
			Name = id,
		})
		effect(function()
			local parent = if isInWindow() then slot else nil
			if built.Parent ~= parent then
				built.Parent = parent
			end
		end)
		return slot
	end

	return create("ScrollingFrame")({
		Name = "List",
		CanvasSize = function(): UDim2
			return UDim2.fromOffset(0, contentHeight())
		end,
		Size = UDim2.fromOffset(LIST_WIDTH, VIEW_HEIGHT),

		changed("CanvasPosition", function(position: Vector2)
			canvasY(position.Y)
		end),
		changed("AbsoluteCanvasSize", function(size: Vector2)
			canvasHeight(size.Y)
		end),
		changed("AbsoluteWindowSize", function(size: Vector2)
			windowHeight(size.Y)
		end),
		values(props.Ids, row),
	}) :: ScrollingFrame
end
```

- The list manages the `Folder`; the row moves in and out of it. GUI objects inside a `Folder`
  draw as if they were children of the `Folder`'s parent.
- The canvas height comes from the data, so rows leaving the tree do not shrink it.
- The row's own per-frame work stops with it, through the same flag.

## A CanvasGroup only while it is drawn

```lua
local function rays(props: RaysProps): Frame
	return create("Frame")({
		Name = "Rays",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = props.ZIndex,

		-- Strength rises from 0 and falls back to it, so the group is nearly clear when it is made
		-- and when it is removed.
		show(function(): boolean
			return props.Strength() > 0
		end, function(): CanvasGroup
			return create("CanvasGroup")({
				Name = "Clip",
				BackgroundTransparency = 1,
				GroupTransparency = function(): number
					return 1 - props.Strength()
				end,
				Size = UDim2.fromScale(1, 1),
				ZIndex = props.ZIndex,

				create("UICorner")({
					CornerRadius = props.Corner,
				}),
				spinningRays(props),
			})
		end),
	})
end
```

- The host `Frame` is what callers parent and measure, so their code does not change.
- Give the CanvasGroup the host's `ZIndex` in case the ScreenGui uses global ordering.
- Adding the panel's showing flag to the condition frees the group while the panel is closed, but
  it is then made at full strength when the panel reopens, so its white first frame can show. Do
  that only when the panel grows in from nothing, when the group fades in after it is made, or
  with the hold below.

When nothing fades the group itself, as with button ripples whose rings fade inside an opaque
group, hold the group nearly clear for its first two drawn frames and for a moment before
`show` removes it. `present` turns false when the condition does, and the exit delay the builder
returns keeps the group parented, held clear, until it is removed:

```lua
-- Under 1, in case the engine skips drawing a fully clear group and so never makes its texture.
const HIDDEN_GROUP_TRANSPARENCY = 0.99
const HIDDEN_FIRST_FRAMES = 2
const HIDDEN_EXIT_SECONDS = 0.05

-- Runs <onDone> once <frames> frames have been drawn, just before the next one is.
local function afterDrawnFrames(frames: number, onDone: () -> ()): RBXScriptConnection
	local framesLeft = frames
	local connection: RBXScriptConnection
	connection = RunService.PreRender:Connect(function()
		if framesLeft > 0 then
			framesLeft -= 1
			return
		end
		connection:Disconnect()
		onDone()
	end)
	return connection
end

-- A show-built group's GroupTransparency: held for its first drawn frames and once <present>
-- turns false. Call it in the builder.
local function heldTransparency(present: () -> boolean): () -> number
	local isRevealed = source(false)
	cleanup(afterDrawnFrames(HIDDEN_FIRST_FRAMES, function()
		isRevealed(true)
	end))
	return function(): number
		return if isRevealed() and present() then 0 else HIDDEN_GROUP_TRANSPARENCY
	end
end

-- In the host Frame's children. hasRings is true while any ring plays.
show(hasRings, function(_, present: () -> boolean): (CanvasGroup, number)
	return create("CanvasGroup")({
		Name = "Clip",
		BackgroundTransparency = 1,
		GroupTransparency = heldTransparency(present),
		Size = UDim2.fromScale(1, 1),

		rings(),
	}), HIDDEN_EXIT_SECONDS
end)
```

- `PreRender` fires just before each frame is drawn, so the hold lifts in the `PreRender` after
  the held frames. Counting a frame and lifting the hold in the same callback holds one frame
  fewer: sampling `GroupTransparency` every frame in a playtest showed such a counter holding one
  drawn frame instead of two.
- The hold removed a full-screen white frame at the end of a burst effect. On button ripples a
  barely visible flicker remained with one held frame and with two, so frame count is not its
  cause; whether holding at 1 instead of 0.99 removes it was not tested.
- The first two drawn frames of the effect are hidden, about 33 ms at 60 frames a second. The
  0.05 s exit is several drawn frames at usual frame rates.
- A group with a fade of its own takes both: `1 - (1 - held) * (1 - own)`.
- A press during the exit delay builds a new group beside the one being removed, so nothing is
  cut short.
- For a burst effect started from an event handler, create the CanvasGroup with `Instance.new` in
  that handler, parent the effect's pieces to it, and remove it in the function that stops the
  effect. Hold it the same way by hand: set the held transparency before parenting it and restore
  it after `afterDrawnFrames`; on stop, cancel that restore if it has not run, unparent
  persistent pieces (a glow frame), set the held transparency, and destroy the group after the
  exit delay. Without the cancel, an effect stopped within its first two frames is restored to 0
  just before it is destroyed. Keep the layer that holds the effect
  shown until the group is gone, and leave it shown if a new burst opened a group meanwhile.
  Destroying the group the moment the effect stopped drew a white frame over the whole layer.

## Rerunning only on a real change

```lua
-- Most steps of the roll format to the same text, so the label's binding reruns only when it changes.
local valueText = derive(function(): string
	return format(math.round(shown()))
end)

create("TextLabel")({
	Text = valueText,
})
```

For many elements driven by time, keep one clock source updated from one `PreRender` connection
(through `whileShowing`), and let each element `derive` its own value from it.
