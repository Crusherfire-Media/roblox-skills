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
The block picker works but feels stiff. Add some motion with Vide:

- When build mode turns on (B or the Build button), the picker should slide up from the bottom of the screen, and when build mode turns off it should slide back down before it goes away, instead of popping in and out.
- Instead of the outline jumping from tile to tile, one highlight should glide over to the tile you pick.
- Tiles should react when you press them.

Spamming B or the Build button shouldn't break anything.
</task>

## Rubric

Score each criterion from 1 to 5 for each attempt (1 poor, 3 acceptable, 5 excellent):

1. Animations are Vide springs (or other motion driven by Vide state) created in component bodies and bound to properties. No `spring`, `effect`, or component is created inside a binding or an effect, which errors in Vide.
2. The closing slide really plays: the picker stays in the tree until it has slid off screen and is removed afterward (for example the `show` builder returns a removal delay and drives its slide from the `present` source). Opening slides in from off screen by moving the panel, not by animating the ScreenGui's UIScale.
3. Spamming B or the Build button never leaves two pickers, a picker stuck partway, or an invisible picker that still takes clicks, and turning build mode back on during the closing slide reverses it cleanly.
4. The highlight glides to the selected tile using positions computed in the UI's own offset units (tile index, tile size, gap, padding). If it reads `AbsolutePosition` or `AbsoluteSize` instead, it divides by the UIScale in effect, since the ScreenGui's UIScale is above 1 on 1440p and 4K screens.
5. Press feedback starts the moment a tile is pressed, with mouse and touch alike, and the tile returns to rest on release.
6. Correct and in scope: selection, placement, the Build button, and the screen scaling keep working, and luau-lsp, selene, and StyLua pass on the changed files. Extra supporting files, such as a preview story, count neither for nor against.

## Attempt A

<attempt_a_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [fail] stylua --check passes on the changed Luau files
  Diff in src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau:
  168 168  | 		Name = "BlockPicker",
  169 169  | 		AnchorPoint = Vector2.new(0.5, 1),
  170 170  | 		Position = panelPosition,
  171      |-		Size = UDim2.fromOffset(count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2, panelHeight),
      171  |+		Size = UDim2.fromOffset(
      172  |+			count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
      173  |+			panelHeight
      174  |+		),
  172 175  | 		BackgroundColor3 = PANEL_COLOR,
  173 176  | 		BackgroundTransparency = 0.2,
  174 177  |
- [pass] The motion uses Vide's spring
- [pass] No file under src builds a ScreenGui with Instance.new (the UI is built with Vide's create)
</attempt_a_checks>

<attempt_a_diff>
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index 4719bcf..58fe004 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,6 +1,11 @@
 --[[
 	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
-	block type. The selected tile has a yellow outline.
+	block type. A single yellow highlight glides to the selected tile.
+
+	The picker slides up from below the screen while `Shown` is true and slides back down when it
+	turns false. The component returns the time the exit slide needs as its second value, so it can
+	be returned straight from a `Vide.show` component, which then keeps the picker alive until the
+	slide finishes (and keeps it if build mode turns back on mid-slide).
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
@@ -9,6 +14,8 @@ local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local create = Vide.create
+local source = Vide.source
+local spring = Vide.spring
 
 type BlockType = BlockTypes.BlockType
 
@@ -21,51 +28,117 @@ local BOTTOM_MARGIN = 24
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
+local HIGHLIGHT_THICKNESS = 3
+
+-- Panel slide: a little overshoot on the way up. The exit delay covers the time the panel takes to
+-- get fully below the screen edge.
+local SLIDE_PERIOD = 0.35
+local SLIDE_DAMPING = 0.75
+local EXIT_DURATION = 0.35
+
+-- Highlight glide between tiles.
+local GLIDE_PERIOD = 0.25
+local GLIDE_DAMPING = 0.8
+
+-- Tile press/hover feedback.
+local PRESS_PERIOD = 0.2
+local PRESS_DAMPING = 0.5
+local HOVER_SCALE = 1.06
+local PRESSED_SCALE = 0.88
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
-	IsSelected: () -> boolean,
+	Interactable: () -> boolean,
 	Select: () -> (),
 }
 
-local function tile(props: TileProps): TextButton
-	return create("TextButton")({
+local function isPressInput(input: InputObject): boolean
+	return input.UserInputType == Enum.UserInputType.MouseButton1
+		or input.UserInputType == Enum.UserInputType.Touch
+end
+
+local function tile(props: TileProps): Frame
+	local hovered = source(false)
+	local pressed = source(false)
+
+	local scale = spring(function()
+		return if pressed() then PRESSED_SCALE elseif hovered() then HOVER_SCALE else 1
+	end, PRESS_PERIOD, PRESS_DAMPING)
+
+	-- The list layout positions the slot; the button inside is centered so it scales about its
+	-- middle instead of its top-left corner.
+	return create("Frame")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
 		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
-		BackgroundColor3 = props.BlockType.Color,
-
-		Activated = props.Select,
-
-		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
-		create("UIStroke")({
-			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
-			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
-			Color = function()
-				return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
+		BackgroundTransparency = 1,
+
+		create("TextButton")({
+			Name = "Button",
+			AnchorPoint = Vector2.new(0.5, 0.5),
+			Position = UDim2.fromScale(0.5, 0.5),
+			Size = UDim2.fromScale(1, 1),
+			BackgroundColor3 = props.BlockType.Color,
+			Text = "",
+			AutoButtonColor = false,
+			Interactable = props.Interactable,
+
+			Activated = props.Select,
+			MouseEnter = function()
+				hovered(true)
+			end,
+			MouseLeave = function()
+				hovered(false)
+				pressed(false)
 			end,
-			Thickness = function()
-				return if props.IsSelected() then 3 else 1
+			InputBegan = function(input: InputObject)
+				if isPressInput(input) then
+					pressed(true)
+				end
 			end,
+			InputEnded = function(input: InputObject)
+				if isPressInput(input) then
+					pressed(false)
+				end
+			end,
+
+			create("UIScale")({ Scale = scale }),
+			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
+			create("UIStroke")({
+				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
+				Color = IDLE_STROKE_COLOR,
+				Thickness = 1,
+			}),
 		}),
 	})
 end
 
+local function tileOffset(index: number): UDim2
+	return UDim2.fromOffset((index - 1) * (TILE_SIZE + TILE_GAP), 0)
+end
+
 export type BlockPickerProps = {
 	Selected: () -> string,
 	Select: (name: string) -> (),
+	-- Whether the picker should be on screen. Defaults to always shown.
+	Shown: (() -> boolean)?,
 }
 
-local function blockPicker(props: BlockPickerProps): Frame
+local function blockPicker(props: BlockPickerProps): (Frame, number)
+	local shown = props.Shown or function()
+		return true
+	end
+
+	local indexByName: { [string]: number } = {}
 	local tiles = {}
 	for index, blockType in BlockTypes.List do
+		indexByName[blockType.Name] = index
 		tiles[index] = tile({
 			BlockType = blockType,
 			LayoutOrder = index,
-			IsSelected = function()
-				return props.Selected() == blockType.Name
-			end,
+			Interactable = shown,
 			Select = function()
 				props.Select(blockType.Name)
 			end,
@@ -73,15 +146,29 @@ local function blockPicker(props: BlockPickerProps): Frame
 	end
 
 	local count = #BlockTypes.List
+	local panelHeight = TILE_SIZE + PANEL_PADDING * 2
 
-	return create("Frame")({
+	local selectedIndex = function(): number?
+		return indexByName[props.Selected()]
+	end
+
+	local highlightPosition = spring(function()
+		return tileOffset(selectedIndex() or 1)
+	end, GLIDE_PERIOD, GLIDE_DAMPING)
+
+	-- Anchored at its bottom edge, so an offset of the panel height (plus a little) puts it fully
+	-- below the screen.
+	local panelPosition = spring(function()
+		return if shown()
+			then UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
+			else UDim2.new(0.5, 0, 1, panelHeight + PANEL_PADDING)
+	end, SLIDE_PERIOD, SLIDE_DAMPING)
+
+	local panel = create("Frame")({
 		Name = "BlockPicker",
 		AnchorPoint = Vector2.new(0.5, 1),
-		Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
-		Size = UDim2.fromOffset(
-			count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
-			TILE_SIZE + PANEL_PADDING * 2
-		),
+		Position = panelPosition,
+		Size = UDim2.fromOffset(count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2, panelHeight),
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
 
@@ -92,13 +179,42 @@ local function blockPicker(props: BlockPickerProps): Frame
 			PaddingTop = UDim.new(0, PANEL_PADDING),
 			PaddingBottom = UDim.new(0, PANEL_PADDING),
 		}),
-		create("UIListLayout")({
-			FillDirection = Enum.FillDirection.Horizontal,
-			Padding = UDim.new(0, TILE_GAP),
+
+		create("Frame")({
+			Name = "Tiles",
+			Size = UDim2.fromScale(1, 1),
+			BackgroundTransparency = 1,
+
+			create("UIListLayout")({
+				FillDirection = Enum.FillDirection.Horizontal,
+				Padding = UDim.new(0, TILE_GAP),
+				SortOrder = Enum.SortOrder.LayoutOrder,
+			}),
+
+			tiles,
 		}),
 
-		tiles,
+		create("Frame")({
+			Name = "Highlight",
+			Position = highlightPosition,
+			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
+			BackgroundTransparency = 1,
+			ZIndex = 2,
+			Visible = function()
+				return selectedIndex() ~= nil
+			end,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
+			create("UIStroke")({
+				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
+				Color = SELECTED_COLOR,
+				Thickness = HIGHLIGHT_THICKNESS,
+			}),
+		}),
 	})
+
+	return panel, EXIT_DURATION
 end
 
 return blockPicker
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 0283e30..cee3e86 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -97,10 +97,14 @@ local function app()
 		create("UIScale")({ Scale = uiScale }),
 		buildButton(),
 
-		show(isBuildMode, function()
+		-- `present` turns false as soon as build mode turns off; the picker slides out and returns
+		-- how long that takes, so `show` destroys it only afterwards. Turning build mode back on
+		-- mid-slide keeps the same picker and it slides back up from where it is.
+		show(isBuildMode, function(_, present)
 			return BlockPicker({
 				Selected = selected,
 				Select = BlockPlacer.setBlockType,
+				Shown = present,
 			})
 		end),
 	})

</attempt_a_diff>

## Attempt B

<attempt_b_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] The motion uses Vide's spring
- [pass] No file under src builds a ScreenGui with Instance.new (the UI is built with Vide's create)
</attempt_b_checks>

<attempt_b_diff>
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index 4719bcf..ef6e17c 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,6 +1,7 @@
 --[[
 	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
-	block type. The selected tile has a yellow outline.
+	block type. It slides up from the bottom edge when opened and back down when closed, a yellow
+	highlight glides to the selected tile, and tiles sink while pressed.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
@@ -9,6 +10,10 @@ local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local create = Vide.create
+local derive = Vide.derive
+local show = Vide.show
+local source = Vide.source
+local spring = Vide.spring
 
 type BlockType = BlockTypes.BlockType
 
@@ -21,69 +26,138 @@ local BOTTOM_MARGIN = 24
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
+local HIGHLIGHT_THICKNESS = 3
+
+local SLIDE_PERIOD = 0.3
+-- Must outlast the slide off screen, or the panel vanishes while still visible.
+local SLIDE_OUT_SECONDS = 0.4
+local GLIDE_PERIOD = 0.25
+local PRESSED_SCALE = 0.88
+local PRESS_PERIOD = 0.25
+-- Below 1 so a released tile springs back with a small bounce.
+local PRESS_DAMPING = 0.5
+
+local PRESS_INPUT_TYPES = {
+	Enum.UserInputType.MouseButton1,
+	Enum.UserInputType.Touch,
+}
+local PRESS_KEY_CODES = {
+	Enum.KeyCode.ButtonA,
+	Enum.KeyCode.Return,
+}
+
+local TILE_COUNT = #BlockTypes.List
+local PANEL_WIDTH = TILE_COUNT * TILE_SIZE + (TILE_COUNT - 1) * TILE_GAP + PANEL_PADDING * 2
+local PANEL_HEIGHT = TILE_SIZE + PANEL_PADDING * 2
+local SHOWN_POSITION = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
+-- The extra margin keeps the spring's slow last pixels below the screen edge.
+local HIDDEN_POSITION = UDim2.new(0.5, 0, 1, PANEL_HEIGHT + BOTTOM_MARGIN)
+
+local function isPressInput(input: InputObject): boolean
+	return table.find(PRESS_INPUT_TYPES, input.UserInputType) ~= nil
+		or table.find(PRESS_KEY_CODES, input.KeyCode) ~= nil
+end
+
+local function tilePosition(index: number): UDim2
+	return UDim2.fromOffset((index - 1) * (TILE_SIZE + TILE_GAP), 0)
+end
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
-	IsSelected: () -> boolean,
 	Select: () -> (),
 }
 
-local function tile(props: TileProps): TextButton
-	return create("TextButton")({
+-- The slot holds the tile's place in the row while the button inside shrinks
+-- around its center.
+local function tile(props: TileProps): Frame
+	local isPressed = source(false)
+
+	local scale = spring(function()
+		return if isPressed() then PRESSED_SCALE else 1
+	end, PRESS_PERIOD, PRESS_DAMPING)
+
+	return create("Frame")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
 		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
-		BackgroundColor3 = props.BlockType.Color,
-
-		Activated = props.Select,
+		BackgroundTransparency = 1,
+
+		create("TextButton")({
+			Name = "Button",
+			AnchorPoint = Vector2.new(0.5, 0.5),
+			Position = UDim2.fromScale(0.5, 0.5),
+			Size = function()
+				return UDim2.fromScale(scale(), scale())
+			end,
+			BackgroundColor3 = props.BlockType.Color,
 
-		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
-		create("UIStroke")({
-			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
-			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
-			Color = function()
-				return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
+			Activated = props.Select,
+			InputBegan = function(input: InputObject)
+				if isPressInput(input) then
+					isPressed(true)
+				end
 			end,
-			Thickness = function()
-				return if props.IsSelected() then 3 else 1
+			InputEnded = function(input: InputObject)
+				if isPressInput(input) then
+					isPressed(false)
+				end
 			end,
+			MouseLeave = function()
+				isPressed(false)
+			end,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
+			create("UIStroke")({
+				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
+				Color = IDLE_STROKE_COLOR,
+				Thickness = 1,
+			}),
 		}),
 	})
 end
 
-export type BlockPickerProps = {
+type PanelProps = {
+	IsOpen: () -> boolean,
 	Selected: () -> string,
 	Select: (name: string) -> (),
 }
 
-local function blockPicker(props: BlockPickerProps): Frame
+local function panel(props: PanelProps): Frame
 	local tiles = {}
+	local indexByName: { [string]: number? } = {}
 	for index, blockType in BlockTypes.List do
+		indexByName[blockType.Name] = index
 		tiles[index] = tile({
 			BlockType = blockType,
 			LayoutOrder = index,
-			IsSelected = function()
-				return props.Selected() == blockType.Name
-			end,
 			Select = function()
 				props.Select(blockType.Name)
 			end,
 		})
 	end
 
-	local count = #BlockTypes.List
+	local selectedIndex = derive(function()
+		return indexByName[props.Selected()] or 1
+	end)
+
+	local position = spring(function()
+		return if props.IsOpen() then SHOWN_POSITION else HIDDEN_POSITION
+	end, SLIDE_PERIOD)
+
+	local highlightPosition = spring(function()
+		return tilePosition(selectedIndex())
+	end, GLIDE_PERIOD)
 
 	return create("Frame")({
 		Name = "BlockPicker",
 		AnchorPoint = Vector2.new(0.5, 1),
-		Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
-		Size = UDim2.fromOffset(
-			count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
-			TILE_SIZE + PANEL_PADDING * 2
-		),
+		Position = position,
+		Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT),
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
+		Interactable = props.IsOpen,
 
 		create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
 		create("UIPadding")({
@@ -92,13 +166,58 @@ local function blockPicker(props: BlockPickerProps): Frame
 			PaddingTop = UDim.new(0, PANEL_PADDING),
 			PaddingBottom = UDim.new(0, PANEL_PADDING),
 		}),
-		create("UIListLayout")({
-			FillDirection = Enum.FillDirection.Horizontal,
-			Padding = UDim.new(0, TILE_GAP),
+
+		create("Frame")({
+			Name = "Tiles",
+			Size = UDim2.fromScale(1, 1),
+			BackgroundTransparency = 1,
+
+			create("UIListLayout")({
+				FillDirection = Enum.FillDirection.Horizontal,
+				Padding = UDim.new(0, TILE_GAP),
+			}),
+
+			tiles,
 		}),
 
-		tiles,
+		-- Kept out of the Tiles frame so the list layout does not pin it in place.
+		create("Frame")({
+			Name = "Highlight",
+			Position = highlightPosition,
+			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
+			BackgroundTransparency = 1,
+			ZIndex = 2,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
+			create("UIStroke")({
+				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
+				Color = SELECTED_COLOR,
+				Thickness = HIGHLIGHT_THICKNESS,
+			}),
+		}),
 	})
 end
 
+export type BlockPickerProps = {
+	IsOpen: () -> boolean,
+	Selected: () -> string,
+	Select: (name: string) -> (),
+}
+
+--[[
+	Returns a children source to pass as a child. The panel stays until it has slid off
+	screen after IsOpen turns false; reopening it mid-slide reverses the same panel.
+]]
+local function blockPicker(props: BlockPickerProps): () -> any
+	return show(props.IsOpen, function(_, present)
+		return panel({
+			IsOpen = present,
+			Selected = props.Selected,
+			Select = props.Select,
+		}),
+			SLIDE_OUT_SECONDS
+	end)
+end
+
 return blockPicker
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 0283e30..9c33ff6 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,5 +1,6 @@
 local Players = game:GetService("Players")
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local RunService = game:GetService("RunService")
 local UserInputService = game:GetService("UserInputService")
 local Workspace = game:GetService("Workspace")
 
@@ -7,9 +8,10 @@ local BlockPicker = require(script.Parent.BlockPicker)
 local BlockPlacer = require(script.Parent.BlockPlacer)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
+Vide.strict = RunService:IsStudio()
+
 local create = Vide.create
 local mount = Vide.mount
-local show = Vide.show
 local source = Vide.source
 
 -- The UI is authored for a screen 1080 pixels tall and grows on larger screens.
@@ -97,12 +99,11 @@ local function app()
 		create("UIScale")({ Scale = uiScale }),
 		buildButton(),
 
-		show(isBuildMode, function()
-			return BlockPicker({
-				Selected = selected,
-				Select = BlockPlacer.setBlockType,
-			})
-		end),
+		BlockPicker({
+			IsOpen = isBuildMode,
+			Selected = selected,
+			Select = BlockPlacer.setBlockType,
+		}),
 	})
 end
 

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
