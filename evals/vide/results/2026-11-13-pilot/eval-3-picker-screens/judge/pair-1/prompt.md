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
index cb3047d..6dad717 100644
--- a/README.md
+++ b/README.md
@@ -22,6 +22,21 @@ are ModuleScripts.
 pesde installs packages from `pesde.toml`. Vide 0.4.1 is installed:
 `require(ReplicatedStorage.Packages.Vide)`.
 
+## UI
+
+UI is built with Vide and authored once, in offsets, for a screen 1080 pixels tall.
+
+- Build every screen inside `UI/screenGui` (in `StarterPlayerScripts`). It adds one `UIScale`
+  that grows the UI on screens taller than 1080 (2x at 4K, 1.25x on a TV) and keeps the UI clear
+  of Roblox's topbar buttons.
+- Read the screen from `UI/Screen`, never the camera directly. Its getters (`isTouchLayout`,
+  `isPhone`, `isTouch`, `usableSize`) are live, so bind to them and layouts follow resizes,
+  rotation, and input changes during a session.
+- Phones and tablets keep a scale of 1 and change layout instead. A reusable component takes its
+  layout as a prop (see `BlockPicker`'s `Layout`), and the screen that mounts it passes one
+  derived from `Screen`.
+- Stories for UI Labs live in `ServerScriptService/Stories`.
+
 ## Checks
 
 Tools come from Rokit (`rokit.toml`). Run each command on its own from the project root:
diff --git a/src/ServerScriptService/Stories/BlockPicker.story.luau b/src/ServerScriptService/Stories/BlockPicker.story.luau
new file mode 100644
index 0000000..74d403d
--- /dev/null
+++ b/src/ServerScriptService/Stories/BlockPicker.story.luau
@@ -0,0 +1,46 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	The block picker in its mouse-and-keyboard column and its touch row.
+	Clicking a tile selects it, as in game.
+]]
+
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const BlockPicker = require("@game/StarterPlayer/StarterPlayerScripts/BlockPicker")
+
+const source = Vide.source
+
+type StoryProps = {
+	controls: {
+		IsTouchLayout: () -> boolean,
+	},
+	target: Frame,
+}
+
+const CONTROLS = {
+	IsTouchLayout = false,
+}
+
+local function story(props: StoryProps)
+	const selected = source(BlockTypes.List[1].Name)
+
+	return BlockPicker({
+		Layout = function(): BlockPicker.Layout
+			return if props.controls.IsTouchLayout() then "Row" else "Column"
+		end,
+		Selected = selected,
+		Select = function(name: string)
+			selected(name)
+		end,
+	})
+end
+
+return {
+	summary = "The block picker's column and touch row layouts.",
+	vide = Vide,
+	controls = CONTROLS,
+	story = story,
+}
diff --git a/src/ServerScriptService/Stories/Game.storybook.luau b/src/ServerScriptService/Stories/Game.storybook.luau
new file mode 100644
index 0000000..907c2b3
--- /dev/null
+++ b/src/ServerScriptService/Stories/Game.storybook.luau
@@ -0,0 +1,12 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	The UI Labs storybook for the game's UI. Studio-only: nothing in the game
+	requires this folder.
+]]
+
+return {
+	name = "Game UI",
+	storyRoots = { script.Parent },
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index b45f323..78b8f45 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,33 +1,95 @@
 --[[
-	The block picker: a column of tiles down the left side of the screen, one per block type, each
-	with the block's name beside it, under a title naming the selected block.
-]]
+	The block picker: one tile per block type, showing the block's color and name, with the
+	selected tile outlined and its name in bold. It has two layouts:
 
-local ReplicatedStorage = game:GetService("ReplicatedStorage")
+	- Column: down the left edge under a title naming the selected block, for mouse and keyboard.
+	- Row: larger tiles across the top-right corner, for touch, clear of the thumbstick region
+	  (left 40%, lower two thirds) and the jump button.
+]]
 
-local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
-local Vide = require(ReplicatedStorage.Packages.Vide)
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
 
-local create = Vide.create
+const create = Vide.create
+const derive = Vide.derive
+const read = Vide.read
 
 type BlockType = BlockTypes.BlockType
 
-local TILE_SIZE = 40
-local TILE_GAP = 6
-local TILE_RADIUS = 6
-local NAME_WIDTH = 96
-local TITLE_HEIGHT = 30
-local TITLE_MAX_TEXT_SIZE = 24
-local PANEL_PADDING = 10
-local PANEL_RADIUS = 10
-local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
-local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
-local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
-local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
+export type Layout = "Column" | "Row"
+
+type Metrics = {
+	PanelAnchor: Vector2,
+	PanelPosition: UDim2,
+	FillDirection: Enum.FillDirection,
+	TileSize: Vector2,
+	SwatchSize: number,
+	SwatchPosition: Vector2,
+	NameSize: Vector2,
+	NamePosition: Vector2,
+	NameTextSize: number,
+	NameAlignment: Enum.TextXAlignment,
+	HasTitle: boolean,
+}
+
+const TILE_GAP = 6
+const TILE_RADIUS = 6
+const TITLE_HEIGHT = 30
+const TITLE_TEXT_SIZE = 24
+const PANEL_PADDING = 10
+const PANEL_RADIUS = 10
+const PANEL_COLOR = Color3.fromRGB(28, 28, 34)
+const SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
+const IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
+const TEXT_COLOR = Color3.fromRGB(240, 240, 240)
+
+const COLUMN_SWATCH = 40
+const COLUMN_NAME_WIDTH = 96
+const COLUMN_TILE_WIDTH = COLUMN_SWATCH + TILE_GAP + COLUMN_NAME_WIDTH
+
+-- Wide enough for "Window" at the row's text size, and narrow enough that
+-- five tiles start right of the thumbstick region on a 667 wide phone.
+const ROW_TILE_WIDTH = 68
+const ROW_SWATCH = 56
+const ROW_NAME_HEIGHT = 18
+const ROW_NAME_GAP = 4
+
+const COLUMN: Metrics = table.freeze({
+	PanelAnchor = Vector2.new(0, 0.5),
+	PanelPosition = UDim2.new(0, 20, 0.5, 0),
+	FillDirection = Enum.FillDirection.Vertical,
+	TileSize = Vector2.new(COLUMN_TILE_WIDTH, COLUMN_SWATCH),
+	SwatchSize = COLUMN_SWATCH,
+	SwatchPosition = Vector2.zero,
+	NameSize = Vector2.new(COLUMN_NAME_WIDTH, COLUMN_SWATCH),
+	NamePosition = Vector2.new(COLUMN_SWATCH + TILE_GAP, 0),
+	NameTextSize = 16,
+	NameAlignment = Enum.TextXAlignment.Left,
+	HasTitle = true,
+})
+
+const ROW: Metrics = table.freeze({
+	PanelAnchor = Vector2.new(1, 0),
+	PanelPosition = UDim2.new(1, -12, 0, 12),
+	FillDirection = Enum.FillDirection.Horizontal,
+	TileSize = Vector2.new(ROW_TILE_WIDTH, ROW_SWATCH + ROW_NAME_GAP + ROW_NAME_HEIGHT),
+	SwatchSize = ROW_SWATCH,
+	SwatchPosition = Vector2.new((ROW_TILE_WIDTH - ROW_SWATCH) / 2, 0),
+	NameSize = Vector2.new(ROW_TILE_WIDTH, ROW_NAME_HEIGHT),
+	NamePosition = Vector2.new(0, ROW_SWATCH + ROW_NAME_GAP),
+	NameTextSize = 15,
+	NameAlignment = Enum.TextXAlignment.Center,
+	HasTitle = false,
+})
+
+local function toOffset(vector: Vector2): UDim2
+	return UDim2.fromOffset(vector.X, vector.Y)
+end
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
+	Metrics: () -> Metrics,
 	IsSelected: () -> boolean,
 	Select: () -> (),
 }
@@ -36,14 +98,22 @@ local function tile(props: TileProps): TextButton
 	return create("TextButton")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
-		Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TILE_SIZE),
+		Size = function()
+			return toOffset(props.Metrics().TileSize)
+		end,
 		BackgroundTransparency = 1,
 
 		Activated = props.Select,
 
 		create("Frame")({
 			Name = "Swatch",
-			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
+			Position = function()
+				return toOffset(props.Metrics().SwatchPosition)
+			end,
+			Size = function()
+				const size = props.Metrics().SwatchSize
+				return UDim2.fromOffset(size, size)
+			end,
 			BackgroundColor3 = props.BlockType.Color,
 
 			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
@@ -59,29 +129,48 @@ local function tile(props: TileProps): TextButton
 
 		create("TextLabel")({
 			Name = "BlockName",
-			Position = UDim2.fromOffset(TILE_SIZE + TILE_GAP, 0),
-			Size = UDim2.fromOffset(NAME_WIDTH, TILE_SIZE),
+			Position = function()
+				return toOffset(props.Metrics().NamePosition)
+			end,
+			Size = function()
+				return toOffset(props.Metrics().NameSize)
+			end,
 			BackgroundTransparency = 1,
-			Font = Enum.Font.Gotham,
-			TextSize = 16,
+			Font = function()
+				return if props.IsSelected() then Enum.Font.GothamBold else Enum.Font.Gotham
+			end,
+			TextSize = function()
+				return props.Metrics().NameTextSize
+			end,
 			TextColor3 = TEXT_COLOR,
-			TextXAlignment = Enum.TextXAlignment.Left,
+			TextXAlignment = function()
+				return props.Metrics().NameAlignment
+			end,
+			TextTruncate = Enum.TextTruncate.AtEnd,
 			Text = props.BlockType.DisplayName,
 		}),
 	})
 end
 
 export type BlockPickerProps = {
+	Layout: Layout | () -> Layout,
 	Selected: () -> string,
 	Select: (name: string) -> (),
 }
 
 local function blockPicker(props: BlockPickerProps): Frame
+	-- Derived, so bindings rerun when the layout flips, not on every pixel of
+	-- a window resize.
+	const metrics = derive(function(): Metrics
+		return if read(props.Layout) == "Row" then ROW else COLUMN
+	end)
+
 	local tiles = {}
 	for index, blockType in BlockTypes.List do
 		tiles[index] = tile({
 			BlockType = blockType,
 			LayoutOrder = index + 1,
+			Metrics = metrics,
 			IsSelected = function()
 				return props.Selected() == blockType.Name
 			end,
@@ -93,8 +182,12 @@ local function blockPicker(props: BlockPickerProps): Frame
 
 	return create("Frame")({
 		Name = "BlockPicker",
-		AnchorPoint = Vector2.new(0, 0.5),
-		Position = UDim2.new(0, 20, 0.5, 0),
+		AnchorPoint = function()
+			return metrics().PanelAnchor
+		end,
+		Position = function()
+			return metrics().PanelPosition
+		end,
 		AutomaticSize = Enum.AutomaticSize.XY,
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
@@ -107,24 +200,30 @@ local function blockPicker(props: BlockPickerProps): Frame
 			PaddingBottom = UDim.new(0, PANEL_PADDING),
 		}),
 		create("UIListLayout")({
-			FillDirection = Enum.FillDirection.Vertical,
+			FillDirection = function()
+				return metrics().FillDirection
+			end,
 			Padding = UDim.new(0, TILE_GAP),
 		}),
 
+		-- In the row each tile names itself, so the title only takes room.
 		create("TextLabel")({
 			Name = "Title",
 			LayoutOrder = 1,
-			Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TITLE_HEIGHT),
+			Visible = function()
+				return metrics().HasTitle
+			end,
+			Size = UDim2.fromOffset(COLUMN_TILE_WIDTH, TITLE_HEIGHT),
 			BackgroundTransparency = 1,
 			Font = Enum.Font.GothamBold,
-			TextScaled = true,
+			-- A fixed size grows with the root UIScale; a TextScaled cap would not.
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
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 04bc27a..83af342 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,30 +1,40 @@
-local Players = game:GetService("Players")
-local ReplicatedStorage = game:GetService("ReplicatedStorage")
+const Players = game:GetService("Players")
+const RunService = game:GetService("RunService")
 
-local BlockPicker = require(script.Parent.BlockPicker)
-local BlockPlacer = require(script.Parent.BlockPlacer)
-local Vide = require(ReplicatedStorage.Packages.Vide)
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
 
-local create = Vide.create
-local mount = Vide.mount
-local source = Vide.source
+const BlockPicker = require("./BlockPicker")
+const BlockPlacer = require("./BlockPlacer")
+const Screen = require("./UI/Screen")
+const screenGui = require("./UI/screenGui")
 
-local localPlayer = Players.LocalPlayer
-local playerGui = localPlayer:WaitForChild("PlayerGui")
+Vide.strict = RunService:IsStudio()
 
-local selected = source(BlockPlacer.getBlockType())
+const mount = Vide.mount
+const source = Vide.source
+
+const localPlayer = Players.LocalPlayer
+const playerGui = localPlayer:WaitForChild("PlayerGui")
+
+const selected = source(BlockPlacer.getBlockType())
 BlockPlacer.BlockTypeChanged:Connect(function(name: string)
 	selected(name)
 end)
 
+local function pickerLayout(): BlockPicker.Layout
+	return if Screen.isTouchLayout() then "Row" else "Column"
+end
+
 local function app()
-	return create("ScreenGui")({
+	return screenGui({
 		Name = "BlockPickerGui",
-
-		BlockPicker({
-			Selected = selected,
-			Select = BlockPlacer.setBlockType,
-		}),
+		Children = {
+			BlockPicker({
+				Layout = pickerLayout,
+				Selected = selected,
+				Select = BlockPlacer.setBlockType,
+			}),
+		},
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
new file mode 100644
index 0000000..d18b7b0
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
@@ -0,0 +1,132 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	Live facts about the player's screen, as Vide sources: the UI scale, the
+	viewport and usable area in UI units, and whether touch is the primary
+	input. UI binds to these, so layout follows window resizes, rotation, and
+	input changes during a session.
+
+	UI is authored in offsets for a screen 1080 pixels tall. Larger screens
+	grow it through Module.uiScale; smaller ones change layout instead.
+]]
+
+const GuiService = game:GetService("GuiService")
+const RunService = game:GetService("RunService")
+const UserInputService = game:GetService("UserInputService")
+
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const batch = Vide.batch
+const source = Vide.source
+
+const REFERENCE_SHORT_SIDE = 1080
+const MINIMUM_SCALE = 1
+const MAXIMUM_SCALE = 3
+-- TVs are read from a couch, so they get more than their pixels alone give.
+const LARGE_DISPLAY_BOOST = 1.25
+-- In UI units. Phones held sideways are 360 to 440 tall; tablets start near 600.
+const PHONE_SHORT_SIDE = 600
+const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)
+
+local Module = {}
+
+local realViewport = source(FALLBACK_VIEWPORT)
+local realInset = source(Vector2.zero)
+local prefersTouch = source(false)
+local isLargeDisplay = source(false)
+local viewportConnection: RBXScriptConnection? = nil
+
+local function refresh()
+	const camera = workspace.CurrentCamera
+	const topLeftInset = GuiService:GetGuiInset()
+	batch(function()
+		-- ViewportSize reads (1, 1) before the first frame, which would pass
+		-- for a tiny phone, so the fallback stays until a real size arrives.
+		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
+			realViewport(camera.ViewportSize)
+		end
+		realInset(topLeftInset)
+		prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
+		isLargeDisplay(GuiService.ViewportDisplaySize == Enum.DisplaySize.Large)
+	end)
+end
+
+-- Camera scripts can replace CurrentCamera, so the listener follows it.
+local function watchCamera()
+	if viewportConnection then
+		viewportConnection:Disconnect()
+	end
+	const camera = workspace.CurrentCamera
+	if camera then
+		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
+	end
+	refresh()
+end
+
+--[[
+	How much the whole UI grows on this screen: the short side over 1080,
+	never below 1 or above 3. Bind it to a UIScale under every ScreenGui.
+]]
+function Module.uiScale(): number
+	const view = realViewport()
+	const boost = if isLargeDisplay() then LARGE_DISPLAY_BOOST else 1
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
+	const view = Module.viewport()
+	return Vector2.new(view.X, view.Y - realInset().Y / Module.uiScale())
+end
+
+--[[
+	Whether touch is the primary input, which is when Roblox shows its
+	thumbstick and jump button.
+]]
+function Module.isTouch(): boolean
+	return prefersTouch()
+end
+
+--[[
+	Whether the screen is phone-sized, whatever the device.
+]]
+function Module.isPhone(): boolean
+	const view = Module.viewport()
+	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
+end
+
+--[[
+	Whether UI should use its touch layout: the touch controls are up, or the
+	screen is too small for the desktop layout.
+]]
+function Module.isTouchLayout(): boolean
+	return prefersTouch() or Module.isPhone()
+end
+
+-- UI Labs loads a fresh copy of this module on every reload, and connections
+-- made there would never be cleaned up, so edit mode reads the screen once.
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
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/screenGui.luau b/src/StarterPlayer/StarterPlayerScripts/UI/screenGui.luau
new file mode 100644
index 0000000..4645022
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/screenGui.luau
@@ -0,0 +1,33 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	The ScreenGui every game screen is built in. It grows its contents with
+	the screen's UI scale and keeps them clear of Roblox's own buttons, so a
+	screen's components are authored once, for 1080p, in offsets.
+]]
+
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const Screen = require("./Screen")
+
+const create = Vide.create
+
+export type ScreenGuiProps = {
+	Name: string,
+	DisplayOrder: number?,
+	Children: { any },
+}
+
+local function screenGui(props: ScreenGuiProps): ScreenGui
+	return create("ScreenGui")({
+		Name = props.Name,
+		DisplayOrder = props.DisplayOrder or 0,
+		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
+
+		create("UIScale")({ Scale = Screen.uiScale }),
+		props.Children,
+	})
+end
+
+return screenGui

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
