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
diff --git a/src/ServerScriptService/Stories/BlockHotbar.story.luau b/src/ServerScriptService/Stories/BlockHotbar.story.luau
new file mode 100644
index 0000000..4984876
--- /dev/null
+++ b/src/ServerScriptService/Stories/BlockHotbar.story.luau
@@ -0,0 +1,40 @@
+--!strict
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+local source = Vide.source
+
+local BlockHotbar = require("@game/StarterPlayer/StarterPlayerScripts/BlockHotbar")
+local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+
+local CONTROLS = {
+	-- Off shows the hotbar as a touch player sees it.
+	ShowKeyHints = true,
+}
+
+type StoryProps = {
+	controls: {
+		ShowKeyHints: () -> boolean,
+	},
+	target: Frame,
+}
+
+local function story(props: StoryProps)
+	local selected = source(BlockTypes.List[1].Name)
+
+	return BlockHotbar({
+		BlockTypes = BlockTypes.List,
+		Selected = selected,
+		Select = function(name: string)
+			print(`selected {name}`)
+			selected(name)
+		end,
+		ShowKeyHints = props.controls.ShowKeyHints,
+	})
+end
+
+return {
+	summary = "The block hotbar. Press a slot to select it.",
+	vide = Vide,
+	controls = CONTROLS,
+	story = story,
+}
diff --git a/src/ServerScriptService/Stories/GameUI.storybook.luau b/src/ServerScriptService/Stories/GameUI.storybook.luau
new file mode 100644
index 0000000..8d952dd
--- /dev/null
+++ b/src/ServerScriptService/Stories/GameUI.storybook.luau
@@ -0,0 +1,7 @@
+--!strict
+local ServerScriptService = game:GetService("ServerScriptService")
+
+return {
+	name = "Game UI",
+	storyRoots = { ServerScriptService.Stories },
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockHotbar.luau b/src/StarterPlayer/StarterPlayerScripts/BlockHotbar.luau
new file mode 100644
index 0000000..831fd83
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockHotbar.luau
@@ -0,0 +1,178 @@
+--!strict
+--[[
+	A row of block slots, one per block type, with the selected one
+	highlighted. Pressing a slot calls Select with that block type's name.
+]]
+
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+local create = Vide.create
+local source = Vide.source
+
+-- 64 keeps every slot well over the 44 a thumb needs.
+local SLOT_SIZE = 64
+-- Wider than both selected strokes together, so neighbors never touch.
+local SLOT_GAP = 8
+local SLOT_CORNER = UDim.new(0, 10)
+local SLOT_TRANSPARENCY = 0.25
+local BOTTOM_MARGIN = 16
+
+local SWATCH_SIZE = 32
+local SWATCH_TOP = 6
+local SWATCH_CORNER = UDim.new(0, 6)
+
+local LABEL_HEIGHT = 16
+local LABEL_BOTTOM = 5
+local LABEL_TEXT_SIZE = 13
+local KEY_HINT_TEXT_SIZE = 12
+local KEY_HINT_POSITION = UDim2.fromOffset(5, 3)
+local KEY_HINT_SIZE = UDim2.fromOffset(10, 14)
+
+local SELECTED_STROKE_THICKNESS = 3
+local IDLE_STROKE_THICKNESS = 1
+
+local IDLE_COLOR = Color3.fromRGB(28, 30, 36)
+local HOVER_COLOR = Color3.fromRGB(48, 52, 62)
+local SELECTED_COLOR = Color3.fromRGB(70, 76, 92)
+local IDLE_STROKE_COLOR = Color3.fromRGB(90, 96, 110)
+local SELECTED_STROKE_COLOR = Color3.fromRGB(255, 255, 255)
+local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
+local KEY_HINT_COLOR = Color3.fromRGB(190, 196, 210)
+local FONT = Enum.Font.BuilderSansBold
+
+local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+
+type BlockType = BlockTypes.BlockType
+
+type SlotProps = {
+	BlockType: BlockType,
+	KeyHint: string,
+	LayoutOrder: number,
+	IsSelected: () -> boolean,
+	ShowKeyHint: boolean | () -> boolean,
+	Select: () -> (),
+}
+
+export type BlockHotbarProps = {
+	BlockTypes: { BlockType },
+	Selected: () -> string,
+	Select: (name: string) -> (),
+	-- Number key hints, which mean nothing to a player on touch.
+	ShowKeyHints: boolean | () -> boolean,
+}
+
+local function slot(props: SlotProps): TextButton
+	local blockType = props.BlockType
+	local isHovered = source(false)
+
+	return create("TextButton")({
+		Name = blockType.Name,
+		LayoutOrder = props.LayoutOrder,
+		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
+		BackgroundColor3 = function()
+			if props.IsSelected() then
+				return SELECTED_COLOR
+			end
+			return if isHovered() then HOVER_COLOR else IDLE_COLOR
+		end,
+		BackgroundTransparency = SLOT_TRANSPARENCY,
+		Activated = props.Select,
+		MouseEnter = function()
+			isHovered(true)
+		end,
+		MouseLeave = function()
+			isHovered(false)
+		end,
+
+		create("UICorner")({ CornerRadius = SLOT_CORNER }),
+		create("UIStroke")({
+			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+			Color = function()
+				return if props.IsSelected() then SELECTED_STROKE_COLOR else IDLE_STROKE_COLOR
+			end,
+			Thickness = function()
+				return if props.IsSelected()
+					then SELECTED_STROKE_THICKNESS
+					else IDLE_STROKE_THICKNESS
+			end,
+		}),
+
+		create("Frame")({
+			Name = "Swatch",
+			AnchorPoint = Vector2.new(0.5, 0),
+			Position = UDim2.new(0.5, 0, 0, SWATCH_TOP),
+			Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),
+			BackgroundColor3 = blockType.Color,
+			BackgroundTransparency = blockType.Transparency,
+
+			create("UICorner")({ CornerRadius = SWATCH_CORNER }),
+			-- Outlines see-through blocks such as Window, which would otherwise
+			-- fade into the slot.
+			create("UIStroke")({
+				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+				Color = blockType.Color,
+				Thickness = IDLE_STROKE_THICKNESS,
+			}),
+		}),
+
+		create("TextLabel")({
+			Name = "Label",
+			AnchorPoint = Vector2.new(0.5, 1),
+			Position = UDim2.new(0.5, 0, 1, -LABEL_BOTTOM),
+			Size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
+			BackgroundTransparency = 1,
+			Font = FONT,
+			Text = blockType.DisplayName,
+			TextColor3 = TEXT_COLOR,
+			TextSize = LABEL_TEXT_SIZE,
+		}),
+
+		create("TextLabel")({
+			Name = "KeyHint",
+			Position = KEY_HINT_POSITION,
+			Size = KEY_HINT_SIZE,
+			BackgroundTransparency = 1,
+			Font = FONT,
+			Text = props.KeyHint,
+			TextColor3 = KEY_HINT_COLOR,
+			TextSize = KEY_HINT_TEXT_SIZE,
+			TextXAlignment = Enum.TextXAlignment.Left,
+			TextYAlignment = Enum.TextYAlignment.Top,
+			Visible = props.ShowKeyHint,
+		}),
+	})
+end
+
+local function BlockHotbar(props: BlockHotbarProps): Frame
+	local slots = {}
+	for index, blockType in props.BlockTypes do
+		slots[index] = slot({
+			BlockType = blockType,
+			KeyHint = tostring(index),
+			LayoutOrder = index,
+			IsSelected = function()
+				return props.Selected() == blockType.Name
+			end,
+			ShowKeyHint = props.ShowKeyHints,
+			Select = function()
+				props.Select(blockType.Name)
+			end,
+		})
+	end
+
+	return create("Frame")({
+		Name = "BlockHotbar",
+		AnchorPoint = Vector2.new(0.5, 1),
+		Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
+		AutomaticSize = Enum.AutomaticSize.XY,
+		BackgroundTransparency = 1,
+
+		create("UIListLayout")({
+			FillDirection = Enum.FillDirection.Horizontal,
+			Padding = UDim.new(0, SLOT_GAP),
+		}),
+		slots,
+	})
+end
+
+return BlockHotbar
diff --git a/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
new file mode 100644
index 0000000..1c1ac16
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
@@ -0,0 +1,50 @@
+--!strict
+--[[
+	Connects the block hotbar to BlockPlacer and mounts it, so the hotbar
+	shows selections made with the number keys and slot presses select a block.
+]]
+
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+local cleanup = Vide.cleanup
+local create = Vide.create
+local mount = Vide.mount
+local source = Vide.source
+
+local BlockHotbar = require("./BlockHotbar")
+local BlockPlacer = require("./BlockPlacer")
+local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+local Screen = require("./Screen")
+
+local Module = {}
+
+local function hotbarGui(): ScreenGui
+	local selected = source(BlockPlacer.getBlockType())
+	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
+		selected(name)
+	end))
+
+	return create("ScreenGui")({
+		Name = "Hotbar",
+
+		create("UIScale")({ Scale = Screen.uiScale }),
+		BlockHotbar({
+			BlockTypes = BlockTypes.List,
+			Selected = selected,
+			Select = BlockPlacer.setBlockType,
+			ShowKeyHints = function()
+				return not Screen.isTouch()
+			end,
+		}),
+	})
+end
+
+--[[
+	Builds the hotbar under the given PlayerGui for the rest of the session.
+	Returns the function that destroys its Vide scope.
+]]
+function Module.mount(playerGui: Instance): () -> ()
+	return mount(hotbarGui, playerGui)
+end
+
+return Module
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index d6fde35..f773a41 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,8 +1,15 @@
 local Players = game:GetService("Players")
+local RunService = game:GetService("RunService")
 
-local BlockPlacer = require(script.Parent.BlockPlacer)
+local Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+local BlockPlacer = require("./BlockPlacer")
+local Hotbar = require("./Hotbar")
+
+Vide.strict = RunService:IsStudio()
 
 local localPlayer = Players.LocalPlayer
 print(`client started for {localPlayer.Name}`)
 
+Hotbar.mount(localPlayer:WaitForChild("PlayerGui"))
 BlockPlacer.start()
diff --git a/src/StarterPlayer/StarterPlayerScripts/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/Screen.luau
new file mode 100644
index 0000000..d99092f
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Screen.luau
@@ -0,0 +1,85 @@
+--!strict
+--[[
+	Facts about the player's screen, as Vide sources that follow the live
+	device. UI binds to these getters instead of reading the camera or input
+	service itself.
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
+local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)
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
+		-- ViewportSize can read (1, 1) before the first frame, which would pass
+		-- for a tiny phone, so the fallback stays until a real size arrives.
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
+	Whether touch is the primary input, which is when Roblox shows its touch
+	controls and keyboard hints mean nothing to the player.
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
index 0000000..4d27206
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
@@ -0,0 +1,178 @@
+--[[
+	Hotbar UI built with Vide: one slot per block type in BlockTypes, with the selected one
+	highlighted. Clicking or tapping a slot selects that block type. The selection is read from
+	BlockPlacer and kept in sync when it changes elsewhere, for example by the number keys.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local Workspace = game:GetService("Workspace")
+
+local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+local BlockPlacer = require(script.Parent.BlockPlacer)
+
+local create = Vide.create
+local source = Vide.source
+local derive = Vide.derive
+local cleanup = Vide.cleanup
+local spring = Vide.spring
+
+-- Slot edge length in pixels. Never below 44 so slots stay easy to tap on phones.
+local MIN_SLOT_SIZE = 44
+local MAX_SLOT_SIZE = 64
+local SLOT_GAP = 6
+local BOTTOM_MARGIN = 12
+
+local SLOT_COLOR = Color3.fromRGB(30, 30, 34)
+local SELECTED_STROKE_COLOR = Color3.fromRGB(255, 255, 255)
+local STROKE_COLOR = Color3.fromRGB(80, 80, 88)
+
+local function Slot(props: {
+	index: number,
+	blockType: BlockTypes.BlockType,
+	selected: () -> boolean,
+	size: () -> number,
+})
+	local blockType = props.blockType
+	local selected = props.selected
+	local emphasis = spring(function()
+		return if selected() then 1 else 0
+	end, 0.15)
+
+	return create("TextButton")({
+		Name = blockType.Name,
+		LayoutOrder = props.index,
+		Text = "",
+		AutoButtonColor = false,
+		BackgroundColor3 = SLOT_COLOR,
+		BackgroundTransparency = function()
+			return 0.45 - emphasis() * 0.3
+		end,
+		Size = function()
+			local size = props.size()
+			return UDim2.fromOffset(size, size)
+		end,
+		Activated = function()
+			BlockPlacer.setBlockType(blockType.Name)
+		end,
+
+		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
+		create("UIStroke")({
+			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+			Color = function()
+				return if selected() then SELECTED_STROKE_COLOR else STROKE_COLOR
+			end,
+			Thickness = function()
+				return 1 + emphasis() * 2
+			end,
+		}),
+
+		-- Block swatch.
+		create("Frame")({
+			Name = "Swatch",
+			AnchorPoint = Vector2.new(0.5, 0.5),
+			Position = UDim2.fromScale(0.5, 0.45),
+			Size = function()
+				local scale = 0.5 + emphasis() * 0.08
+				return UDim2.fromScale(scale, scale)
+			end,
+			BackgroundColor3 = blockType.Color,
+			BackgroundTransparency = blockType.Transparency * 0.6,
+			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
+			create("UIStroke")({ Color = Color3.new(0, 0, 0), Transparency = 0.6 }),
+		}),
+
+		-- Block name.
+		create("TextLabel")({
+			Name = "Label",
+			AnchorPoint = Vector2.new(0.5, 1),
+			Position = UDim2.new(0.5, 0, 1, -2),
+			Size = UDim2.fromScale(0.95, 0.22),
+			BackgroundTransparency = 1,
+			Text = blockType.DisplayName,
+			TextScaled = true,
+			Font = Enum.Font.GothamMedium,
+			TextColor3 = Color3.new(1, 1, 1),
+		}),
+
+		-- Number key hint.
+		create("TextLabel")({
+			Name = "KeyHint",
+			Position = UDim2.fromOffset(4, 2),
+			Size = UDim2.fromOffset(12, 12),
+			BackgroundTransparency = 1,
+			Text = tostring(props.index),
+			TextScaled = true,
+			Font = Enum.Font.GothamBold,
+			TextXAlignment = Enum.TextXAlignment.Left,
+			TextColor3 = Color3.fromRGB(200, 200, 200),
+		}),
+	})
+end
+
+--[[
+	Builds the hotbar. Call inside a Vide root (for example with Vide.mount); the BlockPlacer
+	connection is cleaned up when that root is destroyed.
+]]
+local function Hotbar()
+	local selectedName = source(BlockPlacer.getBlockType())
+	local connection = BlockPlacer.BlockTypeChanged:Connect(selectedName)
+	cleanup(function()
+		connection:Disconnect()
+	end)
+
+	-- Size slots to the screen so all five fit on small phones without dropping below a tappable size.
+	local camera = Workspace.CurrentCamera
+	local viewportSize = source(camera.ViewportSize)
+	local viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
+		viewportSize(camera.ViewportSize)
+	end)
+	cleanup(function()
+		viewportConnection:Disconnect()
+	end)
+
+	local slotSize = derive(function()
+		local count = #BlockTypes.List
+		local fitting = (viewportSize().X * 0.6 - SLOT_GAP * (count - 1)) / count
+		return math.floor(math.clamp(fitting, MIN_SLOT_SIZE, MAX_SLOT_SIZE))
+	end)
+
+	local slots = {}
+	for index, blockType in BlockTypes.List do
+		slots[index] = Slot({
+			index = index,
+			blockType = blockType,
+			selected = function()
+				return selectedName() == blockType.Name
+			end,
+			size = slotSize,
+		})
+	end
+
+	return create("ScreenGui")({
+		Name = "Hotbar",
+		ResetOnSpawn = false,
+		IgnoreGuiInset = false,
+		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
+
+		create("Frame")({
+			Name = "Slots",
+			AnchorPoint = Vector2.new(0.5, 1),
+			Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
+			AutomaticSize = Enum.AutomaticSize.XY,
+			BackgroundTransparency = 1,
+
+			create("UIListLayout")({
+				FillDirection = Enum.FillDirection.Horizontal,
+				HorizontalAlignment = Enum.HorizontalAlignment.Center,
+				VerticalAlignment = Enum.VerticalAlignment.Bottom,
+				SortOrder = Enum.SortOrder.LayoutOrder,
+				Padding = UDim.new(0, SLOT_GAP),
+			}),
+
+			slots,
+		}),
+	})
+end
+
+return Hotbar
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index d6fde35..98b5bf3 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,8 +1,15 @@
 local Players = game:GetService("Players")
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
+local Vide = require(ReplicatedStorage.Packages.Vide)
 local BlockPlacer = require(script.Parent.BlockPlacer)
+local Hotbar = require(script.Parent.Hotbar)
 
 local localPlayer = Players.LocalPlayer
 print(`client started for {localPlayer.Name}`)
 
+-- Mount UI before starting BlockPlacer, since start() yields until the server's remote exists.
+local playerGui = localPlayer:WaitForChild("PlayerGui")
+Vide.mount(Hotbar, playerGui)
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
