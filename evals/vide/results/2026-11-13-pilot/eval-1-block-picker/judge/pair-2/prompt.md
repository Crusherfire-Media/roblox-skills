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
diff --git a/src/ServerScriptService/Stories/Hotbar.story.luau b/src/ServerScriptService/Stories/Hotbar.story.luau
new file mode 100644
index 0000000..126196b
--- /dev/null
+++ b/src/ServerScriptService/Stories/Hotbar.story.luau
@@ -0,0 +1,56 @@
+--[[
+	The block hotbar. Click a slot to select it, as a player would.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local StarterPlayer = game:GetService("StarterPlayer")
+
+local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Hotbar = require(StarterPlayer.StarterPlayerScripts.Hotbar)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local create = Vide.create
+local source = Vide.source
+
+type StoryProps = {
+	controls: {
+		IsCompact: () -> boolean,
+		ShowKeyHints: () -> boolean,
+	},
+	target: Frame,
+}
+
+local function story(props: StoryProps)
+	local selected = source(BlockTypes.List[1].Name)
+
+	return create("Frame")({
+		Name = "Preview",
+		BackgroundTransparency = 1,
+		AnchorPoint = Vector2.new(0.5, 0.5),
+		Position = UDim2.fromScale(0.5, 0.5),
+		AutomaticSize = Enum.AutomaticSize.XY,
+
+		Hotbar.new({
+			BlockTypes = BlockTypes.List,
+			Selected = selected,
+			OnSelect = function(name: string)
+				print(`selected {name}`)
+				selected(name)
+			end,
+			IsCompact = props.controls.IsCompact,
+			ShowKeyHints = props.controls.ShowKeyHints,
+		}),
+	})
+end
+
+return {
+	summary = "The block hotbar in its desktop and compact (touch) sizes.",
+	vide = Vide,
+	controls = {
+		-- The touch layout, used on phones and whenever touch is the primary input.
+		IsCompact = false,
+		-- The number key labels, shown when touch is not the primary input.
+		ShowKeyHints = true,
+	},
+	story = story,
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockHud.luau b/src/StarterPlayer/StarterPlayerScripts/BlockHud.luau
new file mode 100644
index 0000000..896c44e
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockHud.luau
@@ -0,0 +1,90 @@
+--[[
+	The block placement HUD: connects the hotbar to BlockPlacer and places it along the bottom
+	of the screen, between Roblox's thumbstick region and jump button when those are showing.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+
+local BlockPlacer = require(script.Parent.BlockPlacer)
+local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Hotbar = require(script.Parent.Hotbar)
+local Screen = require(script.Parent.Screen)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local cleanup = Vide.cleanup
+local create = Vide.create
+local source = Vide.source
+
+local BOTTOM_MARGIN = 12
+local EDGE_PADDING = 8
+
+-- Default PlayerModule touch controls, in real pixels. The dynamic thumbstick takes presses
+-- across the left 40 percent of the screen, and the jump button's left edge sits this far from
+-- the right edge, by whether the screen's short side is over 500.
+local THUMBSTICK_REGION_WIDTH = 0.4
+local SMALL_TOUCH_SHORT_SIDE = 500
+local SMALL_JUMP_BUTTON_LEFT = 95
+local LARGE_JUMP_BUTTON_LEFT = 170
+
+local BlockHud = {}
+
+--[[
+	Horizontal center of the hotbar in UI units, so it sits in the free span between the
+	thumbstick region and the jump button, or in the middle of the screen without them.
+]]
+local function hotbarCenterX(hotbarWidth: number): number
+	local viewport = Screen.viewport()
+	if not Screen.isTouch() then
+		return math.floor(viewport.X / 2)
+	end
+
+	local scale = Screen.uiScale()
+	local realShortSide = math.min(viewport.X, viewport.Y) * scale
+	local jumpButtonLeft = if realShortSide > SMALL_TOUCH_SHORT_SIDE
+		then LARGE_JUMP_BUTTON_LEFT
+		else SMALL_JUMP_BUTTON_LEFT
+	local freeLeft = viewport.X * THUMBSTICK_REGION_WIDTH
+	local freeRight = viewport.X - jumpButtonLeft / scale
+	local center = (freeLeft + freeRight) / 2
+
+	local halfWidth = hotbarWidth / 2
+	local minimum = halfWidth + EDGE_PADDING
+	local maximum = math.max(minimum, viewport.X - halfWidth - EDGE_PADDING)
+	return math.floor(math.clamp(center, minimum, maximum))
+end
+
+function BlockHud.new(): ScreenGui
+	local selected = source(BlockPlacer.getBlockType())
+	cleanup(BlockPlacer.BlockTypeChanged:Connect(function(name: string)
+		selected(name)
+	end))
+
+	return create("ScreenGui")({
+		Name = "BlockHud",
+
+		create("UIScale")({ Scale = Screen.uiScale }),
+
+		create("Frame")({
+			Name = "HotbarDock",
+			BackgroundTransparency = 1,
+			AnchorPoint = Vector2.new(0.5, 1),
+			Position = function()
+				local size = Hotbar.size(Screen.isTouchLayout(), #BlockTypes.List)
+				return UDim2.new(0, hotbarCenterX(size.X), 1, -BOTTOM_MARGIN)
+			end,
+			AutomaticSize = Enum.AutomaticSize.XY,
+
+			Hotbar.new({
+				BlockTypes = BlockTypes.List,
+				Selected = selected,
+				OnSelect = BlockPlacer.setBlockType,
+				IsCompact = Screen.isTouchLayout,
+				ShowKeyHints = function()
+					return not Screen.isTouch()
+				end,
+			}),
+		}),
+	})
+end
+
+return BlockHud
diff --git a/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
new file mode 100644
index 0000000..a3fe5bf
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Hotbar.luau
@@ -0,0 +1,236 @@
+--[[
+	A row of block type slots with the selected block's name above it. Pressing a slot calls
+	OnSelect; the highlight follows Selected, so it stays right however the selection changes.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+
+local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local create = Vide.create
+local derive = Vide.derive
+local read = Vide.read
+
+type BlockType = BlockTypes.BlockType
+
+export type HotbarProps = {
+	BlockTypes: { BlockType },
+	Selected: () -> string,
+	OnSelect: (name: string) -> (),
+	IsCompact: (boolean | () -> boolean)?,
+	ShowKeyHints: (boolean | () -> boolean)?,
+}
+
+type Metrics = {
+	SlotSize: number,
+	Gap: number,
+	BarPadding: number,
+	NameTextSize: number,
+}
+
+local REGULAR: Metrics = table.freeze({
+	SlotSize = 64,
+	Gap = 8,
+	BarPadding = 8,
+	NameTextSize = 20,
+})
+-- Narrow enough to fit between the thumbstick region and the jump button on a 667 wide phone.
+local COMPACT: Metrics = table.freeze({
+	SlotSize = 52,
+	Gap = 6,
+	BarPadding = 6,
+	NameTextSize = 18,
+})
+
+local BAR_RADIUS = 12
+local SLOT_RADIUS = 10
+local SWATCH_INSET = 6
+local SELECTED_STROKE = 3
+local NAME_GAP = 4
+local KEY_HINT_TEXT_SIZE = 14
+
+local BAR_COLOR = Color3.fromRGB(20, 20, 24)
+local BAR_TRANSPARENCY = 0.35
+local SLOT_COLOR = Color3.fromRGB(45, 45, 52)
+local SELECTED_SLOT_COLOR = Color3.fromRGB(90, 90, 100)
+local HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255)
+local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
+local TEXT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)
+local FONT = Enum.Font.BuilderSansBold
+
+local Hotbar = {}
+
+local function metricsFor(isCompact: boolean): Metrics
+	return if isCompact then COMPACT else REGULAR
+end
+
+local function barWidth(metrics: Metrics, slotCount: number): number
+	return slotCount * metrics.SlotSize + (slotCount - 1) * metrics.Gap + 2 * metrics.BarPadding
+end
+
+--[[
+	The hotbar's full size in UI units, for placing it without reading AbsoluteSize back.
+]]
+function Hotbar.size(isCompact: boolean, slotCount: number): Vector2
+	local metrics = metricsFor(isCompact)
+	local barHeight = metrics.SlotSize + 2 * metrics.BarPadding
+	return Vector2.new(barWidth(metrics, slotCount), metrics.NameTextSize + NAME_GAP + barHeight)
+end
+
+local function slot(
+	blockType: BlockType,
+	index: number,
+	metrics: () -> Metrics,
+	props: HotbarProps
+): TextButton
+	local function isSelected(): boolean
+		return props.Selected() == blockType.Name
+	end
+
+	return create("TextButton")({
+		Name = blockType.Name,
+		LayoutOrder = index,
+		Text = "",
+		Size = function()
+			local size = metrics().SlotSize
+			return UDim2.fromOffset(size, size)
+		end,
+		BackgroundColor3 = function()
+			return if isSelected() then SELECTED_SLOT_COLOR else SLOT_COLOR
+		end,
+
+		Activated = function()
+			props.OnSelect(blockType.Name)
+		end,
+
+		create("UICorner")({ CornerRadius = UDim.new(0, SLOT_RADIUS) }),
+		create("UIStroke")({
+			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+			Color = HIGHLIGHT_COLOR,
+			Thickness = SELECTED_STROKE,
+			Enabled = isSelected,
+		}),
+
+		create("Frame")({
+			Name = "Swatch",
+			Position = UDim2.fromOffset(SWATCH_INSET, SWATCH_INSET),
+			Size = UDim2.new(1, -2 * SWATCH_INSET, 1, -2 * SWATCH_INSET),
+			BackgroundColor3 = blockType.Color,
+			BackgroundTransparency = blockType.Transparency,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, SLOT_RADIUS - SWATCH_INSET) }),
+		}),
+
+		create("TextLabel")({
+			Name = "KeyHint",
+			Position = UDim2.fromOffset(SWATCH_INSET, SWATCH_INSET),
+			Size = UDim2.fromOffset(KEY_HINT_TEXT_SIZE, KEY_HINT_TEXT_SIZE),
+			BackgroundTransparency = 1,
+			Text = tostring(index),
+			TextSize = KEY_HINT_TEXT_SIZE,
+			Font = FONT,
+			TextColor3 = TEXT_COLOR,
+			TextStrokeColor3 = TEXT_OUTLINE_COLOR,
+			TextStrokeTransparency = 0.3,
+			TextXAlignment = Enum.TextXAlignment.Left,
+			TextYAlignment = Enum.TextYAlignment.Top,
+			Visible = function()
+				return read(props.ShowKeyHints) == true
+			end,
+		}),
+	})
+end
+
+function Hotbar.new(props: HotbarProps): Frame
+	-- Derived so bindings rerun when the variant flips, not on every pixel of a resize.
+	local metrics = derive(function(): Metrics
+		return metricsFor(read(props.IsCompact) == true)
+	end)
+
+	local selectedDisplayName = derive(function(): string
+		local name = props.Selected()
+		for _, blockType in props.BlockTypes do
+			if blockType.Name == name then
+				return blockType.DisplayName
+			end
+		end
+		return name
+	end)
+
+	local slots = {}
+	for index, blockType in props.BlockTypes do
+		table.insert(slots, slot(blockType, index, metrics, props))
+	end
+
+	return create("Frame")({
+		Name = "Hotbar",
+		BackgroundTransparency = 1,
+		Size = function()
+			local size = Hotbar.size(read(props.IsCompact) == true, #props.BlockTypes)
+			return UDim2.fromOffset(size.X, size.Y)
+		end,
+
+		create("UIListLayout")({
+			FillDirection = Enum.FillDirection.Vertical,
+			HorizontalAlignment = Enum.HorizontalAlignment.Center,
+			Padding = UDim.new(0, NAME_GAP),
+		}),
+
+		create("TextLabel")({
+			Name = "SelectedName",
+			LayoutOrder = 1,
+			Size = function()
+				return UDim2.new(1, 0, 0, metrics().NameTextSize)
+			end,
+			BackgroundTransparency = 1,
+			Text = selectedDisplayName,
+			TextSize = function()
+				return metrics().NameTextSize
+			end,
+			Font = FONT,
+			TextColor3 = TEXT_COLOR,
+			TextStrokeColor3 = TEXT_OUTLINE_COLOR,
+			TextStrokeTransparency = 0.3,
+			TextTruncate = Enum.TextTruncate.AtEnd,
+		}),
+
+		create("Frame")({
+			Name = "Bar",
+			LayoutOrder = 2,
+			Size = function()
+				local current = metrics()
+				return UDim2.new(1, 0, 0, current.SlotSize + 2 * current.BarPadding)
+			end,
+			BackgroundColor3 = BAR_COLOR,
+			BackgroundTransparency = BAR_TRANSPARENCY,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, BAR_RADIUS) }),
+			create("UIPadding")({
+				PaddingLeft = function()
+					return UDim.new(0, metrics().BarPadding)
+				end,
+				PaddingRight = function()
+					return UDim.new(0, metrics().BarPadding)
+				end,
+				PaddingTop = function()
+					return UDim.new(0, metrics().BarPadding)
+				end,
+				PaddingBottom = function()
+					return UDim.new(0, metrics().BarPadding)
+				end,
+			}),
+			create("UIListLayout")({
+				FillDirection = Enum.FillDirection.Horizontal,
+				VerticalAlignment = Enum.VerticalAlignment.Center,
+				Padding = function()
+					return UDim.new(0, metrics().Gap)
+				end,
+			}),
+
+			slots,
+		}),
+	})
+end
+
+return Hotbar
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index d6fde35..a8432ec 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,8 +1,17 @@
 local Players = game:GetService("Players")
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local RunService = game:GetService("RunService")
 
+local BlockHud = require(script.Parent.BlockHud)
 local BlockPlacer = require(script.Parent.BlockPlacer)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+Vide.strict = RunService:IsStudio()
 
 local localPlayer = Players.LocalPlayer
 print(`client started for {localPlayer.Name}`)
 
+local playerGui = localPlayer:WaitForChild("PlayerGui")
+Vide.mount(BlockHud.new, playerGui)
+
 BlockPlacer.start()
diff --git a/src/StarterPlayer/StarterPlayerScripts/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/Screen.luau
new file mode 100644
index 0000000..4f1c2a2
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/Screen.luau
@@ -0,0 +1,99 @@
+--[[
+	Facts about the player's screen as Vide sources, so UI layout follows the live device: the
+	window can resize, a phone can rotate, and the primary input can change while the UI is up.
+	Sizes from viewport() are in UI units, the offsets UI is authored in for a 1080 tall screen.
+]]
+
+local GuiService = game:GetService("GuiService")
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local RunService = game:GetService("RunService")
+local UserInputService = game:GetService("UserInputService")
+local Workspace = game:GetService("Workspace")
+
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local batch = Vide.batch
+local source = Vide.source
+
+local REFERENCE_SHORT_SIDE = 1080
+local MINIMUM_SCALE = 1
+local MAXIMUM_SCALE = 3
+local PHONE_SHORT_SIDE = 600
+local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)
+
+local Screen = {}
+
+local realViewport = source(FALLBACK_VIEWPORT)
+local prefersTouch = source(false)
+local viewportConnection: RBXScriptConnection? = nil
+
+local function refresh()
+	local camera = Workspace.CurrentCamera
+	batch(function()
+		-- ViewportSize can read (1, 1) before the first frame, which would pass for a tiny
+		-- phone, so the fallback stays until a real size arrives.
+		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
+			realViewport(camera.ViewportSize)
+		end
+		prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
+	end)
+end
+
+local function watchCamera()
+	if viewportConnection then
+		viewportConnection:Disconnect()
+	end
+	local camera = Workspace.CurrentCamera
+	if camera then
+		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
+	end
+	refresh()
+end
+
+--[[
+	How much the whole UI grows on this screen. Bind it to a UIScale under every ScreenGui.
+	Smaller screens keep a scale of 1 and change layout instead.
+]]
+function Screen.uiScale(): number
+	local view = realViewport()
+	return math.clamp(math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE, MINIMUM_SCALE, MAXIMUM_SCALE)
+end
+
+--[[
+	The viewport in UI units.
+]]
+function Screen.viewport(): Vector2
+	return realViewport() / Screen.uiScale()
+end
+
+--[[
+	Whether touch is the primary input, which is when Roblox shows its thumbstick and jump
+	button.
+]]
+function Screen.isTouch(): boolean
+	return prefersTouch()
+end
+
+function Screen.isPhone(): boolean
+	local view = Screen.viewport()
+	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
+end
+
+--[[
+	Whether a HUD should use its touch layout: the touch controls are up, or the screen is too
+	small for the desktop layout.
+]]
+function Screen.isTouchLayout(): boolean
+	return prefersTouch() or Screen.isPhone()
+end
+
+if RunService:IsRunning() then
+	watchCamera()
+	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
+	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
+	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
+else
+	refresh()
+end
+
+return Screen

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
