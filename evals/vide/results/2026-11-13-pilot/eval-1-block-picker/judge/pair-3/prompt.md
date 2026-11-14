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
Block placement works now: BlockPlacer (a module in StarterPlayerScripts) places the selected block where you click or tap, and the number keys 1 to 5 switch the block type. There's no UI yet, though, so nobody can see which block is selected, and phone players can't switch at all.

Add a hotbar with Vide that shows the five block types from BlockTypes, highlights the selected one, and selects a block when you click or tap it. It has to stay in sync when someone switches with the number keys, and it needs to work on phones as well as PC.
</task>

## Rubric

Score each criterion from 1 to 5 for each attempt (1 poor, 3 acceptable, 5 excellent):

1. The hotbar is built with Vide and started once from client code: components are created inside the function passed to `mount` or `root`, never at module top level or inside an event handler.
2. The selected-tile highlight is a binding (a function or source given to the property, or a derived value), so it updates both when a tile is pressed and when the number keys change BlockPlacer's selection. Nothing that changes is read only once in a component body.
3. The subscription to `BlockPlacer.BlockTypeChanged` (or any other signal from outside the UI) is disconnected when the UI's Vide scope is destroyed, for example with Vide's `cleanup`, rather than left connected forever.
4. The tiles are generated from `BlockTypes.List` through one reusable tile component that takes a props table (block type, whether it is selected, a select callback), not five hand-written copies.
5. No yields inside Vide scopes: any `WaitForChild` for PlayerGui or other instances happens before `mount` or `root` runs, not in a component body, binding, or effect.
6. Works on phones: tiles are large enough to tap (about 44 px or more), and the hotbar fits a small landscape phone while staying clear of Roblox's touch thumbstick (lower left) and jump button (lower right).
7. Correct and in scope: the requested hotbar works as described, placement and the server code keep working, the code is typed and readable, and luau-lsp, selene, and StyLua pass on the attempt's own files. Extra supporting files, such as a preview story, count neither for nor against.

## Attempt A

<attempt_a_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] A Luau file under src requires Vide
- [pass] The UI is started with Vide's mount or root
- [pass] No file under src builds a ScreenGui with Instance.new (the UI is built with Vide's create)
</attempt_a_checks>

<attempt_a_diff>
diff --git a/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
new file mode 100644
index 0000000..b2188d7
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
@@ -0,0 +1,235 @@
+--[[
+	Hotbar for picking a block type. Shows every type in BlockTypes, highlights the selected one,
+	and selects a type when its slot is clicked or tapped. It follows BlockPlacer, so switching with
+	the number keys updates the highlight too.
+
+	Mount it with Vide: `Vide.mount(Hotbar, playerGui)`.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local UserInputService = game:GetService("UserInputService")
+
+local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local BlockPlacer = require(script.Parent.BlockPlacer)
+
+local create = Vide.create
+local source = Vide.source
+local cleanup = Vide.cleanup
+local changed = Vide.changed
+
+local SLOT_SIZE = 64
+local SLOT_GAP = 8
+local BAR_PADDING = 8
+local LABEL_HEIGHT = 24
+local LABEL_GAP = 6
+local BOTTOM_MARGIN = 16
+
+local SLOT_COUNT = #BlockTypes.List
+local BAR_WIDTH = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP + 2 * BAR_PADDING
+local BAR_HEIGHT = SLOT_SIZE + 2 * BAR_PADDING
+
+-- On narrow screens (phones) the hotbar shrinks so it takes at most this share of the screen width,
+-- keeping it clear of the thumbstick and jump button. It never shrinks below MIN_SCALE so slots
+-- stay big enough to tap (64 * 0.7 is about 45 pixels).
+local MAX_WIDTH_FRACTION = 0.5
+local MIN_SCALE = 0.7
+
+local BAR_COLOR = Color3.fromRGB(20, 20, 24)
+local SLOT_COLOR = Color3.fromRGB(45, 45, 52)
+local SLOT_SELECTED_COLOR = Color3.fromRGB(70, 70, 80)
+local STROKE_COLOR = Color3.fromRGB(90, 90, 100)
+local STROKE_SELECTED_COLOR = Color3.fromRGB(255, 255, 255)
+local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
+
+type SlotProps = {
+	blockType: BlockTypes.BlockType,
+	index: number,
+	selected: () -> string,
+	select: (name: string) -> (),
+	showKeyHints: () -> boolean,
+}
+
+local function Slot(props: SlotProps)
+	local blockType = props.blockType
+
+	local function isSelected(): boolean
+		return props.selected() == blockType.Name
+	end
+
+	return create("TextButton")({
+		Name = blockType.Name,
+		LayoutOrder = props.index,
+		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
+		Text = "",
+		AutoButtonColor = false,
+		BorderSizePixel = 0,
+		BackgroundColor3 = function()
+			return if isSelected() then SLOT_SELECTED_COLOR else SLOT_COLOR
+		end,
+
+		-- Activated fires for mouse clicks, touch taps and gamepad presses alike.
+		Activated = function()
+			props.select(blockType.Name)
+		end,
+
+		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
+
+		create("UIStroke")({
+			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+			Color = function()
+				return if isSelected() then STROKE_SELECTED_COLOR else STROKE_COLOR
+			end,
+			Thickness = function()
+				return if isSelected() then 3 else 1
+			end,
+		}),
+
+		-- Colour swatch for the block. Window blocks are see-through, so the swatch is too.
+		create("Frame")({
+			Name = "Swatch",
+			AnchorPoint = Vector2.new(0.5, 0.5),
+			Position = UDim2.fromScale(0.5, 0.5),
+			Size = UDim2.fromScale(0.6, 0.6),
+			BorderSizePixel = 0,
+			BackgroundColor3 = blockType.Color,
+			BackgroundTransparency = blockType.Transparency,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
+			create("UIStroke")({
+				Color = Color3.new(0, 0, 0),
+				Transparency = 0.6,
+				Thickness = 1,
+			}),
+		}),
+
+		-- Number key that selects this slot. Hidden when there is no keyboard, as on phones.
+		create("TextLabel")({
+			Name = "KeyHint",
+			Position = UDim2.fromOffset(4, 2),
+			Size = UDim2.fromOffset(16, 16),
+			BackgroundTransparency = 1,
+			Text = tostring(props.index),
+			TextColor3 = TEXT_COLOR,
+			TextStrokeTransparency = 0.4,
+			TextSize = 14,
+			Font = Enum.Font.GothamBold,
+			TextXAlignment = Enum.TextXAlignment.Left,
+			TextYAlignment = Enum.TextYAlignment.Top,
+			Visible = props.showKeyHints,
+		}),
+	})
+end
+
+local function Hotbar()
+	local selected = source(BlockPlacer.getBlockType())
+	local screenWidth = source(0)
+	local showKeyHints = source(UserInputService.KeyboardEnabled)
+
+	-- Follow selection changes made anywhere else, such as the number keys.
+	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
+		selected(name)
+	end))
+
+	cleanup(UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(function()
+		showKeyHints(UserInputService.KeyboardEnabled)
+	end))
+
+	local function select(name: string)
+		BlockPlacer.setBlockType(name)
+		-- BlockTypeChanged is deferred, so update now rather than a frame later.
+		selected(name)
+	end
+
+	local function scale(): number
+		local width = screenWidth()
+		if width <= 0 then
+			return 1
+		end
+		return math.clamp(width * MAX_WIDTH_FRACTION / BAR_WIDTH, MIN_SCALE, 1)
+	end
+
+	local slots = {}
+	for index, blockType in BlockTypes.List do
+		table.insert(
+			slots,
+			Slot({
+				blockType = blockType,
+				index = index,
+				selected = selected,
+				select = select,
+				showKeyHints = showKeyHints,
+			})
+		)
+	end
+
+	return create("ScreenGui")({
+		Name = "Hotbar",
+		-- Created by script, so it would be lost on respawn if this were left on.
+		ResetOnSpawn = false,
+		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
+		-- Keep clear of notches and the home indicator on phones.
+		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
+
+		changed("AbsoluteSize", function(size: Vector2)
+			screenWidth(size.X)
+		end),
+
+		create("Frame")({
+			Name = "Container",
+			AnchorPoint = Vector2.new(0.5, 1),
+			Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
+			Size = UDim2.fromOffset(BAR_WIDTH, BAR_HEIGHT + LABEL_GAP + LABEL_HEIGHT),
+			BackgroundTransparency = 1,
+
+			create("UIScale")({ Scale = scale }),
+
+			create("TextLabel")({
+				Name = "SelectedName",
+				Size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
+				BackgroundTransparency = 1,
+				Text = function()
+					local blockType = BlockTypes.ByName[selected()]
+					return if blockType then blockType.DisplayName else ""
+				end,
+				TextColor3 = TEXT_COLOR,
+				TextStrokeTransparency = 0.3,
+				TextSize = 20,
+				Font = Enum.Font.GothamBold,
+			}),
+
+			create("Frame")({
+				Name = "Bar",
+				AnchorPoint = Vector2.new(0, 1),
+				Position = UDim2.fromScale(0, 1),
+				Size = UDim2.fromOffset(BAR_WIDTH, BAR_HEIGHT),
+				BackgroundColor3 = BAR_COLOR,
+				BackgroundTransparency = 0.35,
+				BorderSizePixel = 0,
+				-- Sink clicks and taps in the gaps between slots so they don't place a block
+				-- in the world behind the bar.
+				Active = true,
+
+				create("UICorner")({ CornerRadius = UDim.new(0, 12) }),
+				create("UIPadding")({
+					PaddingTop = UDim.new(0, BAR_PADDING),
+					PaddingBottom = UDim.new(0, BAR_PADDING),
+					PaddingLeft = UDim.new(0, BAR_PADDING),
+					PaddingRight = UDim.new(0, BAR_PADDING),
+				}),
+				create("UIListLayout")({
+					FillDirection = Enum.FillDirection.Horizontal,
+					HorizontalAlignment = Enum.HorizontalAlignment.Center,
+					VerticalAlignment = Enum.VerticalAlignment.Center,
+					SortOrder = Enum.SortOrder.LayoutOrder,
+					Padding = UDim.new(0, SLOT_GAP),
+				}),
+
+				slots,
+			}),
+		}),
+	})
+end
+
+return Hotbar
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index d6fde35..f41b8a4 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,8 +1,15 @@
 local Players = game:GetService("Players")
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+
+local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local BlockPlacer = require(script.Parent.BlockPlacer)
+local Hotbar = require(script.Parent.Hotbar)
 
 local localPlayer = Players.LocalPlayer
 print(`client started for {localPlayer.Name}`)
 
+-- Mount the UI first: BlockPlacer.start() yields until the server's remote exists.
+Vide.mount(Hotbar, localPlayer:WaitForChild("PlayerGui"))
+
 BlockPlacer.start()

</attempt_a_diff>

## Attempt B

<attempt_b_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] A Luau file under src requires Vide
- [pass] The UI is started with Vide's mount or root
- [pass] No file under src builds a ScreenGui with Instance.new (the UI is built with Vide's create)
</attempt_b_checks>

<attempt_b_diff>
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index d6fde35..302d298 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,8 +1,25 @@
-local Players = game:GetService("Players")
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	Client entry point: mounts the HUD, then starts block placement.
+]]
 
-local BlockPlacer = require(script.Parent.BlockPlacer)
+const Players = game:GetService("Players")
+const RunService = game:GetService("RunService")
 
-local localPlayer = Players.LocalPlayer
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const BlockPlacer = require("./BlockPlacer")
+const headsUpDisplay = require("./UI/headsUpDisplay")
+
+Vide.strict = RunService:IsStudio()
+
+const localPlayer = Players.LocalPlayer
 print(`client started for {localPlayer.Name}`)
 
+const playerGui = localPlayer:WaitForChild("PlayerGui")
+Vide.mount(headsUpDisplay, playerGui)
+
+-- Yields until the server's remote exists, so it comes after the UI is up.
 BlockPlacer.start()
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
new file mode 100644
index 0000000..1b56df9
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
@@ -0,0 +1,122 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	Facts about the player's screen, as Vide sources: how much the whole UI
+	grows, the viewport in UI units, and whether the touch layout applies.
+	UI binds to these so it follows window resizes and device switches live.
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
+-- UI sizes are authored for a screen this many pixels on its short side.
+const REFERENCE_SHORT_SIDE = 1080
+const MINIMUM_SCALE = 1
+const MAXIMUM_SCALE = 3
+-- TVs are read from a couch.
+const LARGE_DISPLAY_BOOST = 1.25
+-- In UI units. Phones held sideways are 360 to 440 tall, tablets start near 600.
+const PHONE_SHORT_SIDE = 600
+const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)
+
+local Module = {}
+
+local realViewport = source(FALLBACK_VIEWPORT)
+local prefersTouch = source(false)
+local prefersKeyboard = source(true)
+local isLargeDisplay = source(false)
+local viewportConnection: RBXScriptConnection? = nil
+
+local function refresh()
+	local camera = workspace.CurrentCamera
+	batch(function()
+		-- ViewportSize can read (1, 1) before the first frame, which would
+		-- pass for a tiny phone.
+		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
+			realViewport(camera.ViewportSize)
+		end
+		prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
+		prefersKeyboard(UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse)
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
+	How much the whole UI grows on this screen. Bind it to a UIScale under
+	every ScreenGui the game builds.
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
+	Whether touch is the primary input, which is when Roblox shows its touch
+	controls.
+]]
+function Module.isTouch(): boolean
+	return prefersTouch()
+end
+
+--[[
+	Whether keyboard and mouse is the primary input, so keyboard shortcuts are
+	worth showing.
+]]
+function Module.isKeyboard(): boolean
+	return prefersKeyboard()
+end
+
+function Module.isPhone(): boolean
+	const view = Module.viewport()
+	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
+end
+
+--[[
+	Whether a HUD should use its touch layout: the touch controls are up, or
+	the screen is too small for the desktop layout.
+]]
+function Module.isTouchLayout(): boolean
+	return prefersTouch() or Module.isPhone()
+end
+
+-- Connections would outlive the fresh module copies that edit-mode tools load.
+if RunService:IsRunning() then
+	watchCamera()
+	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
+	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
+	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
+else
+	refresh()
+end
+
+return Module
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/headsUpDisplay.luau b/src/StarterPlayer/StarterPlayerScripts/UI/headsUpDisplay.luau
new file mode 100644
index 0000000..21e1075
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/headsUpDisplay.luau
@@ -0,0 +1,56 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	The in-game HUD: the block hotbar, wired to BlockPlacer. Selecting a slot
+	sets BlockPlacer's block type, and any change there (number keys included)
+	moves the highlight, so BlockPlacer stays the one owner of the selection.
+]]
+
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const cleanup = Vide.cleanup
+const create = Vide.create
+const source = Vide.source
+
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+
+const BlockPlacer = require("../BlockPlacer")
+const hotbar = require("./hotbar")
+const Screen = require("./Screen")
+
+-- Desktop sits at the bottom center. Touch moves to the top center, clear of
+-- the thumbstick region (lower left) and the jump button (lower right).
+const DESKTOP_ANCHOR = Vector2.new(0.5, 1)
+const DESKTOP_POSITION = UDim2.new(0.5, 0, 1, -16)
+const TOUCH_ANCHOR = Vector2.new(0.5, 0)
+const TOUCH_POSITION = UDim2.new(0.5, 0, 0, 8)
+
+local function headsUpDisplay(): ScreenGui
+	const selectedName = source(BlockPlacer.getBlockType())
+	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
+		selectedName(name)
+	end))
+
+	return create("ScreenGui")({
+		Name = "HeadsUpDisplay",
+
+		create("UIScale")({ Scale = Screen.uiScale }),
+
+		hotbar({
+			BlockTypes = BlockTypes.List,
+			SelectedName = selectedName,
+			Select = BlockPlacer.setBlockType,
+			IsCompact = Screen.isTouchLayout,
+			ShowsKeyHints = Screen.isKeyboard,
+			AnchorPoint = function()
+				return if Screen.isTouchLayout() then TOUCH_ANCHOR else DESKTOP_ANCHOR
+			end,
+			Position = function()
+				return if Screen.isTouchLayout() then TOUCH_POSITION else DESKTOP_POSITION
+			end,
+		}),
+	})
+end
+
+return headsUpDisplay
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/hotbar.luau b/src/StarterPlayer/StarterPlayerScripts/UI/hotbar.luau
new file mode 100644
index 0000000..efab6fe
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/hotbar.luau
@@ -0,0 +1,242 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	A row of block slots: each shows its block's color and name, the selected
+	one is outlined, and clicking or tapping a slot selects it. The caller
+	owns the selection and passes it in, so the row stays a plain view.
+]]
+
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const create = Vide.create
+const derive = Vide.derive
+const read = Vide.read
+
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+
+type BlockType = BlockTypes.BlockType
+
+export type HotbarProps = {
+	BlockTypes: { BlockType },
+	SelectedName: () -> string,
+	Select: (name: string) -> (),
+	-- The touch-sized variant, for phones and small windows.
+	IsCompact: (boolean | () -> boolean)?,
+	-- Number labels for the keys 1 to 5, for players on keyboard and mouse.
+	ShowsKeyHints: (boolean | () -> boolean)?,
+	AnchorPoint: (Vector2 | () -> Vector2)?,
+	Position: (UDim2 | () -> UDim2)?,
+}
+
+type Metrics = {
+	SlotSize: number,
+	Gap: number,
+	CornerRadius: number,
+	SwatchSize: number,
+	SwatchTop: number,
+	NameTop: number,
+	NameHeight: number,
+	NameTextSize: number,
+}
+
+type SlotProps = {
+	BlockType: BlockType,
+	Index: number,
+	IsSelected: () -> boolean,
+	Metrics: () -> Metrics,
+	ShowsKeyHints: (boolean | () -> boolean)?,
+	Select: (name: string) -> (),
+}
+
+-- Slots stay above 44 so a thumb can hit them. Each column sums to SlotSize:
+-- SwatchTop + SwatchSize + gap + NameHeight + bottom margin.
+const REGULAR: Metrics = table.freeze({
+	SlotSize = 72,
+	Gap = 8,
+	CornerRadius = 10,
+	SwatchSize = 40,
+	SwatchTop = 8,
+	NameTop = 50,
+	NameHeight = 18,
+	NameTextSize = 16,
+})
+const COMPACT: Metrics = table.freeze({
+	SlotSize = 56,
+	Gap = 6,
+	CornerRadius = 8,
+	SwatchSize = 30,
+	SwatchTop = 6,
+	NameTop = 37,
+	NameHeight = 16,
+	NameTextSize = 14,
+})
+
+const BAR_COLOR = Color3.fromRGB(20, 20, 24)
+const BAR_TRANSPARENCY = 0.35
+const SLOT_COLOR = Color3.fromRGB(40, 40, 46)
+const SELECTED_SLOT_COLOR = Color3.fromRGB(78, 78, 88)
+const SELECTED_STROKE_COLOR = Color3.fromRGB(255, 255, 255)
+-- Below Gap, so the outline never reaches a neighbor or the bar's edge.
+const SELECTED_STROKE_THICKNESS = 3
+const SWATCH_CORNER_RADIUS = 6
+const SWATCH_EDGE_COLOR = Color3.fromRGB(0, 0, 0)
+const SWATCH_EDGE_TRANSPARENCY = 0.6
+-- A see-through block drawn at full transparency vanishes into the dark slot.
+const SWATCH_TRANSPARENCY_FACTOR = 0.5
+const NAME_COLOR = Color3.fromRGB(255, 255, 255)
+const KEY_HINT_COLOR = Color3.fromRGB(190, 190, 200)
+const KEY_HINT_TEXT_SIZE = 12
+-- Stays left of the smallest swatch's edge in both variants.
+const KEY_HINT_POSITION = UDim2.fromOffset(3, 2)
+const KEY_HINT_SIZE = UDim2.fromOffset(9, 14)
+const FONT = Enum.Font.BuilderSansBold
+
+local function slot(props: SlotProps): TextButton
+	const blockType = props.BlockType
+	const metrics = props.Metrics
+
+	return create("TextButton")({
+		Name = blockType.Name,
+		LayoutOrder = props.Index,
+		Size = function()
+			const size = metrics().SlotSize
+			return UDim2.fromOffset(size, size)
+		end,
+		BackgroundColor3 = function()
+			return if props.IsSelected() then SELECTED_SLOT_COLOR else SLOT_COLOR
+		end,
+
+		Activated = function()
+			props.Select(blockType.Name)
+		end,
+
+		create("UICorner")({
+			CornerRadius = function()
+				return UDim.new(0, metrics().CornerRadius)
+			end,
+		}),
+
+		-- Border mode, since a stroke on a TextButton outlines its text by default.
+		create("UIStroke")({
+			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+			Color = SELECTED_STROKE_COLOR,
+			Thickness = SELECTED_STROKE_THICKNESS,
+			Transparency = function()
+				return if props.IsSelected() then 0 else 1
+			end,
+		}),
+
+		create("Frame")({
+			Name = "Swatch",
+			AnchorPoint = Vector2.new(0.5, 0),
+			Position = function()
+				return UDim2.new(0.5, 0, 0, metrics().SwatchTop)
+			end,
+			Size = function()
+				const size = metrics().SwatchSize
+				return UDim2.fromOffset(size, size)
+			end,
+			BackgroundColor3 = blockType.Color,
+			BackgroundTransparency = blockType.Transparency * SWATCH_TRANSPARENCY_FACTOR,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, SWATCH_CORNER_RADIUS) }),
+			create("UIStroke")({
+				Color = SWATCH_EDGE_COLOR,
+				Transparency = SWATCH_EDGE_TRANSPARENCY,
+			}),
+		}),
+
+		create("TextLabel")({
+			Name = "BlockName",
+			BackgroundTransparency = 1,
+			Position = function()
+				return UDim2.fromOffset(2, metrics().NameTop)
+			end,
+			Size = function()
+				return UDim2.new(1, -4, 0, metrics().NameHeight)
+			end,
+			Font = FONT,
+			Text = blockType.DisplayName,
+			TextColor3 = NAME_COLOR,
+			TextSize = function()
+				return metrics().NameTextSize
+			end,
+			TextTruncate = Enum.TextTruncate.AtEnd,
+		}),
+
+		create("TextLabel")({
+			Name = "KeyHint",
+			BackgroundTransparency = 1,
+			Position = KEY_HINT_POSITION,
+			Size = KEY_HINT_SIZE,
+			Font = FONT,
+			Text = tostring(props.Index),
+			TextColor3 = KEY_HINT_COLOR,
+			TextSize = KEY_HINT_TEXT_SIZE,
+			TextXAlignment = Enum.TextXAlignment.Left,
+			Visible = props.ShowsKeyHints or false,
+		}),
+	})
+end
+
+local function hotbar(props: HotbarProps): Frame
+	const metrics = derive(function(): Metrics
+		return if read(props.IsCompact) then COMPACT else REGULAR
+	end)
+
+	const slots = {}
+	for index, blockType in props.BlockTypes do
+		const isSelected = derive(function()
+			return props.SelectedName() == blockType.Name
+		end)
+		table.insert(
+			slots,
+			slot({
+				BlockType = blockType,
+				Index = index,
+				IsSelected = isSelected,
+				Metrics = metrics,
+				ShowsKeyHints = props.ShowsKeyHints,
+				Select = props.Select,
+			})
+		)
+	end
+
+	local function padding(): UDim
+		return UDim.new(0, metrics().Gap)
+	end
+
+	return create("Frame")({
+		Name = "Hotbar",
+		AnchorPoint = props.AnchorPoint or Vector2.zero,
+		Position = props.Position or UDim2.new(),
+		-- A Frame starts at 100 by 100, and AutomaticSize only grows.
+		Size = UDim2.new(),
+		AutomaticSize = Enum.AutomaticSize.XY,
+		BackgroundColor3 = BAR_COLOR,
+		BackgroundTransparency = BAR_TRANSPARENCY,
+		-- Sinks presses in the gaps between slots, so they never place a block.
+		Active = true,
+
+		create("UICorner")({
+			CornerRadius = function()
+				return UDim.new(0, metrics().CornerRadius + metrics().Gap)
+			end,
+		}),
+		create("UIPadding")({
+			PaddingTop = padding,
+			PaddingBottom = padding,
+			PaddingLeft = padding,
+			PaddingRight = padding,
+		}),
+		create("UIListLayout")({
+			FillDirection = Enum.FillDirection.Horizontal,
+			Padding = padding,
+		}),
+
+		slots,
+	})
+end
+
+return hotbar

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
