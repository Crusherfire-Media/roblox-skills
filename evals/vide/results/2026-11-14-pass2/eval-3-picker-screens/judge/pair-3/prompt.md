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
diff --git a/src/ServerScriptService/Stories/BlockPicker.story.luau b/src/ServerScriptService/Stories/BlockPicker.story.luau
new file mode 100644
index 0000000..dafcac2
--- /dev/null
+++ b/src/ServerScriptService/Stories/BlockPicker.story.luau
@@ -0,0 +1,52 @@
+--!strict
+
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+local BlockPicker = require("@game/StarterPlayer/StarterPlayerScripts/BlockPicker")
+local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+
+local source = Vide.source
+
+local CENTER = Vector2.new(0.5, 0.5)
+local SCREEN_CENTER = UDim2.fromScale(0.5, 0.5)
+
+-- Plain controls, so the story needs no UI Labs utility package.
+local CONTROLS = {
+	-- Off is the desktop column, on is the touch row.
+	IsRowLayout = false,
+	ShowKeyHints = true,
+}
+
+type StoryProps = {
+	controls: {
+		IsRowLayout: () -> boolean,
+		ShowKeyHints: () -> boolean,
+	},
+	target: Frame,
+}
+
+local function story(props: StoryProps)
+	local controls = props.controls
+	local selected = source(BlockTypes.List[1].Name)
+
+	return BlockPicker({
+		Selected = selected,
+		Select = function(name: string)
+			print(`Selected {name}`)
+			selected(name)
+		end,
+		Layout = function(): BlockPicker.Layout
+			return if controls.IsRowLayout() then "Row" else "Column"
+		end,
+		ShowKeyHints = controls.ShowKeyHints,
+		AnchorPoint = CENTER,
+		Position = SCREEN_CENTER,
+	})
+end
+
+return {
+	summary = "The block picker in its desktop column and touch row layouts.",
+	vide = Vide,
+	controls = CONTROLS,
+	story = story,
+}
diff --git a/src/ServerScriptService/Stories/GameUI.storybook.luau b/src/ServerScriptService/Stories/GameUI.storybook.luau
new file mode 100644
index 0000000..af65549
--- /dev/null
+++ b/src/ServerScriptService/Stories/GameUI.storybook.luau
@@ -0,0 +1,6 @@
+--!strict
+
+return {
+	name = "Game UI",
+	storyRoots = { game:GetService("ServerScriptService").Stories },
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index b45f323..c48a91d 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,49 +1,133 @@
+--!strict
 --[[
-	The block picker: a column of tiles down the left side of the screen, one per block type, each
-	with the block's name beside it, under a title naming the selected block.
+	The block picker, one tile per block type, in two layouts:
+
+	- Column: tiles down the screen with each block's name beside it, under a
+	  title naming the selected block. For mouse and keyboard.
+	- Row: larger tiles side by side with each name underneath, sized for a
+	  thumb. For touch screens and small windows.
+
+	The screen that mounts the picker chooses the layout and where it sits.
 ]]
 
-local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
 
-local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
-local Vide = require(ReplicatedStorage.Packages.Vide)
+local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
 
 local create = Vide.create
+local derive = Vide.derive
+local read = Vide.read
 
-type BlockType = BlockTypes.BlockType
-
-local TILE_SIZE = 40
 local TILE_GAP = 6
 local TILE_RADIUS = 6
-local NAME_WIDTH = 96
 local TITLE_HEIGHT = 30
-local TITLE_MAX_TEXT_SIZE = 24
+local TITLE_TEXT_SIZE = 24
 local PANEL_PADDING = 10
 local PANEL_RADIUS = 10
+local KEY_HINT_SIZE = 16
+local KEY_HINT_TEXT_SIZE = 12
+-- Keep in sync with NUMBER_KEYS in BlockPlacer.
+local KEY_HINT_COUNT = 5
+local SELECTED_STROKE = 3
+local IDLE_STROKE = 1
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
 local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
+local KEY_HINT_COLOR = Color3.fromRGB(20, 20, 24)
+
+type BlockType = BlockTypes.BlockType
+
+export type Layout = "Column" | "Row"
+
+type Metrics = {
+	TileSize: Vector2,
+	SwatchSize: number,
+	SwatchPosition: Vector2,
+	NamePosition: Vector2,
+	NameSize: Vector2,
+	NameTextSize: number,
+	NameAlignment: Enum.TextXAlignment,
+	FillDirection: Enum.FillDirection,
+	HasTitle: boolean,
+}
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
+	KeyHint: string?,
+	Metrics: () -> Metrics,
+	ShowKeyHint: () -> boolean,
 	IsSelected: () -> boolean,
 	Select: () -> (),
 }
 
+export type BlockPickerProps = {
+	Selected: () -> string,
+	Select: (name: string) -> (),
+	Layout: Layout | () -> Layout,
+	ShowKeyHints: (boolean | () -> boolean)?,
+	AnchorPoint: (Vector2 | () -> Vector2)?,
+	Position: (UDim2 | () -> UDim2)?,
+}
+
+local COLUMN: Metrics = table.freeze({
+	TileSize = Vector2.new(44 + TILE_GAP + 96, 44),
+	SwatchSize = 44,
+	SwatchPosition = Vector2.zero,
+	NamePosition = Vector2.new(44 + TILE_GAP, 0),
+	NameSize = Vector2.new(96, 44),
+	NameTextSize = 18,
+	NameAlignment = Enum.TextXAlignment.Left,
+	FillDirection = Enum.FillDirection.Vertical,
+	HasTitle = true,
+})
+
+-- The tile is wider than its swatch so the name fits under it, and the whole
+-- tile takes the press.
+local ROW: Metrics = table.freeze({
+	TileSize = Vector2.new(64, 52 + 4 + 18),
+	SwatchSize = 52,
+	SwatchPosition = Vector2.new(6, 0),
+	NamePosition = Vector2.new(0, 52 + 4),
+	NameSize = Vector2.new(64, 18),
+	NameTextSize = 16,
+	NameAlignment = Enum.TextXAlignment.Center,
+	FillDirection = Enum.FillDirection.Horizontal,
+	HasTitle = false,
+})
+
+local METRICS: { [Layout]: Metrics } = table.freeze({
+	Column = COLUMN,
+	Row = ROW,
+})
+
+local function toOffset(size: Vector2): UDim2
+	return UDim2.fromOffset(size.X, size.Y)
+end
+
 local function tile(props: TileProps): TextButton
+	local metrics = props.Metrics
+
 	return create("TextButton")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
-		Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TILE_SIZE),
+		Size = function()
+			return toOffset(metrics().TileSize)
+		end,
 		BackgroundTransparency = 1,
 
 		Activated = props.Select,
 
 		create("Frame")({
 			Name = "Swatch",
-			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
+			Position = function()
+				return toOffset(metrics().SwatchPosition)
+			end,
+			Size = function()
+				local size = metrics().SwatchSize
+				return UDim2.fromOffset(size, size)
+			end,
 			BackgroundColor3 = props.BlockType.Color,
 
 			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
@@ -52,36 +136,68 @@ local function tile(props: TileProps): TextButton
 					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
 				end,
 				Thickness = function()
-					return if props.IsSelected() then 3 else 1
+					return if props.IsSelected() then SELECTED_STROKE else IDLE_STROKE
 				end,
 			}),
+
+			props.KeyHint and create("TextLabel")({
+				Name = "KeyHint",
+				Position = UDim2.fromOffset(2, 2),
+				Size = UDim2.fromOffset(KEY_HINT_SIZE, KEY_HINT_SIZE),
+				BackgroundColor3 = KEY_HINT_COLOR,
+				BackgroundTransparency = 0.2,
+				Font = Enum.Font.GothamBold,
+				TextSize = KEY_HINT_TEXT_SIZE,
+				TextColor3 = TEXT_COLOR,
+				Text = props.KeyHint,
+				Visible = props.ShowKeyHint,
+
+				create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS - 2) }),
+			}),
 		}),
 
 		create("TextLabel")({
 			Name = "BlockName",
-			Position = UDim2.fromOffset(TILE_SIZE + TILE_GAP, 0),
-			Size = UDim2.fromOffset(NAME_WIDTH, TILE_SIZE),
+			Position = function()
+				return toOffset(metrics().NamePosition)
+			end,
+			Size = function()
+				return toOffset(metrics().NameSize)
+			end,
 			BackgroundTransparency = 1,
 			Font = Enum.Font.Gotham,
-			TextSize = 16,
+			TextSize = function()
+				return metrics().NameTextSize
+			end,
 			TextColor3 = TEXT_COLOR,
-			TextXAlignment = Enum.TextXAlignment.Left,
+			TextXAlignment = function()
+				return metrics().NameAlignment
+			end,
+			TextTruncate = Enum.TextTruncate.AtEnd,
 			Text = props.BlockType.DisplayName,
 		}),
 	})
 end
 
-export type BlockPickerProps = {
-	Selected: () -> string,
-	Select: (name: string) -> (),
-}
-
 local function blockPicker(props: BlockPickerProps): Frame
+	-- Derived, so bindings rerun when the layout flips and not on every
+	-- pixel of a window resize.
+	local metrics = derive(function(): Metrics
+		return METRICS[read(props.Layout)]
+	end)
+
+	local function showKeyHint(): boolean
+		return read(props.ShowKeyHints) == true
+	end
+
 	local tiles = {}
 	for index, blockType in BlockTypes.List do
 		tiles[index] = tile({
 			BlockType = blockType,
 			LayoutOrder = index + 1,
+			KeyHint = if index <= KEY_HINT_COUNT then tostring(index) else nil,
+			Metrics = metrics,
+			ShowKeyHint = showKeyHint,
 			IsSelected = function()
 				return props.Selected() == blockType.Name
 			end,
@@ -93,8 +209,8 @@ local function blockPicker(props: BlockPickerProps): Frame
 
 	return create("Frame")({
 		Name = "BlockPicker",
-		AnchorPoint = Vector2.new(0, 0.5),
-		Position = UDim2.new(0, 20, 0.5, 0),
+		AnchorPoint = props.AnchorPoint or Vector2.zero,
+		Position = props.Position or UDim2.fromOffset(0, 0),
 		AutomaticSize = Enum.AutomaticSize.XY,
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
@@ -107,24 +223,30 @@ local function blockPicker(props: BlockPickerProps): Frame
 			PaddingBottom = UDim.new(0, PANEL_PADDING),
 		}),
 		create("UIListLayout")({
-			FillDirection = Enum.FillDirection.Vertical,
+			FillDirection = function()
+				return metrics().FillDirection
+			end,
 			Padding = UDim.new(0, TILE_GAP),
 		}),
 
 		create("TextLabel")({
 			Name = "Title",
 			LayoutOrder = 1,
-			Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TITLE_HEIGHT),
+			Size = function()
+				return UDim2.fromOffset(metrics().TileSize.X, TITLE_HEIGHT)
+			end,
+			Visible = function()
+				return metrics().HasTitle
+			end,
 			BackgroundTransparency = 1,
 			Font = Enum.Font.GothamBold,
-			TextScaled = true,
+			TextSize = TITLE_TEXT_SIZE,
 			TextColor3 = TEXT_COLOR,
 			TextXAlignment = Enum.TextXAlignment.Left,
+			TextTruncate = Enum.TextTruncate.AtEnd,
 			Text = function()
 				return BlockTypes.ByName[props.Selected()].DisplayName
 			end,
-
-			create("UITextSizeConstraint")({ MaxTextSize = TITLE_MAX_TEXT_SIZE }),
 		}),
 
 		tiles,
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau
index e8d33eb..c8d1828 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau
@@ -11,6 +11,7 @@ local Workspace = game:GetService("Workspace")
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 
 local RAY_LENGTH = 512
+-- Keep in sync with KEY_HINT_COUNT in BlockPicker.
 local NUMBER_KEYS = {
 	Enum.KeyCode.One,
 	Enum.KeyCode.Two,
diff --git a/src/StarterPlayer/StarterPlayerScripts/GameScreenGui.luau b/src/StarterPlayer/StarterPlayerScripts/GameScreenGui.luau
new file mode 100644
index 0000000..dafd63a
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/GameScreenGui.luau
@@ -0,0 +1,33 @@
+--!strict
+--[[
+	The ScreenGui every game screen is built in. It keeps interactive UI clear
+	of Roblox's own buttons and grows everything inside it on screens whose
+	short side is over 1080, so UI authored for 1080p keeps its share of a
+	1440p or 4K monitor or a TV.
+]]
+
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+local Screen = require("./Screen")
+
+local create = Vide.create
+
+export type GameScreenGuiProps = {
+	Name: string,
+	DisplayOrder: number?,
+	Children: { any },
+}
+
+local function gameScreenGui(props: GameScreenGuiProps): ScreenGui
+	return create("ScreenGui")({
+		Name = props.Name,
+		DisplayOrder = props.DisplayOrder or 0,
+		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
+
+		create("UIScale")({ Scale = Screen.uiScale }),
+
+		props.Children,
+	})
+end
+
+return gameScreenGui
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 04bc27a..b1fe257 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,14 +1,24 @@
 local Players = game:GetService("Players")
-local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-local BlockPicker = require(script.Parent.BlockPicker)
-local BlockPlacer = require(script.Parent.BlockPlacer)
-local Vide = require(ReplicatedStorage.Packages.Vide)
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
 
-local create = Vide.create
+local BlockPicker = require("./BlockPicker")
+local BlockPlacer = require("./BlockPlacer")
+local GameScreenGui = require("./GameScreenGui")
+local Screen = require("./Screen")
+
+local derive = Vide.derive
 local mount = Vide.mount
 local source = Vide.source
 
+-- The column sits mid-left, out of the way on a desktop. The row sits at the
+-- top center, clear of the thumbstick (lower left) and jump button (lower
+-- right) on touch screens.
+local COLUMN_ANCHOR = Vector2.new(0, 0.5)
+local COLUMN_POSITION = UDim2.new(0, 20, 0.5, 0)
+local ROW_ANCHOR = Vector2.new(0.5, 0)
+local ROW_POSITION = UDim2.new(0.5, 0, 0, 8)
+
 local localPlayer = Players.LocalPlayer
 local playerGui = localPlayer:WaitForChild("PlayerGui")
 
@@ -18,13 +28,28 @@ BlockPlacer.BlockTypeChanged:Connect(function(name: string)
 end)
 
 local function app()
-	return create("ScreenGui")({
-		Name = "BlockPickerGui",
+	local layout = derive(function(): BlockPicker.Layout
+		return if Screen.isTouchLayout() then "Row" else "Column"
+	end)
 
-		BlockPicker({
-			Selected = selected,
-			Select = BlockPlacer.setBlockType,
-		}),
+	return GameScreenGui({
+		Name = "BlockPickerGui",
+		Children = {
+			BlockPicker({
+				Selected = selected,
+				Select = BlockPlacer.setBlockType,
+				Layout = layout,
+				ShowKeyHints = function()
+					return Screen.preferredInput() == Enum.PreferredInput.KeyboardAndMouse
+				end,
+				AnchorPoint = function()
+					return if layout() == "Row" then ROW_ANCHOR else COLUMN_ANCHOR
+				end,
+				Position = function()
+					return if layout() == "Row" then ROW_POSITION else COLUMN_POSITION
+				end,
+			}),
+		},
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/Screen.luau
new file mode 100644
index 0000000..f2ee7b1
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Screen.luau
@@ -0,0 +1,138 @@
+--!strict
+--[[
+	Facts about the player's screen, as Vide sources, so UI follows the device
+	live: a window resize, a phone or tablet rotating, a keyboard or gamepad
+	being connected. UI reads the screen here and nowhere else.
+
+	Sizes are authored once for a screen 1080 pixels tall. Larger screens grow
+	the whole UI with uiScale; smaller screens keep a scale of 1 and change
+	layout instead.
+]]
+
+local GuiService = game:GetService("GuiService")
+local RunService = game:GetService("RunService")
+local UserInputService = game:GetService("UserInputService")
+
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
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
+local Module = {}
+
+local realViewport = source(FALLBACK_VIEWPORT)
+local realInset = source(Vector2.zero)
+local preferredInput = source(Enum.PreferredInput.KeyboardAndMouse)
+local isLargeDisplay = source(false)
+local viewportConnection: RBXScriptConnection? = nil
+
+local function refresh()
+	local camera = workspace.CurrentCamera
+	local topLeftInset = GuiService:GetGuiInset()
+	-- One batch, so a device switch reruns each binding once, with every fact
+	-- already updated.
+	batch(function()
+		-- ViewportSize can read (1, 1) before the first frame, which would pass
+		-- for a tiny phone.
+		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
+			realViewport(camera.ViewportSize)
+		end
+		realInset(topLeftInset)
+		preferredInput(UserInputService.PreferredInput)
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
+	How much the whole UI grows on this screen: the short side over 1080, never
+	below 1 or above 3, with a quarter more on a TV. Only GameScreenGui binds
+	it; components never use it for their own sizes.
+]]
+function Module.uiScale(): number
+	local view = realViewport()
+	local boost = if isLargeDisplay() then LARGE_DISPLAY_BOOST else 1
+	return math.clamp(
+		math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE * boost,
+		MINIMUM_SCALE,
+		MAXIMUM_SCALE
+	)
+end
+
+--[[
+	The viewport in UI units.
+]]
+function Module.viewport(): Vector2
+	return realViewport() / Module.uiScale()
+end
+
+--[[
+	The part of the viewport below the Roblox topbar, in UI units.
+]]
+function Module.usableSize(): Vector2
+	local view = Module.viewport()
+	return Vector2.new(view.X, view.Y - realInset().Y / Module.uiScale())
+end
+
+--[[
+	Roblox's pick of the player's primary input.
+]]
+function Module.preferredInput(): Enum.PreferredInput
+	return preferredInput()
+end
+
+--[[
+	Whether touch is the primary input, which is when Roblox shows its
+	thumbstick and jump button.
+]]
+function Module.isTouch(): boolean
+	return preferredInput() == Enum.PreferredInput.Touch
+end
+
+--[[
+	A phone is a size, not a platform: a desktop window dragged that small
+	cannot fit a desktop layout either.
+]]
+function Module.isPhone(): boolean
+	local view = Module.viewport()
+	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
+end
+
+--[[
+	Whether UI should use its touch layout: the touch controls are up, or the
+	screen is too small for the desktop layout.
+]]
+function Module.isTouchLayout(): boolean
+	return Module.isTouch() or Module.isPhone()
+end
+
+-- UI Labs loads a fresh copy of this module on every reload, and a connection
+-- would keep each copy alive, so edit mode reads the screen once.
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
+return Module

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
diff --git a/README.md b/README.md
index cb3047d..4b28b64 100644
--- a/README.md
+++ b/README.md
@@ -22,6 +22,20 @@ are ModuleScripts.
 pesde installs packages from `pesde.toml`. Vide 0.4.1 is installed:
 `require(ReplicatedStorage.Packages.Vide)`.
 
+## UI
+
+Client UI is built with Vide. Shared pieces live in `StarterPlayerScripts/UI`:
+
+- `Screen` is the root for every screen. It wraps a ScreenGui that stays inside the safe area,
+  survives respawns, and scales its contents with a UIScale.
+- `Responsive` has reactive device state: `viewportSize`, `inputMode` (`"Touch"`, `"Gamepad"`,
+  `"KeyboardMouse"`), `isTouch`, `isPortrait`, `isCompact`, `designSize`, `scale`, and
+  `MIN_TOUCH_TARGET`.
+
+Write sizes in design units (1 unit = 1 px at 1080p, or 1 pt on phones and tablets). Use
+`Responsive` inside property functions when a layout needs to change shape, not just size, for
+example moving out of the way of the touch thumbstick.
+
 ## Checks
 
 Tools come from Rokit (`rokit.toml`). Run each command on its own from the project root:
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index b45f323..4352fd8 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,11 +1,18 @@
 --[[
-	The block picker: a column of tiles down the left side of the screen, one per block type, each
-	with the block's name beside it, under a title naming the selected block.
+	The block picker: one tile per block type under a title naming the selected block.
+
+	With a keyboard and mouse or a gamepad it is a column down the left side of the screen, with each
+	block's name beside its tile. On touch screens the left side belongs to the movement thumbstick
+	and the bottom right to the jump button, so it becomes a row of larger, name-less tiles along the
+	top centre instead. It switches between the two as soon as the player's input changes.
+
+	Sizes are in design units; the Screen it is mounted in scales them to the display.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Responsive = require(script.Parent.UI.Responsive)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local create = Vide.create
@@ -14,17 +21,38 @@ type BlockType = BlockTypes.BlockType
 
 local TILE_SIZE = 40
 local TILE_GAP = 6
+-- Comfortably above the minimum tap target so neighbouring tiles are hard to hit by mistake.
+local TOUCH_TILE_SIZE = Responsive.MIN_TOUCH_TARGET + 4
+local TOUCH_TILE_GAP = 8
 local TILE_RADIUS = 6
+-- Outline thickness as a fraction of the swatch's size (3 and 1 pixels on a 40-unit tile).
+local SELECTED_STROKE = 3 / TILE_SIZE
+local IDLE_STROKE = 1 / TILE_SIZE
 local NAME_WIDTH = 96
-local TITLE_HEIGHT = 30
-local TITLE_MAX_TEXT_SIZE = 24
+local NAME_TEXT_SIZE = 16
+local TITLE_HEIGHT = 26
+local TITLE_TEXT_SIZE = 22
 local PANEL_PADDING = 10
 local PANEL_RADIUS = 10
+local SCREEN_MARGIN = 20
+local TOUCH_SCREEN_MARGIN = 8
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
 local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
 
+local function tileSize(): number
+	return if Responsive.isTouch() then TOUCH_TILE_SIZE else TILE_SIZE
+end
+
+local function tileGap(): number
+	return if Responsive.isTouch() then TOUCH_TILE_GAP else TILE_GAP
+end
+
+local function showsNames(): boolean
+	return not Responsive.isTouch()
+end
+
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
@@ -36,36 +64,52 @@ local function tile(props: TileProps): TextButton
 	return create("TextButton")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
-		Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TILE_SIZE),
+		Size = function()
+			local size = tileSize()
+			local width = if showsNames() then size + tileGap() + NAME_WIDTH else size
+			return UDim2.fromOffset(width, size)
+		end,
 		BackgroundTransparency = 1,
 
 		Activated = props.Select,
 
 		create("Frame")({
 			Name = "Swatch",
-			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
+			Size = function()
+				local size = tileSize()
+				return UDim2.fromOffset(size, size)
+			end,
 			BackgroundColor3 = props.BlockType.Color,
 
 			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
 			create("UIStroke")({
+				-- Thickness is a fraction of the swatch, so the outline grows with the tile on
+				-- every display instead of staying a fixed number of pixels.
+				StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
 				Color = function()
 					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
 				end,
 				Thickness = function()
-					return if props.IsSelected() then 3 else 1
+					return if props.IsSelected() then SELECTED_STROKE else IDLE_STROKE
 				end,
 			}),
 		}),
 
 		create("TextLabel")({
 			Name = "BlockName",
-			Position = UDim2.fromOffset(TILE_SIZE + TILE_GAP, 0),
-			Size = UDim2.fromOffset(NAME_WIDTH, TILE_SIZE),
+			Visible = showsNames,
+			Position = function()
+				return UDim2.fromOffset(tileSize() + tileGap(), 0)
+			end,
+			Size = function()
+				return UDim2.fromOffset(NAME_WIDTH, tileSize())
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
@@ -81,7 +125,7 @@ local function blockPicker(props: BlockPickerProps): Frame
 	for index, blockType in BlockTypes.List do
 		tiles[index] = tile({
 			BlockType = blockType,
-			LayoutOrder = index + 1,
+			LayoutOrder = index,
 			IsSelected = function()
 				return props.Selected() == blockType.Name
 			end,
@@ -93,8 +137,14 @@ local function blockPicker(props: BlockPickerProps): Frame
 
 	return create("Frame")({
 		Name = "BlockPicker",
-		AnchorPoint = Vector2.new(0, 0.5),
-		Position = UDim2.new(0, 20, 0.5, 0),
+		AnchorPoint = function()
+			return if Responsive.isTouch() then Vector2.new(0.5, 0) else Vector2.new(0, 0.5)
+		end,
+		Position = function()
+			return if Responsive.isTouch()
+				then UDim2.new(0.5, 0, 0, TOUCH_SCREEN_MARGIN)
+				else UDim2.new(0, SCREEN_MARGIN, 0.5, 0)
+		end,
 		AutomaticSize = Enum.AutomaticSize.XY,
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
@@ -108,26 +158,51 @@ local function blockPicker(props: BlockPickerProps): Frame
 		}),
 		create("UIListLayout")({
 			FillDirection = Enum.FillDirection.Vertical,
-			Padding = UDim.new(0, TILE_GAP),
+			HorizontalAlignment = Enum.HorizontalAlignment.Center,
+			Padding = function()
+				return UDim.new(0, tileGap())
+			end,
 		}),
 
 		create("TextLabel")({
 			Name = "Title",
 			LayoutOrder = 1,
-			Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TITLE_HEIGHT),
+			-- Fills the panel's width, which the tiles decide.
+			Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
 			BackgroundTransparency = 1,
 			Font = Enum.Font.GothamBold,
-			TextScaled = true,
+			TextSize = TITLE_TEXT_SIZE,
 			TextColor3 = TEXT_COLOR,
-			TextXAlignment = Enum.TextXAlignment.Left,
+			TextXAlignment = function()
+				return if Responsive.isTouch()
+					then Enum.TextXAlignment.Center
+					else Enum.TextXAlignment.Left
+			end,
+			TextTruncate = Enum.TextTruncate.AtEnd,
 			Text = function()
 				return BlockTypes.ByName[props.Selected()].DisplayName
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
+					return if Responsive.isTouch()
+						then Enum.FillDirection.Horizontal
+						else Enum.FillDirection.Vertical
+				end,
+				Padding = function()
+					return UDim.new(0, tileGap())
+				end,
+			}),
+
+			tiles,
+		}),
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 04bc27a..1f37db0 100644
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
 
@@ -18,13 +18,14 @@ BlockPlacer.BlockTypeChanged:Connect(function(name: string)
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
+			}),
+		},
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau
new file mode 100644
index 0000000..150bce4
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau
@@ -0,0 +1,149 @@
+--[[
+	Reactive facts about the player's screen and input device, shared by every UI screen.
+
+	Screens are authored in design units: one unit is one pixel on a 1080p monitor, or one point on
+	a phone or tablet. Each Screen root applies `Responsive.scale()` with a UIScale, so sizes written
+	in design units come out at a sensible physical size on every device.
+
+	Everything here is a Vide source or a plain function that reads sources, so reading it inside a
+	property function or effect keeps that UI up to date as the player rotates a device, resizes the
+	window, or switches between touch, keyboard and mouse, and gamepad.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local UserInputService = game:GetService("UserInputService")
+local Workspace = game:GetService("Workspace")
+
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local source = Vide.source
+
+export type InputMode = "Touch" | "Gamepad" | "KeyboardMouse"
+
+-- Smallest comfortable tap target, in design units (Apple and Google both use about 44).
+local MIN_TOUCH_TARGET = 44
+
+-- Desktop viewports are in physical pixels, so a 4K monitor reports 3840 x 2160. Scaling by the
+-- short edge against 1080 keeps UI the same physical size as on the 1080p monitor it was built on.
+local DESKTOP_REFERENCE_SHORT_EDGE = 1080
+local DESKTOP_MAX_SCALE = 4
+
+-- Phone and tablet viewports are in points (a phone's short edge is about 360 to 430, a tablet's
+-- about 740 to 1030). Phones stay at 1; tablets grow a little to use their extra room.
+local TOUCH_REFERENCE_SHORT_EDGE = 720
+local TOUCH_MAX_SCALE = 1.5
+
+-- Gamepad players usually sit further from a TV, so their UI is drawn a bit larger.
+local GAMEPAD_SCALE_BOOST = 1.25
+
+-- Rounding the scale stops UI re-laying out on every pixel while a window is dragged.
+local SCALE_STEP = 0.05
+
+-- A screen whose short edge is under this many design units is treated as compact.
+local COMPACT_SHORT_EDGE = 500
+
+local function readInputMode(): InputMode
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
+local viewportSize =
+	source(Vector2.new(DESKTOP_REFERENCE_SHORT_EDGE * 16 / 9, DESKTOP_REFERENCE_SHORT_EDGE))
+local inputMode = source(readInputMode())
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
+	viewportSize(camera.ViewportSize)
+	cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
+		viewportSize(camera.ViewportSize)
+	end)
+end
+
+Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
+watchCamera()
+
+UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
+	inputMode(readInputMode())
+end)
+
+local Responsive = {}
+
+Responsive.MIN_TOUCH_TARGET = MIN_TOUCH_TARGET
+
+--[[
+	The viewport size in physical pixels (desktop) or points (phones and tablets).
+]]
+Responsive.viewportSize = viewportSize :: () -> Vector2
+
+--[[
+	How the player is controlling the game right now. Changes as soon as they touch the screen,
+	press a key, or pick up a gamepad.
+]]
+Responsive.inputMode = inputMode :: () -> InputMode
+
+function Responsive.isTouch(): boolean
+	return inputMode() == "Touch"
+end
+
+function Responsive.isPortrait(): boolean
+	local size = viewportSize()
+	return size.Y > size.X
+end
+
+--[[
+	The factor that turns design units into screen pixels. Screen roots apply it with a UIScale, so
+	most components never need to read it themselves.
+]]
+function Responsive.scale(): number
+	local size = viewportSize()
+	local shortEdge = math.min(size.X, size.Y)
+	local mode = inputMode()
+
+	local scale
+	if mode == "Touch" then
+		scale = math.clamp(shortEdge / TOUCH_REFERENCE_SHORT_EDGE, 1, TOUCH_MAX_SCALE)
+	else
+		scale = math.clamp(shortEdge / DESKTOP_REFERENCE_SHORT_EDGE, 1, DESKTOP_MAX_SCALE)
+		if mode == "Gamepad" then
+			scale *= GAMEPAD_SCALE_BOOST
+		end
+	end
+
+	return math.round(scale / SCALE_STEP) * SCALE_STEP
+end
+
+--[[
+	How much room a screen has, in design units. Use it to decide whether a layout fits.
+]]
+function Responsive.designSize(): Vector2
+	return viewportSize() / Responsive.scale()
+end
+
+--[[
+	True on small screens such as phones and very small windows.
+]]
+function Responsive.isCompact(): boolean
+	local size = Responsive.designSize()
+	return math.min(size.X, size.Y) < COMPACT_SHORT_EDGE
+end
+
+return table.freeze(Responsive)
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
new file mode 100644
index 0000000..03bce7e
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
@@ -0,0 +1,41 @@
+--[[
+	The root of every UI screen: a ScreenGui that stays inside the device's safe area, survives
+	respawns, and scales its contents with `Responsive.scale()`. Write everything inside it in
+	design units (see Responsive).
+
+		Screen({
+			Name = "InventoryGui",
+			Children = { inventoryPanel() },
+		})
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
+		IgnoreGuiInset = false,
+		-- Keeps content clear of the Roblox topbar, notches, and rounded corners.
+		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
+		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
+
+		create("UIScale")({ Scale = Responsive.scale }),
+
+		props.Children,
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
