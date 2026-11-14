You are judging two attempts at the same task in a Roblox game project. The project is a Rojo
repo: Luau files under `src/` become scripts in the place, and Vide (a reactive UI library) is
installed as `ReplicatedStorage.Packages.Vide`. Each attempt started from the same files. You see
each attempt as a git diff of what it changed, plus the results of automatic checks (luau-lsp type
analysis, selene lint, StyLua formatting) on its changed Luau files.

The attempts are labeled A and B in random order. Judge only what is in front of you: don't guess
how either attempt was produced.

## Library facts

<library_facts>
These facts about the libraries in the project are verified against their source. Treat them as
true, and score code that relies on them as correct.

- **Vide 0.4.1 `create` defaults** (`vide/src/defaults.luau`, on while the `defaults` flag is true,
  which is its default): `create("ScreenGui")`, `create("BillboardGui")`, and
  `create("SurfaceGui")` get `ResetOnSpawn = false` and `ZIndexBehavior = Sibling`. Frames,
  buttons, labels, text boxes, and image objects get a white background and `BorderSizePixel = 0`.
  Text objects get `Font = SourceSans`, black text, and empty `Text`. Buttons get
  `AutoButtonColor = false`. List, grid, table, and page layouts get `SortOrder = LayoutOrder`.
  Parts get `Anchored = true`, `SmoothPlastic`, and size 1 x 1 x 1. Instances made with
  `Instance.new` get none of these.
- **Vide `mount(component, target)`** parents the component's result to `target` and returns a
  destroy function. Destroying it runs the scope's cleanups but leaves the mounted instance
  parented. A children binding (a function returning instances) unparents the instances it stops
  returning.
- **Vide `cleanup(value)`** registers a cleanup on the current scope: it disconnects connections,
  cancels threads, and calls `Destroy` on instances.
</library_facts>

## Task given to both attempts

<task>
I built the block picker on my 1080p monitor and it only really works there. On my phone it sits right where the movement thumbstick is and the tiles are hard to hit, on my 4K monitor everything is tiny, and on an iPad it's somewhere in between.

Make the picker work well on phones, tablets, laptops, and big monitors. Players switch mid-session (rotating a tablet, plugging in a keyboard, resizing the window), so it has to keep up with that. It's the only UI in the game for now, but more screens are coming, so set it up in a way the next ones can use too.
</task>

## Rubric

Score each criterion from 1 to 5 for each attempt (1 poor, 3 acceptable, 5 excellent):

1. Screen facts (viewport size, primary input, and the topbar inset if used) are kept as live reactive state in one shared module that the next screens can reuse, and update when the window resizes, the device rotates, or the input changes. No layout decision comes from a value read once at startup.
2. Large screens: the whole UI grows on screens whose short side is above about 1080 px (for example one UIScale under the ScreenGui bound to the screen size), rather than each component doing its own screen math.
3. Small screens: the UI is not shrunk below its authored size on phones. The layout changes instead (position, arrangement, or a compact variant), so tiles stay about 44 px or larger and text stays readable.
4. The touch layout is chosen from the primary input (`UserInputService.PreferredInput`) and/or the screen size, not from `TouchEnabled` alone, which is also true on touchscreen laptops used with a mouse.
5. On touch layouts the picker stays clear of the thumbstick region (left side, lower two thirds of the screen) and the jump button (lower right), and stays below the topbar.
6. Text keeps up with the scale: the title's `UITextSizeConstraint` cap (real pixels, which a UIScale does not change) is multiplied by the UI scale, or the text moves to a fixed `TextSize`, so the title grows on 4K like everything else.
7. Correct and in scope: still valid Vide (everything that changes is bound, no reactive scope created inside a binding or effect), selection and placement keep working, and luau-lsp, selene, and StyLua pass on the changed files. Extra supporting files, such as a preview story, count neither for nor against.

## Attempt A

<attempt_a_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] The UI reads the screen size
- [pass] The UI follows screen size changes live (a ViewportSize or AbsoluteSize change listener)
- [pass] No file under src builds a ScreenGui with Instance.new (the UI is built with Vide's create)
</attempt_a_checks>

<attempt_a_diff>
diff --git a/src/ServerScriptService/Stories/BlockGame.storybook.luau b/src/ServerScriptService/Stories/BlockGame.storybook.luau
new file mode 100644
index 0000000..b8ac89f
--- /dev/null
+++ b/src/ServerScriptService/Stories/BlockGame.storybook.luau
@@ -0,0 +1,4 @@
+return {
+	name = "Block Game",
+	storyRoots = { script.Parent },
+}
diff --git a/src/ServerScriptService/Stories/BlockPicker.story.luau b/src/ServerScriptService/Stories/BlockPicker.story.luau
new file mode 100644
index 0000000..2c2028b
--- /dev/null
+++ b/src/ServerScriptService/Stories/BlockPicker.story.luau
@@ -0,0 +1,100 @@
+--!strict
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local StarterPlayer = game:GetService("StarterPlayer")
+
+local BlockPicker = require(StarterPlayer.StarterPlayerScripts.BlockPicker)
+local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local create = Vide.create
+local indexes = Vide.indexes
+local source = Vide.source
+
+local MAXIMUM_BLOCK_COUNT = 12
+
+local CONTROLS = {
+	-- The hotbar shown on touch screens and phone-sized windows.
+	IsRow = false,
+	-- Changing it starts the story over. Kept between 1 and 12.
+	BlockCount = #BlockTypes.List,
+	HasLongNames = false,
+}
+
+type StoryProps = {
+	controls: {
+		IsRow: () -> boolean,
+		BlockCount: () -> number,
+		HasLongNames: () -> boolean,
+	},
+	target: Frame,
+}
+
+type Sample = {
+	Count: number,
+	HasLongNames: boolean,
+}
+
+local function sampleBlockTypes(sample: Sample): { BlockTypes.BlockType }
+	local list = {}
+	for index = 1, sample.Count do
+		local base = BlockTypes.List[(index - 1) % #BlockTypes.List + 1]
+		list[index] = table.freeze({
+			Name = `{base.Name}{index}`,
+			DisplayName = if sample.HasLongNames
+				then `Polished {base.DisplayName} Panel`
+				else base.DisplayName,
+			Color = base.Color,
+			Material = base.Material,
+			Transparency = base.Transparency,
+		})
+	end
+	return list
+end
+
+local function story(props: StoryProps)
+	local controls = props.controls
+
+	local function layout(): BlockPicker.Layout
+		return if controls.IsRow() then "Row" else "Column"
+	end
+
+	return create("Frame")({
+		Name = "Preview",
+		Size = UDim2.fromScale(1, 1),
+		BackgroundTransparency = 1,
+
+		create("UIListLayout")({
+			HorizontalAlignment = Enum.HorizontalAlignment.Center,
+			VerticalAlignment = Enum.VerticalAlignment.Center,
+		}),
+
+		indexes(function()
+			local count = math.clamp(math.floor(controls.BlockCount()), 1, MAXIMUM_BLOCK_COUNT)
+			local hasLongNames = controls.HasLongNames()
+			return {
+				[`{count}:{hasLongNames}`] = { Count = count, HasLongNames = hasLongNames },
+			}
+		end, function(sample: () -> Sample)
+			local blockTypes = sampleBlockTypes(sample())
+			local selected = source(blockTypes[1].Name)
+
+			return BlockPicker.component({
+				Layout = layout,
+				BlockTypes = blockTypes,
+				Selected = selected,
+				Select = function(name: string)
+					print(`Selected {name}`)
+					selected(name)
+				end,
+			})
+		end),
+	})
+end
+
+return {
+	summary = "The block picker in its desktop column and touch hotbar layouts.",
+	vide = Vide,
+	controls = CONTROLS,
+	story = story,
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index b45f323..f7696c2 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,6 +1,9 @@
+--!strict
 --[[
-	The block picker: a column of tiles down the left side of the screen, one per block type, each
-	with the block's name beside it, under a title naming the selected block.
+	The block picker: one tile per block type under a title naming the selected
+	block. The Column layout lists the tiles down the screen with each block's
+	name beside it; the Row layout is a hotbar of larger tiles for thumbs.
+	Where the picker sits on screen is up to whoever mounts it.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
@@ -9,15 +12,17 @@ local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local create = Vide.create
+local derive = Vide.derive
+local read = Vide.read
 
-type BlockType = BlockTypes.BlockType
-
-local TILE_SIZE = 40
 local TILE_GAP = 6
 local TILE_RADIUS = 6
+local IDLE_STROKE_THICKNESS = 1
+local SELECTED_STROKE_THICKNESS = 3
 local NAME_WIDTH = 96
+local NAME_TEXT_SIZE = 16
 local TITLE_HEIGHT = 30
-local TITLE_MAX_TEXT_SIZE = 24
+local TITLE_TEXT_SIZE = 24
 local PANEL_PADDING = 10
 local PANEL_RADIUS = 10
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
@@ -25,25 +30,95 @@ local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
 local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
 
+type BlockType = BlockTypes.BlockType
+
+export type Layout = "Column" | "Row"
+
+type Metrics = {
+	TileSize: number,
+	ShowsNames: boolean,
+	FillDirection: Enum.FillDirection,
+	TitleAlignment: Enum.TextXAlignment,
+}
+
+local COLUMN_METRICS: Metrics = table.freeze({
+	TileSize = 40,
+	ShowsNames = true,
+	FillDirection = Enum.FillDirection.Vertical,
+	TitleAlignment = Enum.TextXAlignment.Left,
+})
+-- No names beside the tiles, so the row fits between the thumbstick and the
+-- jump button on a phone.
+local ROW_METRICS: Metrics = table.freeze({
+	TileSize = 52,
+	ShowsNames = false,
+	FillDirection = Enum.FillDirection.Horizontal,
+	TitleAlignment = Enum.TextXAlignment.Center,
+})
+
+local COLUMN_CONTENT_WIDTH = COLUMN_METRICS.TileSize + TILE_GAP + NAME_WIDTH
+
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
+	Metrics: () -> Metrics,
 	IsSelected: () -> boolean,
 	Select: () -> (),
 }
 
+export type BlockPickerProps = {
+	Layout: Layout | () -> Layout,
+	Selected: () -> string,
+	Select: (name: string) -> (),
+	-- Defaults to every block type in the game.
+	BlockTypes: { BlockType }?,
+}
+
+local BlockPicker = {}
+
+local function metricsFor(layout: Layout): Metrics
+	return if layout == "Column" then COLUMN_METRICS else ROW_METRICS
+end
+
+local function contentWidth(layout: Layout, count: number): number
+	if layout == "Column" then
+		return COLUMN_CONTENT_WIDTH
+	end
+	local tileSize = ROW_METRICS.TileSize
+	local rowWidth = count * tileSize + math.max(count - 1, 0) * TILE_GAP
+	-- The title needs room even when only a tile or two shows.
+	return math.max(rowWidth, COLUMN_CONTENT_WIDTH)
+end
+
+local function contentHeight(layout: Layout, count: number): number
+	if layout == "Column" then
+		return TITLE_HEIGHT + count * (TILE_GAP + COLUMN_METRICS.TileSize)
+	end
+	return TITLE_HEIGHT + TILE_GAP + ROW_METRICS.TileSize
+end
+
 local function tile(props: TileProps): TextButton
 	return create("TextButton")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
-		Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TILE_SIZE),
+		Size = function()
+			local metrics = props.Metrics()
+			local width = metrics.TileSize
+			if metrics.ShowsNames then
+				width += TILE_GAP + NAME_WIDTH
+			end
+			return UDim2.fromOffset(width, metrics.TileSize)
+		end,
 		BackgroundTransparency = 1,
 
 		Activated = props.Select,
 
 		create("Frame")({
 			Name = "Swatch",
-			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
+			Size = function()
+				local tileSize = props.Metrics().TileSize
+				return UDim2.fromOffset(tileSize, tileSize)
+			end,
 			BackgroundColor3 = props.BlockType.Color,
 
 			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
@@ -52,36 +127,71 @@ local function tile(props: TileProps): TextButton
 					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
 				end,
 				Thickness = function()
-					return if props.IsSelected() then 3 else 1
+					return if props.IsSelected()
+						then SELECTED_STROKE_THICKNESS
+						else IDLE_STROKE_THICKNESS
 				end,
 			}),
 		}),
 
 		create("TextLabel")({
 			Name = "BlockName",
-			Position = UDim2.fromOffset(TILE_SIZE + TILE_GAP, 0),
-			Size = UDim2.fromOffset(NAME_WIDTH, TILE_SIZE),
+			Visible = function()
+				return props.Metrics().ShowsNames
+			end,
+			Position = function()
+				return UDim2.fromOffset(props.Metrics().TileSize + TILE_GAP, 0)
+			end,
+			Size = function()
+				return UDim2.fromOffset(NAME_WIDTH, props.Metrics().TileSize)
+			end,
 			BackgroundTransparency = 1,
 			Font = Enum.Font.Gotham,
-			TextSize = 16,
+			TextSize = NAME_TEXT_SIZE,
 			TextColor3 = TEXT_COLOR,
 			TextXAlignment = Enum.TextXAlignment.Left,
+			TextTruncate = Enum.TextTruncate.AtEnd,
 			Text = props.BlockType.DisplayName,
 		}),
 	})
 end
 
-export type BlockPickerProps = {
-	Selected: () -> string,
-	Select: (name: string) -> (),
-}
+--[[
+	The picker's size in UI units for the given layout and number of block
+	types, before any scale. Use it to place or fit the picker without reading
+	its AbsoluteSize.
+]]
+function BlockPicker.designSize(layout: Layout, count: number): Vector2
+	return Vector2.new(
+		contentWidth(layout, count) + PANEL_PADDING * 2,
+		contentHeight(layout, count) + PANEL_PADDING * 2
+	)
+end
+
+function BlockPicker.component(props: BlockPickerProps): Frame
+	local blockTypes = props.BlockTypes or BlockTypes.List
+	local count = #blockTypes
+
+	local byName: { [string]: BlockType? } = {}
+	for _, blockType in blockTypes do
+		byName[blockType.Name] = blockType
+	end
+
+	-- Derived, so bindings rerun when the layout flips, not on every pixel of
+	-- a window resize.
+	local layout = derive(function(): Layout
+		return read(props.Layout)
+	end) :: () -> Layout
+	local metrics = derive(function(): Metrics
+		return metricsFor(layout())
+	end)
 
-local function blockPicker(props: BlockPickerProps): Frame
 	local tiles = {}
-	for index, blockType in BlockTypes.List do
+	for index, blockType in blockTypes do
 		tiles[index] = tile({
 			BlockType = blockType,
-			LayoutOrder = index + 1,
+			LayoutOrder = index,
+			Metrics = metrics,
 			IsSelected = function()
 				return props.Selected() == blockType.Name
 			end,
@@ -93,9 +203,10 @@ local function blockPicker(props: BlockPickerProps): Frame
 
 	return create("Frame")({
 		Name = "BlockPicker",
-		AnchorPoint = Vector2.new(0, 0.5),
-		Position = UDim2.new(0, 20, 0.5, 0),
-		AutomaticSize = Enum.AutomaticSize.XY,
+		Size = function()
+			local size = BlockPicker.designSize(layout(), count)
+			return UDim2.fromOffset(size.X, size.Y)
+		end,
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
 
@@ -108,27 +219,46 @@ local function blockPicker(props: BlockPickerProps): Frame
 		}),
 		create("UIListLayout")({
 			FillDirection = Enum.FillDirection.Vertical,
+			HorizontalAlignment = Enum.HorizontalAlignment.Center,
 			Padding = UDim.new(0, TILE_GAP),
 		}),
 
 		create("TextLabel")({
 			Name = "Title",
 			LayoutOrder = 1,
-			Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TITLE_HEIGHT),
+			Size = function()
+				return UDim2.fromOffset(contentWidth(layout(), count), TITLE_HEIGHT)
+			end,
 			BackgroundTransparency = 1,
 			Font = Enum.Font.GothamBold,
-			TextScaled = true,
+			TextSize = TITLE_TEXT_SIZE,
 			TextColor3 = TEXT_COLOR,
-			TextXAlignment = Enum.TextXAlignment.Left,
+			TextXAlignment = function()
+				return metrics().TitleAlignment
+			end,
+			TextTruncate = Enum.TextTruncate.AtEnd,
 			Text = function()
-				return BlockTypes.ByName[props.Selected()].DisplayName
+				local blockType = byName[props.Selected()]
+				return if blockType then blockType.DisplayName else ""
 			end,
-
-			create("UITextSizeConstraint")({ MaxTextSize = TITLE_MAX_TEXT_SIZE }),
 		}),
 
-		tiles,
+		create("Frame")({
+			Name = "Tiles",
+			LayoutOrder = 2,
+			AutomaticSize = Enum.AutomaticSize.XY,
+			BackgroundTransparency = 1,
+
+			create("UIListLayout")({
+				FillDirection = function()
+					return metrics().FillDirection
+				end,
+				Padding = UDim.new(0, TILE_GAP),
+			}),
+
+			tiles,
+		}),
 	})
 end
 
-return blockPicker
+return BlockPicker
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 04bc27a..2d84e61 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -3,12 +3,24 @@ local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
 local BlockPicker = require(script.Parent.BlockPicker)
 local BlockPlacer = require(script.Parent.BlockPlacer)
+local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Screen = require(script.Parent.UI.Screen)
 local Vide = require(ReplicatedStorage.Packages.Vide)
+local scaledScreenGui = require(script.Parent.UI.scaledScreenGui)
 
 local create = Vide.create
+local derive = Vide.derive
 local mount = Vide.mount
 local source = Vide.source
 
+local COLUMN_ANCHOR = Vector2.new(0, 0.5)
+local COLUMN_POSITION = UDim2.new(0, 20, 0.5, 0)
+local ROW_ANCHOR = Vector2.new(0.5, 1)
+local EDGE_PADDING = 16
+-- Keeps the Row layout's 52 pixel tiles at 44 or more, the smallest a thumb
+-- hits reliably.
+local MINIMUM_FIT_SCALE = 0.85
+
 local localPlayer = Players.LocalPlayer
 local playerGui = localPlayer:WaitForChild("PlayerGui")
 
@@ -17,17 +29,65 @@ BlockPlacer.BlockTypeChanged:Connect(function(name: string)
 	selected(name)
 end)
 
-local function app()
-	return create("ScreenGui")({
-		Name = "BlockPickerGui",
+local function blockPickerDock()
+	local layout: () -> BlockPicker.Layout = derive(function(): BlockPicker.Layout
+		return if Screen.isTouchLayout() then "Row" else "Column"
+	end)
+
+	local function designSize(): Vector2
+		return BlockPicker.designSize(layout(), #BlockTypes.List)
+	end
 
-		BlockPicker({
+	local function room(): Vector2
+		local usable = Screen.usableSize()
+		local height = usable.Y - EDGE_PADDING * 2
+		if layout() == "Row" then
+			local span = Screen.bottomTouchSpan()
+			return Vector2.new(span.Right - span.Left - EDGE_PADDING * 2, height)
+		end
+		return Vector2.new(usable.X - EDGE_PADDING * 2, height)
+	end
+
+	return create("Frame")({
+		Name = "BlockPickerDock",
+		BackgroundTransparency = 1,
+		AnchorPoint = function()
+			return if layout() == "Row" then ROW_ANCHOR else COLUMN_ANCHOR
+		end,
+		Position = function()
+			if layout() == "Column" then
+				return COLUMN_POSITION
+			end
+			-- Centered in the gap between the thumbstick and the jump button.
+			local span = Screen.bottomTouchSpan()
+			return UDim2.new(0, math.round((span.Left + span.Right) / 2), 1, -EDGE_PADDING)
+		end,
+		Size = function()
+			local size = designSize()
+			return UDim2.fromOffset(size.X, size.Y)
+		end,
+
+		create("UIScale")({
+			Scale = function()
+				return Screen.fitScale(designSize(), room(), MINIMUM_FIT_SCALE)
+			end,
+		}),
+
+		BlockPicker.component({
+			Layout = layout,
 			Selected = selected,
 			Select = BlockPlacer.setBlockType,
 		}),
 	})
 end
 
+local function app()
+	return scaledScreenGui({
+		Name = "BlockPickerGui",
+		Children = { blockPickerDock() },
+	})
+end
+
 mount(app, playerGui)
 
 BlockPlacer.start()
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
new file mode 100644
index 0000000..e77c1e1
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
@@ -0,0 +1,167 @@
+--!strict
+--[[
+	Live facts about the player's screen, as Vide sources, shared by every
+	screen of UI. Sizes are in UI units: the offsets UI is authored in, for a
+	screen 1080 pixels tall. Build ScreenGuis with scaledScreenGui so those
+	units grow on larger screens.
+]]
+
+local GuiService = game:GetService("GuiService")
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local RunService = game:GetService("RunService")
+local UserInputService = game:GetService("UserInputService")
+
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local batch = Vide.batch
+local source = Vide.source
+
+local REFERENCE_SHORT_SIDE = 1080
+local MINIMUM_SCALE = 1
+local MAXIMUM_SCALE = 3
+local LARGE_DISPLAY_BOOST = 1.25
+local PHONE_SHORT_SIDE = 600
+local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)
+
+-- Where the default PlayerModule puts its touch controls, in real pixels: the
+-- dynamic thumbstick can start anywhere in the left 40 percent, and the jump
+-- button's left edge sits this far from the right edge.
+local THUMBSTICK_WIDTH_SHARE = 0.4
+local SMALL_TOUCH_SHORT_SIDE = 500
+local SMALL_JUMP_LEFT_FROM_RIGHT = 95
+local LARGE_JUMP_LEFT_FROM_RIGHT = 170
+
+export type Span = {
+	Left: number,
+	Right: number,
+}
+
+local Screen = {}
+
+local realViewport = source(FALLBACK_VIEWPORT)
+local realInset = source(Vector2.zero)
+local prefersTouch = source(false)
+local isLargeDisplay = source(false)
+local viewportConnection: RBXScriptConnection? = nil
+
+local function refresh()
+	local camera = workspace.CurrentCamera
+	local topLeftInset = GuiService:GetGuiInset()
+	batch(function()
+		-- ViewportSize reads (1, 1) before the first frame, which would pass
+		-- for a tiny phone.
+		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
+			realViewport(camera.ViewportSize)
+		end
+		realInset(topLeftInset)
+		prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
+		isLargeDisplay(GuiService.ViewportDisplaySize == Enum.DisplaySize.Large)
+	end)
+end
+
+local function watchCamera()
+	if viewportConnection then
+		viewportConnection:Disconnect()
+	end
+	local camera = workspace.CurrentCamera
+	if camera then
+		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
+	end
+	refresh()
+end
+
+--[[
+	How much the whole UI grows: the short side over 1080, kept between 1 and
+	3, with a quarter more on a TV. Smaller screens change layout instead.
+]]
+function Screen.uiScale(): number
+	local view = realViewport()
+	local boost = if isLargeDisplay() then LARGE_DISPLAY_BOOST else 1
+	return math.clamp(
+		math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE * boost,
+		MINIMUM_SCALE,
+		MAXIMUM_SCALE
+	)
+end
+
+function Screen.viewport(): Vector2
+	return realViewport() / Screen.uiScale()
+end
+
+--[[
+	The viewport below the Roblox topbar.
+]]
+function Screen.usableSize(): Vector2
+	local view = Screen.viewport()
+	return Vector2.new(view.X, view.Y - realInset().Y / Screen.uiScale())
+end
+
+--[[
+	Whether touch is the primary input, which is when Roblox shows its
+	thumbstick and jump button.
+]]
+function Screen.isTouch(): boolean
+	return prefersTouch()
+end
+
+--[[
+	A short side under 600 UI units, which includes a desktop window dragged
+	that small.
+]]
+function Screen.isPhone(): boolean
+	local view = Screen.viewport()
+	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
+end
+
+--[[
+	Whether UI should use its touch layout: the touch controls are up, or the
+	screen is too small for the desktop layout.
+]]
+function Screen.isTouchLayout(): boolean
+	return prefersTouch() or Screen.isPhone()
+end
+
+--[[
+	The stretch along the bottom edge that the touch controls leave free,
+	measured from the left edge. Without touch controls it is the whole width.
+]]
+function Screen.bottomTouchSpan(): Span
+	local view = realViewport()
+	local scale = Screen.uiScale()
+	if not prefersTouch() then
+		return { Left = 0, Right = view.X / scale }
+	end
+
+	local isSmallTouchArea = math.min(view.X, view.Y) <= SMALL_TOUCH_SHORT_SIDE
+	local jumpLeftFromRight = if isSmallTouchArea
+		then SMALL_JUMP_LEFT_FROM_RIGHT
+		else LARGE_JUMP_LEFT_FROM_RIGHT
+	return {
+		Left = view.X * THUMBSTICK_WIDTH_SHARE / scale,
+		Right = (view.X - jumpLeftFromRight) / scale,
+	}
+end
+
+--[[
+	The scale that fits a panel's design size into the room it has. Never
+	above 1, and never below minimumScale, past which its text or buttons get
+	too small to use.
+]]
+function Screen.fitScale(designSize: Vector2, room: Vector2, minimumScale: number): number
+	local fit = math.min(room.X / designSize.X, room.Y / designSize.Y)
+	return math.clamp(fit, minimumScale, 1)
+end
+
+-- UI Labs loads a fresh copy of this module on every reload, and an engine
+-- connection would keep each copy in memory, so edit mode reads once.
+if RunService:IsRunning() then
+	watchCamera()
+	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
+	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(refresh)
+	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
+	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
+else
+	refresh()
+end
+
+return Screen
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/scaledScreenGui.luau b/src/StarterPlayer/StarterPlayerScripts/UI/scaledScreenGui.luau
new file mode 100644
index 0000000..01ad666
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/scaledScreenGui.luau
@@ -0,0 +1,30 @@
+--!strict
+--[[
+	A ScreenGui that grows the UI inside it on screens larger than 1080p. Build
+	every screen of game UI with it, so no component does its own screen math.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+
+local Screen = require(script.Parent.Screen)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local create = Vide.create
+
+export type ScaledScreenGuiProps = {
+	Name: string,
+	DisplayOrder: number?,
+	Children: { any },
+}
+
+local function scaledScreenGui(props: ScaledScreenGuiProps): ScreenGui
+	return create("ScreenGui")({
+		Name = props.Name,
+		DisplayOrder = props.DisplayOrder,
+
+		create("UIScale")({ Scale = Screen.uiScale }),
+		props.Children,
+	})
+end
+
+return scaledScreenGui

</attempt_a_diff>

## Attempt B

<attempt_b_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] The UI reads the screen size
- [pass] The UI follows screen size changes live (a ViewportSize or AbsoluteSize change listener)
- [pass] No file under src builds a ScreenGui with Instance.new (the UI is built with Vide's create)
</attempt_b_checks>

<attempt_b_diff>
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index b45f323..9a616e9 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,33 +1,55 @@
 --[[
-	The block picker: a column of tiles down the left side of the screen, one per block type, each
-	with the block's name beside it, under a title naming the selected block.
+	The block picker: one tile per block type plus a title naming the selected block. Sizes are in
+	design units (see UI/Responsive); put it inside a UI/Screen so it's scaled for the device.
+
+	It switches layout live as the device changes:
+	- "Column", for keyboard and mouse or gamepad with room to spare: a column down the left side,
+	  each tile with the block's name beside it and, with a keyboard, its number key.
+	- "Bar", for touch or a compact screen: a row of tiles along the top centre, with the title
+	  underneath. That keeps it clear of the thumbstick (bottom left) and jump button (bottom
+	  right), and makes the tiles finger-sized.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Responsive = require(script.Parent.UI.Responsive)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local create = Vide.create
+local derive = Vide.derive
 
 type BlockType = BlockTypes.BlockType
+type Layout = "Column" | "Bar"
 
 local TILE_SIZE = 40
 local TILE_GAP = 6
 local TILE_RADIUS = 6
 local NAME_WIDTH = 96
-local TITLE_HEIGHT = 30
+local NAME_TEXT_SIZE = 16
+local HINT_SIZE = 16
+local HINT_TEXT_SIZE = 12
+local COLUMN_TITLE_HEIGHT = 30
+local BAR_TITLE_HEIGHT = 22
 local TITLE_MAX_TEXT_SIZE = 24
 local PANEL_PADDING = 10
 local PANEL_RADIUS = 10
+local SCREEN_MARGIN = 20
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
 local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
+local HINT_COLOR = Color3.fromRGB(0, 0, 0)
+
+local COLUMN_WIDTH = TILE_SIZE + TILE_GAP + NAME_WIDTH
+local BAR_WIDTH = #BlockTypes.List * TILE_SIZE + (#BlockTypes.List - 1) * TILE_GAP
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
+	Hotkey: string?,
+	Layout: () -> Layout,
+	ShowHotkey: () -> boolean,
 	IsSelected: () -> boolean,
 	Select: () -> (),
 }
@@ -36,8 +58,12 @@ local function tile(props: TileProps): TextButton
 	return create("TextButton")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
-		Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TILE_SIZE),
+		Size = function()
+			local width = if props.Layout() == "Column" then COLUMN_WIDTH else TILE_SIZE
+			return UDim2.fromOffset(width, TILE_SIZE)
+		end,
 		BackgroundTransparency = 1,
+		Text = "",
 
 		Activated = props.Select,
 
@@ -55,17 +81,38 @@ local function tile(props: TileProps): TextButton
 					return if props.IsSelected() then 3 else 1
 				end,
 			}),
+
+			create("TextLabel")({
+				Name = "Hotkey",
+				Visible = function()
+					return props.Hotkey ~= nil and props.ShowHotkey()
+				end,
+				Position = UDim2.fromOffset(2, 2),
+				Size = UDim2.fromOffset(HINT_SIZE, HINT_SIZE),
+				BackgroundColor3 = HINT_COLOR,
+				BackgroundTransparency = 0.45,
+				Font = Enum.Font.GothamBold,
+				TextSize = HINT_TEXT_SIZE,
+				TextColor3 = TEXT_COLOR,
+				Text = props.Hotkey or "",
+
+				create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
+			}),
 		}),
 
 		create("TextLabel")({
 			Name = "BlockName",
+			Visible = function()
+				return props.Layout() == "Column"
+			end,
 			Position = UDim2.fromOffset(TILE_SIZE + TILE_GAP, 0),
 			Size = UDim2.fromOffset(NAME_WIDTH, TILE_SIZE),
 			BackgroundTransparency = 1,
 			Font = Enum.Font.Gotham,
-			TextSize = 16,
+			TextSize = NAME_TEXT_SIZE,
 			TextColor3 = TEXT_COLOR,
 			TextXAlignment = Enum.TextXAlignment.Left,
+			TextTruncate = Enum.TextTruncate.AtEnd,
 			Text = props.BlockType.DisplayName,
 		}),
 	})
@@ -74,14 +121,32 @@ end
 export type BlockPickerProps = {
 	Selected: () -> string,
 	Select: (name: string) -> (),
+	-- Key labels by block index, shown on the tiles while the player uses a keyboard.
+	Hotkeys: { string }?,
 }
 
 local function blockPicker(props: BlockPickerProps): Frame
+	local layout = derive(function(): Layout
+		if Responsive.inputKind() == "Touch" or Responsive.sizeClass() == "Compact" then
+			return "Bar"
+		end
+		return "Column"
+	end)
+	local isColumn = derive(function()
+		return layout() == "Column"
+	end)
+	local showHotkeys = derive(function()
+		return Responsive.inputKind() == "KeyboardMouse"
+	end)
+
 	local tiles = {}
 	for index, blockType in BlockTypes.List do
 		tiles[index] = tile({
 			BlockType = blockType,
-			LayoutOrder = index + 1,
+			LayoutOrder = index,
+			Hotkey = if props.Hotkeys then props.Hotkeys[index] else nil,
+			Layout = layout,
+			ShowHotkey = showHotkeys,
 			IsSelected = function()
 				return props.Selected() == blockType.Name
 			end,
@@ -93,8 +158,14 @@ local function blockPicker(props: BlockPickerProps): Frame
 
 	return create("Frame")({
 		Name = "BlockPicker",
-		AnchorPoint = Vector2.new(0, 0.5),
-		Position = UDim2.new(0, 20, 0.5, 0),
+		AnchorPoint = function()
+			return if isColumn() then Vector2.new(0, 0.5) else Vector2.new(0.5, 0)
+		end,
+		Position = function()
+			return if isColumn()
+				then UDim2.new(0, SCREEN_MARGIN, 0.5, 0)
+				else UDim2.new(0.5, 0, 0, SCREEN_MARGIN)
+		end,
 		AutomaticSize = Enum.AutomaticSize.XY,
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
@@ -108,18 +179,28 @@ local function blockPicker(props: BlockPickerProps): Frame
 		}),
 		create("UIListLayout")({
 			FillDirection = Enum.FillDirection.Vertical,
+			SortOrder = Enum.SortOrder.LayoutOrder,
 			Padding = UDim.new(0, TILE_GAP),
 		}),
 
 		create("TextLabel")({
 			Name = "Title",
-			LayoutOrder = 1,
-			Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TITLE_HEIGHT),
+			-- Above the tiles in a column, below them in a bar.
+			LayoutOrder = function()
+				return if isColumn() then 1 else 3
+			end,
+			Size = function()
+				return if isColumn()
+					then UDim2.fromOffset(COLUMN_WIDTH, COLUMN_TITLE_HEIGHT)
+					else UDim2.fromOffset(BAR_WIDTH, BAR_TITLE_HEIGHT)
+			end,
 			BackgroundTransparency = 1,
 			Font = Enum.Font.GothamBold,
 			TextScaled = true,
 			TextColor3 = TEXT_COLOR,
-			TextXAlignment = Enum.TextXAlignment.Left,
+			TextXAlignment = function()
+				return if isColumn() then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
+			end,
 			Text = function()
 				return BlockTypes.ByName[props.Selected()].DisplayName
 			end,
@@ -127,7 +208,24 @@ local function blockPicker(props: BlockPickerProps): Frame
 			create("UITextSizeConstraint")({ MaxTextSize = TITLE_MAX_TEXT_SIZE }),
 		}),
 
-		tiles,
+		create("Frame")({
+			Name = "Tiles",
+			LayoutOrder = 2,
+			AutomaticSize = Enum.AutomaticSize.XY,
+			BackgroundTransparency = 1,
+
+			create("UIListLayout")({
+				FillDirection = function()
+					return if isColumn()
+						then Enum.FillDirection.Vertical
+						else Enum.FillDirection.Horizontal
+				end,
+				SortOrder = Enum.SortOrder.LayoutOrder,
+				Padding = UDim.new(0, TILE_GAP),
+			}),
+
+			tiles,
+		}),
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau
index e8d33eb..54a2a0c 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau
@@ -32,6 +32,15 @@ local blockTypeChanged = Instance.new("BindableEvent")
 ]]
 BlockPlacer.BlockTypeChanged = blockTypeChanged.Event
 
+--[[
+	The key that selects each block type, by index into BlockTypes.List, as shown to players.
+]]
+local hotkeyLabels = {}
+for index in NUMBER_KEYS do
+	hotkeyLabels[index] = tostring(index)
+end
+BlockPlacer.HotkeyLabels = table.freeze(hotkeyLabels) :: { string }
+
 function BlockPlacer.getBlockType(): string
 	return selectedName
 end
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 04bc27a..8b61283 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -3,9 +3,9 @@ local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
 local BlockPicker = require(script.Parent.BlockPicker)
 local BlockPlacer = require(script.Parent.BlockPlacer)
+local Screen = require(script.Parent.UI.Screen)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
-local create = Vide.create
 local mount = Vide.mount
 local source = Vide.source
 
@@ -18,13 +18,15 @@ BlockPlacer.BlockTypeChanged:Connect(function(name: string)
 end)
 
 local function app()
-	return create("ScreenGui")({
+	return Screen({
 		Name = "BlockPickerGui",
-
-		BlockPicker({
-			Selected = selected,
-			Select = BlockPlacer.setBlockType,
-		}),
+		Children = {
+			BlockPicker({
+				Selected = selected,
+				Select = BlockPlacer.setBlockType,
+				Hotkeys = BlockPlacer.HotkeyLabels,
+			}),
+		},
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau
new file mode 100644
index 0000000..fc53e91
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau
@@ -0,0 +1,139 @@
+--[[
+	Live facts about the player's screen and input device, as Vide sources, for every UI screen to
+	build on. Each one updates when the player resizes the window, rotates a device, or switches
+	between touch, keyboard and mouse, and gamepad, and only notifies when its value actually
+	changes.
+
+	UI is designed in "design units": the size things should be on a 1080p monitor with a mouse.
+	`scale()` turns design units into screen pixels for the current device, and `Screen` applies it
+	with a UIScale, so components write fixed design-unit sizes and never read `scale()`
+	themselves.
+
+	- `inputKind()`: "KeyboardMouse", "Touch" or "Gamepad", following the same signal Roblox's
+	  own controls use (for example, the touch thumbstick hides when a keyboard is used).
+	- `scale()`: screen pixels per design unit.
+	- `canvasSize()`: the screen's size in design units, which is the space components lay out in.
+	- `sizeClass()`: "Compact" (phones, tiny windows), "Medium" (tablets, small laptop windows) or
+	  "Large" (laptops and monitors), from `canvasSize()`.
+	- `viewportSize()`: the raw viewport size in screen pixels.
+]]
+
+local UserInputService = game:GetService("UserInputService")
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local Workspace = game:GetService("Workspace")
+
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local source = Vide.source
+
+export type InputKind = "KeyboardMouse" | "Touch" | "Gamepad"
+export type SizeClass = "Compact" | "Medium" | "Large"
+
+-- Pointer devices scale with the screen's short side, relative to a 1080p screen. Desktop clients
+-- report the viewport in physical pixels, so a 4K monitor gets 2x and a 768p laptop gets the
+-- minimum.
+local POINTER_REFERENCE = 1080
+local POINTER_MIN_SCALE = 0.8
+local POINTER_MAX_SCALE = 3
+
+-- Touch clients report the viewport in points (a phone is around 390 tall). The minimum keeps a
+-- 40-unit tile at 48 points, a comfortable finger target; tablets grow up to the maximum.
+local TOUCH_REFERENCE = 600
+local TOUCH_MIN_SCALE = 1.2
+local TOUCH_MAX_SCALE = 1.6
+
+-- Gamepad players usually sit further from the screen.
+local GAMEPAD_BOOST = 1.25
+
+-- Canvas thresholds, in design units, for the size classes.
+local COMPACT_MAX_HEIGHT = 480
+local COMPACT_MAX_WIDTH = 600
+local MEDIUM_MAX_HEIGHT = 800
+
+local function readInputKind(): InputKind
+	local preferred = UserInputService.PreferredInput
+	if preferred == Enum.PreferredInput.Touch then
+		return "Touch"
+	elseif
+		preferred == Enum.PreferredInput.Gamepad
+		or preferred == Enum.PreferredInput.MicroGamepad
+	then
+		return "Gamepad"
+	end
+	return "KeyboardMouse"
+end
+
+local function computeScale(viewport: Vector2, kind: InputKind): number
+	local shortSide = math.max(math.min(viewport.X, viewport.Y), 1)
+	if kind == "Touch" then
+		return math.clamp(shortSide / TOUCH_REFERENCE, TOUCH_MIN_SCALE, TOUCH_MAX_SCALE)
+	end
+	local scale = math.clamp(shortSide / POINTER_REFERENCE, POINTER_MIN_SCALE, POINTER_MAX_SCALE)
+	if kind == "Gamepad" then
+		scale *= GAMEPAD_BOOST
+	end
+	return scale
+end
+
+local function computeSizeClass(canvas: Vector2): SizeClass
+	if canvas.Y < COMPACT_MAX_HEIGHT or canvas.X < COMPACT_MAX_WIDTH then
+		return "Compact"
+	elseif canvas.Y < MEDIUM_MAX_HEIGHT then
+		return "Medium"
+	end
+	return "Large"
+end
+
+local viewportSize = source(Vector2.new(1920, 1080))
+local inputKind = source(readInputKind())
+local scale = source(1)
+local canvasSize = source(Vector2.new(1920, 1080))
+local sizeClass = source("Large" :: SizeClass)
+
+local function recompute()
+	local viewport = viewportSize()
+	local newScale = computeScale(viewport, inputKind())
+	local canvas = viewport / newScale
+	scale(newScale)
+	canvasSize(canvas)
+	sizeClass(computeSizeClass(canvas))
+end
+
+local cameraConnection: RBXScriptConnection? = nil
+
+local function watchCamera()
+	if cameraConnection then
+		cameraConnection:Disconnect()
+		cameraConnection = nil
+	end
+
+	local camera = Workspace.CurrentCamera
+	if not camera then
+		return
+	end
+
+	local function update()
+		viewportSize(camera.ViewportSize)
+		recompute()
+	end
+	cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
+	update()
+end
+
+Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
+UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
+	inputKind(readInputKind())
+	recompute()
+end)
+watchCamera()
+recompute()
+
+local Responsive = {
+	viewportSize = viewportSize :: () -> Vector2,
+	inputKind = inputKind :: () -> InputKind,
+	scale = scale :: () -> number,
+	canvasSize = canvasSize :: () -> Vector2,
+	sizeClass = sizeClass :: () -> SizeClass,
+}
+
+return table.freeze(Responsive)
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
new file mode 100644
index 0000000..3973e28
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
@@ -0,0 +1,50 @@
+--[[
+	A ScreenGui for one UI screen, set up so its contents are laid out in design units (see
+	Responsive) and scaled to suit the current device.
+
+	Children go inside a full-screen "Root" frame carrying a UIScale. Root is sized at 1 / scale
+	of the screen so that, once scaled, it exactly covers the safe area: scale-based positions
+	(like `UDim2.fromScale(0.5, 0)`) still mean "middle of the screen", and offsets are design
+	units. Root doesn't take input, so taps and clicks on empty space still reach the world.
+
+	The ScreenGui stays inside the safe area (clear of the topbar and any notch) and survives the
+	character respawning, since screens are mounted once from PlayerScripts.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+
+local Responsive = require(script.Parent.Responsive)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local create = Vide.create
+
+export type ScreenProps = {
+	Name: string,
+	DisplayOrder: number?,
+	Children: { any },
+}
+
+local function screen(props: ScreenProps): ScreenGui
+	return create("ScreenGui")({
+		Name = props.Name,
+		DisplayOrder = props.DisplayOrder or 0,
+		ResetOnSpawn = false,
+		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
+		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
+
+		create("Frame")({
+			Name = "Root",
+			BackgroundTransparency = 1,
+			Size = function()
+				local scale = Responsive.scale()
+				return UDim2.fromScale(1 / scale, 1 / scale)
+			end,
+
+			create("UIScale")({ Scale = Responsive.scale }),
+
+			props.Children,
+		}),
+	})
+end
+
+return screen

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
