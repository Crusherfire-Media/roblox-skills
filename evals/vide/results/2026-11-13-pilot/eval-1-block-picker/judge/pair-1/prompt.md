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
diff --git a/src/ServerScriptService/Stories/Game.storybook.luau b/src/ServerScriptService/Stories/Game.storybook.luau
new file mode 100644
index 0000000..2819488
--- /dev/null
+++ b/src/ServerScriptService/Stories/Game.storybook.luau
@@ -0,0 +1,14 @@
+--!strict
+--@author: Crusherfire
+--@date: 11/13/2026
+--[[@description:
+	UI Labs storybook for the game's UI. Studio-only: nothing in the game
+	requires this folder.
+]]
+
+const ServerScriptService = game:GetService("ServerScriptService")
+
+return {
+	name = "Game UI",
+	storyRoots = { ServerScriptService.Stories },
+}
diff --git a/src/ServerScriptService/Stories/Hotbar.story.luau b/src/ServerScriptService/Stories/Hotbar.story.luau
new file mode 100644
index 0000000..580ec3b
--- /dev/null
+++ b/src/ServerScriptService/Stories/Hotbar.story.luau
@@ -0,0 +1,48 @@
+--!strict
+--@author: Crusherfire
+--@date: 11/13/2026
+--[[@description:
+	The block hotbar with every block type. Pressing a slot selects it, as in
+	game.
+]]
+
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const source = Vide.source
+
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+const Hotbar = require("@game/StarterPlayer/StarterPlayerScripts/Hotbar")
+
+type StoryProps = {
+	controls: {
+		-- Off is how touch players see it.
+		ShowKeyHints: () -> boolean,
+	},
+	target: Frame,
+}
+
+const CONTROLS = {
+	ShowKeyHints = true,
+}
+
+local function story(props: StoryProps)
+	const selectedName = source(BlockTypes.List[1].Name)
+
+	return Hotbar({
+		BlockTypes = BlockTypes.List,
+		SelectedName = selectedName,
+		ShowKeyHints = props.controls.ShowKeyHints,
+		Select = function(name: string)
+			selectedName(name)
+		end,
+		AnchorPoint = Vector2.new(0.5, 0.5),
+		Position = UDim2.fromScale(0.5, 0.5),
+	})
+end
+
+return {
+	summary = "The block hotbar. Press a slot to select it.",
+	vide = Vide,
+	controls = CONTROLS,
+	story = story,
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
new file mode 100644
index 0000000..87e1b98
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
@@ -0,0 +1,158 @@
+--!strict
+--@author: Crusherfire
+--@date: 11/13/2026
+--[[@description:
+	A row of block slots: each shows the block's color and name, the selected
+	slot is outlined, and clicking or tapping a slot asks to select it.
+]]
+
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const create = Vide.create
+
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+
+export type HotbarProps = {
+	BlockTypes: { BlockTypes.BlockType },
+	SelectedName: () -> string,
+	ShowKeyHints: boolean | () -> boolean,
+	Select: (name: string) -> (),
+	AnchorPoint: Vector2?,
+	Position: UDim2?,
+}
+
+-- 64 keeps every slot well over the 44 a thumb needs.
+const SLOT_SIZE = 64
+const SLOT_GAP = 8
+const SLOT_RADIUS = 10
+const SWATCH_INSET = 6
+const SWATCH_RADIUS = SLOT_RADIUS - SWATCH_INSET
+const SWATCH_HEIGHT = 34
+const NAME_TOP = SWATCH_INSET + SWATCH_HEIGHT + 2
+const NAME_HEIGHT = 18
+const NAME_TEXT_SIZE = 14
+const KEY_HINT_SIZE = 14
+const KEY_HINT_TEXT_SIZE = 13
+-- Outer padding is wider than the stroke, so the outline is never cut off.
+const BAR_PADDING = 8
+const BAR_RADIUS = SLOT_RADIUS + BAR_PADDING
+const SELECTED_STROKE = 3
+
+const BAR_COLOR = Color3.fromRGB(0, 0, 0)
+const BAR_TRANSPARENCY = 0.4
+const SLOT_COLOR = Color3.fromRGB(35, 35, 40)
+const SELECTED_SLOT_COLOR = Color3.fromRGB(75, 75, 85)
+const TEXT_COLOR = Color3.fromRGB(255, 255, 255)
+const FONT = Enum.Font.BuilderSansBold
+
+local function slot(props: {
+	BlockType: BlockTypes.BlockType,
+	KeyNumber: number,
+	IsSelected: () -> boolean,
+	ShowKeyHints: boolean | () -> boolean,
+	Select: (name: string) -> (),
+}): TextButton
+	const blockType = props.BlockType
+
+	return create("TextButton")({
+		Name = blockType.Name,
+		LayoutOrder = props.KeyNumber,
+		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
+		BackgroundColor3 = function()
+			return if props.IsSelected() then SELECTED_SLOT_COLOR else SLOT_COLOR
+		end,
+		Text = "",
+		Activated = function()
+			props.Select(blockType.Name)
+		end,
+
+		create("UICorner")({ CornerRadius = UDim.new(0, SLOT_RADIUS) }),
+		create("UIStroke")({
+			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+			Color = TEXT_COLOR,
+			Thickness = SELECTED_STROKE,
+			Transparency = function()
+				return if props.IsSelected() then 0 else 1
+			end,
+		}),
+
+		create("Frame")({
+			Name = "Swatch",
+			Position = UDim2.fromOffset(SWATCH_INSET, SWATCH_INSET),
+			Size = UDim2.new(1, -2 * SWATCH_INSET, 0, SWATCH_HEIGHT),
+			BackgroundColor3 = blockType.Color,
+			BackgroundTransparency = blockType.Transparency,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, SWATCH_RADIUS) }),
+
+			create("TextLabel")({
+				Name = "KeyHint",
+				Position = UDim2.fromOffset(2, 1),
+				Size = UDim2.fromOffset(KEY_HINT_SIZE, KEY_HINT_SIZE),
+				BackgroundTransparency = 1,
+				Font = FONT,
+				Text = tostring(props.KeyNumber),
+				TextColor3 = TEXT_COLOR,
+				TextSize = KEY_HINT_TEXT_SIZE,
+				TextStrokeTransparency = 0.3,
+				Visible = props.ShowKeyHints,
+			}),
+		}),
+
+		create("TextLabel")({
+			Name = "BlockName",
+			Position = UDim2.fromOffset(0, NAME_TOP),
+			Size = UDim2.new(1, 0, 0, NAME_HEIGHT),
+			BackgroundTransparency = 1,
+			Font = FONT,
+			Text = blockType.DisplayName,
+			TextColor3 = TEXT_COLOR,
+			TextSize = NAME_TEXT_SIZE,
+			TextTruncate = Enum.TextTruncate.AtEnd,
+		}),
+	})
+end
+
+local function hotbar(props: HotbarProps): Frame
+	const slots = {}
+	for index, blockType in props.BlockTypes do
+		table.insert(
+			slots,
+			slot({
+				BlockType = blockType,
+				KeyNumber = index,
+				IsSelected = function()
+					return props.SelectedName() == blockType.Name
+				end,
+				ShowKeyHints = props.ShowKeyHints,
+				Select = props.Select,
+			})
+		)
+	end
+
+	return create("Frame")({
+		Name = "Hotbar",
+		AnchorPoint = props.AnchorPoint,
+		Position = props.Position,
+		Size = UDim2.new(),
+		AutomaticSize = Enum.AutomaticSize.XY,
+		BackgroundColor3 = BAR_COLOR,
+		BackgroundTransparency = BAR_TRANSPARENCY,
+
+		create("UICorner")({ CornerRadius = UDim.new(0, BAR_RADIUS) }),
+		create("UIPadding")({
+			PaddingLeft = UDim.new(0, BAR_PADDING),
+			PaddingRight = UDim.new(0, BAR_PADDING),
+			PaddingTop = UDim.new(0, BAR_PADDING),
+			PaddingBottom = UDim.new(0, BAR_PADDING),
+		}),
+		create("UIListLayout")({
+			FillDirection = Enum.FillDirection.Horizontal,
+			Padding = UDim.new(0, SLOT_GAP),
+		}),
+
+		slots,
+	})
+end
+
+return hotbar
diff --git a/src/StarterPlayer/StarterPlayerScripts/HotbarGui.luau b/src/StarterPlayer/StarterPlayerScripts/HotbarGui.luau
new file mode 100644
index 0000000..845f997
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/HotbarGui.luau
@@ -0,0 +1,48 @@
+--!strict
+--@author: Crusherfire
+--@date: 11/13/2026
+--[[@description:
+	The hotbar ScreenGui: connects the hotbar to BlockPlacer, so it shows the
+	selected block type however it was chosen and selects the slot pressed.
+]]
+
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const cleanup = Vide.cleanup
+const create = Vide.create
+const source = Vide.source
+
+const BlockPlacer = require("./BlockPlacer")
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+const Hotbar = require("./Hotbar")
+const Screen = require("./Screen")
+
+const BOTTOM_CENTER = Vector2.new(0.5, 1)
+const HOTBAR_POSITION = UDim2.new(0.5, 0, 1, -16)
+
+local function hotbarGui(): ScreenGui
+	const selectedName = source(BlockPlacer.getBlockType())
+
+	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
+		selectedName(name)
+	end))
+
+	return create("ScreenGui")({
+		Name = "Hotbar",
+
+		create("UIScale")({ Scale = Screen.uiScale }),
+
+		Hotbar({
+			BlockTypes = BlockTypes.List,
+			SelectedName = selectedName,
+			ShowKeyHints = function()
+				return not Screen.isTouch()
+			end,
+			Select = BlockPlacer.setBlockType,
+			AnchorPoint = BOTTOM_CENTER,
+			Position = HOTBAR_POSITION,
+		}),
+	})
+end
+
+return hotbarGui
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index d6fde35..ac56752 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,8 +1,17 @@
-local Players = game:GetService("Players")
+const Players = game:GetService("Players")
+const RunService = game:GetService("RunService")
 
-local BlockPlacer = require(script.Parent.BlockPlacer)
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const BlockPlacer = require("./BlockPlacer")
+const HotbarGui = require("./HotbarGui")
+
+Vide.strict = RunService:IsStudio()
 
 local localPlayer = Players.LocalPlayer
 print(`client started for {localPlayer.Name}`)
 
+local playerGui = localPlayer:WaitForChild("PlayerGui")
+Vide.mount(HotbarGui, playerGui)
+
 BlockPlacer.start()
diff --git a/src/StarterPlayer/StarterPlayerScripts/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/Screen.luau
new file mode 100644
index 0000000..b92e758
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Screen.luau
@@ -0,0 +1,87 @@
+--!strict
+--@author: Crusherfire
+--@date: 11/13/2026
+--[[@description:
+	Facts about the player's screen, as Vide sources, so UI follows a window
+	resize, a device switch, or a change of primary input while it is up.
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
+-- UI is authored for a screen 1080 pixels tall and grows on taller ones.
+const REFERENCE_SHORT_SIDE = 1080
+const MINIMUM_SCALE = 1
+const MAXIMUM_SCALE = 3
+const LARGE_DISPLAY_BOOST = 1.25
+const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)
+
+local Module = {}
+
+local realViewport = source(FALLBACK_VIEWPORT)
+local prefersTouch = source(false)
+local isLargeDisplay = source(false)
+local viewportConnection: RBXScriptConnection? = nil
+
+local function refresh()
+	local camera = workspace.CurrentCamera
+	batch(function()
+		-- ViewportSize can read (1, 1) before the first frame, so the fallback
+		-- stays until a real size arrives.
+		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
+			realViewport(camera.ViewportSize)
+		end
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
+	How much the whole UI grows on this screen. Bind it to a UIScale directly
+	under every ScreenGui the game builds.
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
+	Whether touch is the primary input, which is when Roblox shows its touch
+	controls.
+]]
+function Module.isTouch(): boolean
+	return prefersTouch()
+end
+
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
diff --git a/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
new file mode 100644
index 0000000..28e74ec
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
@@ -0,0 +1,206 @@
+--[[
+	Hotbar UI built with Vide. Shows every block type from BlockTypes in hotbar order, highlights the
+	one BlockPlacer has selected, and selects a block type when its slot is clicked or tapped.
+
+	The selection lives in BlockPlacer; the hotbar mirrors it through BlockPlacer.BlockTypeChanged, so
+	switching with the number keys (or any other caller of setBlockType) updates the highlight too.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local UserInputService = game:GetService("UserInputService")
+
+local Vide = require(ReplicatedStorage.Packages.Vide)
+local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local BlockPlacer = require(script.Parent.BlockPlacer)
+
+local create = Vide.create
+local source = Vide.source
+local cleanup = Vide.cleanup
+local changed = Vide.changed
+
+-- Slots are sized from the screen so they stay comfortable to tap on phones without being huge on PC.
+-- 44 px is the smallest touch target worth allowing.
+local MIN_SLOT_SIZE = 44
+local MAX_SLOT_SIZE = 68
+local SLOT_SCREEN_FRACTION = 0.13
+local SLOT_GAP = 6
+local BAR_PADDING = 6
+local BOTTOM_MARGIN = 12
+
+local BAR_COLOR = Color3.fromRGB(20, 20, 24)
+local SLOT_COLOR = Color3.fromRGB(45, 45, 52)
+local SELECTED_SLOT_COLOR = Color3.fromRGB(70, 70, 80)
+local SELECTED_STROKE_COLOR = Color3.fromRGB(255, 220, 90)
+local IDLE_STROKE_COLOR = Color3.fromRGB(90, 90, 100)
+local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
+
+type Props = {
+	blockType: BlockTypes.BlockType,
+	index: number,
+	selected: () -> string,
+	slotSize: () -> number,
+	showKeyHint: boolean,
+}
+
+local function Slot(props: Props)
+	local blockType = props.blockType
+	local function isSelected(): boolean
+		return props.selected() == blockType.Name
+	end
+
+	return create("TextButton")({
+		Name = blockType.Name,
+		LayoutOrder = props.index,
+		Size = function()
+			local size = props.slotSize()
+			return UDim2.fromOffset(size, size)
+		end,
+		AutoButtonColor = false,
+		Text = "",
+		BorderSizePixel = 0,
+		BackgroundColor3 = function()
+			return if isSelected() then SELECTED_SLOT_COLOR else SLOT_COLOR
+		end,
+
+		Activated = function()
+			BlockPlacer.setBlockType(blockType.Name)
+		end,
+
+		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
+		create("UIStroke")({
+			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+			Color = function()
+				return if isSelected() then SELECTED_STROKE_COLOR else IDLE_STROKE_COLOR
+			end,
+			Thickness = function()
+				return if isSelected() then 3 else 1
+			end,
+		}),
+
+		-- Colour swatch for the block.
+		create("Frame")({
+			Name = "Swatch",
+			AnchorPoint = Vector2.new(0.5, 0),
+			Position = UDim2.fromScale(0.5, 0.12),
+			Size = UDim2.fromScale(0.52, 0.52),
+			BackgroundColor3 = blockType.Color,
+			BackgroundTransparency = blockType.Transparency,
+			BorderSizePixel = 0,
+			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
+			create("UIStroke")({
+				Color = Color3.new(0, 0, 0),
+				Transparency = 0.5,
+				Thickness = 1,
+			}),
+		}),
+
+		create("TextLabel")({
+			Name = "Label",
+			AnchorPoint = Vector2.new(0.5, 1),
+			Position = UDim2.fromScale(0.5, 0.95),
+			Size = UDim2.fromScale(0.92, 0.24),
+			BackgroundTransparency = 1,
+			Text = blockType.DisplayName,
+			TextColor3 = TEXT_COLOR,
+			FontFace = Font.fromEnum(Enum.Font.GothamMedium),
+			TextScaled = true,
+			create("UITextSizeConstraint")({ MaxTextSize = 14 }),
+		}),
+
+		-- Number key hint, only on devices with a keyboard.
+		if props.showKeyHint
+			then create("TextLabel")({
+				Name = "KeyHint",
+				Position = UDim2.fromOffset(4, 2),
+				Size = UDim2.fromOffset(12, 12),
+				BackgroundTransparency = 1,
+				Text = tostring(props.index),
+				TextColor3 = TEXT_COLOR,
+				TextTransparency = 0.3,
+				FontFace = Font.fromEnum(Enum.Font.GothamBold),
+				TextSize = 11,
+				TextXAlignment = Enum.TextXAlignment.Left,
+				TextYAlignment = Enum.TextYAlignment.Top,
+			})
+			else nil,
+	})
+end
+
+local function Hotbar()
+	-- Mirror BlockPlacer's selection into a source.
+	local selected = source(BlockPlacer.getBlockType())
+	local connection = BlockPlacer.BlockTypeChanged:Connect(function(name: string)
+		selected(name)
+	end)
+	cleanup(function()
+		connection:Disconnect()
+	end)
+
+	local screenSize = source(Vector2.new(800, 600))
+	local function slotSize(): number
+		local size = screenSize()
+		local shortest = math.min(size.X, size.Y)
+		return math.clamp(math.floor(shortest * SLOT_SCREEN_FRACTION), MIN_SLOT_SIZE, MAX_SLOT_SIZE)
+	end
+
+	local showKeyHint = UserInputService.KeyboardEnabled
+
+	local slots = {}
+	for index, blockType in BlockTypes.List do
+		slots[index] = Slot({
+			blockType = blockType,
+			index = index,
+			selected = selected,
+			slotSize = slotSize,
+			showKeyHint = showKeyHint,
+		})
+	end
+
+	return create("ScreenGui")({
+		Name = "Hotbar",
+		ResetOnSpawn = false,
+		IgnoreGuiInset = false,
+		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
+		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
+		changed("AbsoluteSize", screenSize),
+
+		create("Frame")({
+			Name = "Bar",
+			AnchorPoint = Vector2.new(0.5, 1),
+			Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
+			AutomaticSize = Enum.AutomaticSize.XY,
+			Size = UDim2.fromOffset(0, 0),
+			BackgroundColor3 = BAR_COLOR,
+			BackgroundTransparency = 0.35,
+			BorderSizePixel = 0,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, 10) }),
+			create("UIPadding")({
+				PaddingTop = UDim.new(0, BAR_PADDING),
+				PaddingBottom = UDim.new(0, BAR_PADDING),
+				PaddingLeft = UDim.new(0, BAR_PADDING),
+				PaddingRight = UDim.new(0, BAR_PADDING),
+			}),
+			create("UIListLayout")({
+				FillDirection = Enum.FillDirection.Horizontal,
+				HorizontalAlignment = Enum.HorizontalAlignment.Center,
+				VerticalAlignment = Enum.VerticalAlignment.Center,
+				SortOrder = Enum.SortOrder.LayoutOrder,
+				Padding = UDim.new(0, SLOT_GAP),
+			}),
+
+			slots,
+		}),
+	})
+end
+
+--[[
+	Mounts the hotbar into the given PlayerGui. Returns a function that unmounts it.
+]]
+local function mount(playerGui: Instance): () -> ()
+	return Vide.mount(Hotbar, playerGui)
+end
+
+return {
+	mount = mount,
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index d6fde35..cd8b3da 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,8 +1,12 @@
 local Players = game:GetService("Players")
 
 local BlockPlacer = require(script.Parent.BlockPlacer)
+local Hotbar = require(script.Parent.Hotbar)
 
 local localPlayer = Players.LocalPlayer
 print(`client started for {localPlayer.Name}`)
 
+-- Mount UI before BlockPlacer.start(), which yields until the server's remote exists.
+Hotbar.mount(localPlayer:WaitForChild("PlayerGui"))
+
 BlockPlacer.start()

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
