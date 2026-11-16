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
- [pass] stylua --check passes on the changed Luau files
- [pass] The motion uses Vide's spring
- [pass] No file under src builds a ScreenGui with Instance.new (the UI is built with Vide's create)
</attempt_a_checks>

<attempt_a_diff>
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index 4719bcf..a12da82 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,6 +1,12 @@
 --[[
 	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
-	block type. The selected tile has a yellow outline.
+	block type. A single yellow highlight glides to the selected tile.
+
+	The picker slides up from below the screen when it appears and slides back down before it is
+	removed. It is meant to be used inside `Vide.show`: it takes the `Present` source that `show`
+	passes to its component, and returns the exit delay `show` should wait before destroying it.
+	If build mode is turned back on during the slide-out, `show` keeps the same picker and the
+	spring simply turns around, so spamming the toggle is safe.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
@@ -8,7 +14,10 @@ local ReplicatedStorage = game:GetService("ReplicatedStorage")
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
+local changed = Vide.changed
 local create = Vide.create
+local source = Vide.source
+local spring = Vide.spring
 
 type BlockType = BlockTypes.BlockType
 
@@ -17,55 +26,103 @@ local TILE_GAP = 8
 local TILE_RADIUS = 8
 local PANEL_PADDING = 8
 local PANEL_RADIUS = TILE_RADIUS + PANEL_PADDING
+local PANEL_HEIGHT = TILE_SIZE + PANEL_PADDING * 2
 local BOTTOM_MARGIN = 24
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
+local HIGHLIGHT_THICKNESS = 3
+
+-- The panel is anchored at its bottom centre. Shown, it sits BOTTOM_MARGIN above the screen's
+-- bottom edge; hidden, its top edge is a little below the screen.
+local SHOWN_POSITION = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
+local HIDDEN_POSITION = UDim2.new(0.5, 0, 1, PANEL_HEIGHT + 16)
+local SLIDE_PERIOD = 0.35
+local SLIDE_DAMPING = 0.75
+-- How long `show` keeps the picker after build mode turns off, so the slide-out can finish.
+local EXIT_DELAY = 0.4
+
+local HIGHLIGHT_PERIOD = 0.25
+local HIGHLIGHT_DAMPING = 0.7
+
+local PRESSED_SCALE = 0.86
+local HOVER_SCALE = 1.06
+local PRESS_PERIOD = 0.2
+local PRESS_DAMPING = 0.45
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
-	IsSelected: () -> boolean,
+	Interactable: () -> boolean,
 	Select: () -> (),
 }
 
-local function tile(props: TileProps): TextButton
-	return create("TextButton")({
+-- A tile is a fixed slot in the row holding a button centred inside it, so the button can shrink
+-- and grow around its centre without nudging the layout.
+local function tile(props: TileProps): Frame
+	local guiState = source(Enum.GuiState.Idle)
+
+	local scale = spring(function()
+		local state = guiState()
+		if state == Enum.GuiState.Press then
+			return PRESSED_SCALE
+		elseif state == Enum.GuiState.Hover then
+			return HOVER_SCALE
+		end
+		return 1
+	end, PRESS_PERIOD, PRESS_DAMPING)
+
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
-			end,
-			Thickness = function()
-				return if props.IsSelected() then 3 else 1
-			end,
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
+			changed("GuiState", guiState),
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
+	-- From `Vide.show`: true while the picker should be on screen, false while it leaves.
+	Present: () -> boolean,
 }
 
-local function blockPicker(props: BlockPickerProps): Frame
+local function blockPicker(props: BlockPickerProps): (Frame, number)
 	local tiles = {}
+	local indexByName: { [string]: number } = {}
 	for index, blockType in BlockTypes.List do
+		indexByName[blockType.Name] = index
 		tiles[index] = tile({
 			BlockType = blockType,
 			LayoutOrder = index,
-			IsSelected = function()
-				return props.Selected() == blockType.Name
-			end,
+			Interactable = props.Present,
 			Select = function()
 				props.Select(blockType.Name)
 			end,
@@ -74,13 +131,23 @@ local function blockPicker(props: BlockPickerProps): Frame
 
 	local count = #BlockTypes.List
 
-	return create("Frame")({
+	-- `show` creates the picker with Present false and flips it to true right after, so the
+	-- spring starts below the screen and slides up.
+	local position = spring(function()
+		return if props.Present() then SHOWN_POSITION else HIDDEN_POSITION
+	end, SLIDE_PERIOD, SLIDE_DAMPING)
+
+	local highlightPosition = spring(function()
+		return tileOffset(indexByName[props.Selected()] or 1)
+	end, HIGHLIGHT_PERIOD, HIGHLIGHT_DAMPING)
+
+	local panel = create("Frame")({
 		Name = "BlockPicker",
 		AnchorPoint = Vector2.new(0.5, 1),
-		Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
+		Position = position,
 		Size = UDim2.fromOffset(
 			count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
-			TILE_SIZE + PANEL_PADDING * 2
+			PANEL_HEIGHT
 		),
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
@@ -92,13 +159,41 @@ local function blockPicker(props: BlockPickerProps): Frame
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
+				SortOrder = Enum.SortOrder.LayoutOrder,
+				Padding = UDim.new(0, TILE_GAP),
+			}),
+
+			tiles,
 		}),
 
-		tiles,
+		-- Drawn over the tiles and kept out of the list layout so it can move freely.
+		create("Frame")({
+			Name = "Highlight",
+			ZIndex = 2,
+			Position = highlightPosition,
+			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
+			BackgroundTransparency = 1,
+			Active = false,
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
+	return panel, EXIT_DELAY
 end
 
 return blockPicker
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 0283e30..edb85f0 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -97,10 +97,13 @@ local function app()
 		create("UIScale")({ Scale = uiScale }),
 		buildButton(),
 
-		show(isBuildMode, function()
+		-- The picker returns an exit delay, so `show` keeps it around while it slides away and
+		-- reuses it if build mode comes back on before then.
+		show(isBuildMode, function(_, present)
 			return BlockPicker({
 				Selected = selected,
 				Select = BlockPlacer.setBlockType,
+				Present = present,
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
index 4719bcf..f547244 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,6 +1,8 @@
 --[[
 	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
-	block type. The selected tile has a yellow outline.
+	block type. It slides up from below the screen while `Present` is true and back down when it
+	turns false, one yellow highlight glides to the selected tile, and tiles grow on hover and sink
+	when pressed.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
@@ -8,7 +10,10 @@ local ReplicatedStorage = game:GetService("ReplicatedStorage")
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
+local changed = Vide.changed
 local create = Vide.create
+local source = Vide.source
+local spring = Vide.spring
 
 type BlockType = BlockTypes.BlockType
 
@@ -21,67 +26,126 @@ local BOTTOM_MARGIN = 24
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
+local HIGHLIGHT_THICKNESS = 3
+
+local SLIDE_PERIOD = 0.3
+local GLIDE_PERIOD = 0.25
+local PRESS_PERIOD = 0.25
+-- Below 1 so a released tile bounces back: feedback to the player's own press.
+local PRESS_DAMPING = 0.5
+local HOVER_SCALE = 1.06
+local PRESS_SCALE = 0.9
+
+local Module = {}
+
+-- Seconds to keep the picker after it leaves; a critically damped spring with SLIDE_PERIOD is
+-- within a pixel of its target by then.
+Module.ExitDuration = 0.4
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
-	IsSelected: () -> boolean,
 	Select: () -> (),
 }
 
-local function tile(props: TileProps): TextButton
-	return create("TextButton")({
+local function tile(props: TileProps): Frame
+	local guiState = source(Enum.GuiState.Idle)
+
+	local scale = spring(function()
+		local state = guiState()
+		if state == Enum.GuiState.Press then
+			return PRESS_SCALE
+		elseif state == Enum.GuiState.Hover then
+			return HOVER_SCALE
+		end
+		return 1
+	end, PRESS_PERIOD, PRESS_DAMPING)
+
+	-- The layout places this fixed slot, so the button can scale around its center without
+	-- pushing its neighbors.
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
-			end,
-			Thickness = function()
-				return if props.IsSelected() then 3 else 1
-			end,
+		BackgroundTransparency = 1,
+
+		create("TextButton")({
+			Name = "Button",
+			AnchorPoint = Vector2.new(0.5, 0.5),
+			Position = UDim2.fromScale(0.5, 0.5),
+			Size = UDim2.fromScale(1, 1),
+			BackgroundColor3 = props.BlockType.Color,
+
+			Activated = props.Select,
+
+			changed("GuiState", guiState),
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
+	-- The `present` source from the `show` that builds the picker.
+	Present: () -> boolean,
 }
 
-local function blockPicker(props: BlockPickerProps): Frame
+function Module.new(props: BlockPickerProps): Frame
+	local count = #BlockTypes.List
+	local panelSize = Vector2.new(
+		count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
+		TILE_SIZE + PANEL_PADDING * 2
+	)
+
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
+				-- Tiles stay clickable while the picker slides away.
+				if not props.Present() then
+					return
+				end
 				props.Select(blockType.Name)
 			end,
 		})
 	end
 
-	local count = #BlockTypes.List
+	local function selectedIndex(): number?
+		return indexByName[props.Selected()]
+	end
+
+	local position = spring(function()
+		return if props.Present()
+			then UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
+			else UDim2.new(0.5, 0, 1, panelSize.Y)
+	end, SLIDE_PERIOD)
+
+	local highlightPosition = spring(function()
+		return tileOffset(selectedIndex() or 1)
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
+		Size = UDim2.fromOffset(panelSize.X, panelSize.Y),
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
 
@@ -92,13 +156,40 @@ local function blockPicker(props: BlockPickerProps): Frame
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
+		-- Kept out of the list layout so it can glide between tiles.
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
 end
 
-return blockPicker
+return Module
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 0283e30..cfb2de2 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,5 +1,6 @@
 local Players = game:GetService("Players")
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local RunService = game:GetService("RunService")
 local UserInputService = game:GetService("UserInputService")
 local Workspace = game:GetService("Workspace")
 
@@ -7,6 +8,8 @@ local BlockPicker = require(script.Parent.BlockPicker)
 local BlockPlacer = require(script.Parent.BlockPlacer)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
+Vide.strict = RunService:IsStudio()
+
 local create = Vide.create
 local mount = Vide.mount
 local show = Vide.show
@@ -97,11 +100,15 @@ local function app()
 		create("UIScale")({ Scale = uiScale }),
 		buildButton(),
 
-		show(isBuildMode, function()
-			return BlockPicker({
+		-- Turning build mode back on during the exit delay cancels the removal, so spamming B
+		-- reverses the slide instead of stacking pickers.
+		show(isBuildMode, function(_, present)
+			return BlockPicker.new({
 				Selected = selected,
 				Select = BlockPlacer.setBlockType,
-			})
+				Present = present,
+			}),
+				BlockPicker.ExitDuration
 		end),
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
