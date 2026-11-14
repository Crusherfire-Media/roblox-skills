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
index 4719bcf..4312043 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,6 +1,10 @@
 --[[
 	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
-	block type. The selected tile has a yellow outline.
+	block type. It slides up when opened and back down before it is removed when closed. A yellow
+	ring glides to the selected tile, and tiles squash when pressed.
+
+	Note on springs: Vide's spring only settles exactly onto a target that isn't 0 (its tolerance
+	scales with the target), so every animated value here has a non-zero resting value.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
@@ -9,12 +13,17 @@ local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local create = Vide.create
+local derive = Vide.derive
+local show = Vide.show
+local source = Vide.source
+local spring = Vide.spring
 
 type BlockType = BlockTypes.BlockType
 
 local TILE_SIZE = 64
 local TILE_GAP = 8
 local TILE_RADIUS = 8
+local TILE_STRIDE = TILE_SIZE + TILE_GAP
 local PANEL_PADDING = 8
 local PANEL_RADIUS = TILE_RADIUS + PANEL_PADDING
 local BOTTOM_MARGIN = 24
@@ -22,83 +31,189 @@ local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
 
+-- The selection ring sits slightly outside the tile so a squashed tile still reads as selected.
+local RING_OUTSET = 4
+local RING_THICKNESS = 3
+
+-- Panel slide: vertical offset of the panel's bottom edge from the bottom of the screen.
+local SHOWN_OFFSET = -BOTTOM_MARGIN
+local SLIDE_PERIOD = 0.4
+local SLIDE_DAMPING = 0.8
+
+local GLIDE_PERIOD = 0.25
+local GLIDE_DAMPING = 0.75
+
+local PRESSED_SCALE = 0.88
+local PRESS_PERIOD = 0.2
+local PRESS_DAMPING = 0.45
+
+local function isPressInput(input: InputObject): boolean
+	return input.UserInputType == Enum.UserInputType.MouseButton1
+		or input.UserInputType == Enum.UserInputType.Touch
+end
+
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
-	IsSelected: () -> boolean,
 	Select: () -> (),
 }
 
-local function tile(props: TileProps): TextButton
-	return create("TextButton")({
+local function tile(props: TileProps): Frame
+	local isPressed = source(false)
+	local scale = spring(function()
+		return if isPressed() then PRESSED_SCALE else 1
+	end, PRESS_PERIOD, PRESS_DAMPING)
+
+	-- The layout positions the slot; the button inside scales around its centre.
+	return create("Frame")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
 		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
-		BackgroundColor3 = props.BlockType.Color,
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
+
+			Activated = props.Select,
+			InputBegan = function(input: InputObject)
+				if isPressInput(input) then
+					isPressed(true)
+				end
+			end,
+			InputEnded = function(input: InputObject)
+				if isPressInput(input) then
+					isPressed(false)
+				end
+			end,
+			MouseLeave = function()
+				isPressed(false)
+			end,
 
-		Activated = props.Select,
+			create("UIScale")({ Scale = scale }),
+			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
+			create("UIStroke")({
+				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
+				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
+				Color = IDLE_STROKE_COLOR,
+				Thickness = 1,
+			}),
+		}),
+	})
+end
 
-		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
+local function selectionRing(selectedIndex: () -> number): Frame
+	-- Always positive (PANEL_PADDING > RING_OUTSET), so the spring settles exactly.
+	local x = spring(function()
+		return PANEL_PADDING - RING_OUTSET + (selectedIndex() - 1) * TILE_STRIDE
+	end, GLIDE_PERIOD, GLIDE_DAMPING)
+
+	return create("Frame")({
+		Name = "SelectionRing",
+		Position = function()
+			return UDim2.fromOffset(x(), PANEL_PADDING - RING_OUTSET)
+		end,
+		Size = UDim2.fromOffset(TILE_SIZE + RING_OUTSET * 2, TILE_SIZE + RING_OUTSET * 2),
+		BackgroundTransparency = 1,
+		Active = false,
+		ZIndex = 2,
+
+		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS + RING_OUTSET) }),
 		create("UIStroke")({
 			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
 			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
-			Color = function()
-				return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
-			end,
-			Thickness = function()
-				return if props.IsSelected() then 3 else 1
-			end,
+			Color = SELECTED_COLOR,
+			Thickness = RING_THICKNESS,
 		}),
 	})
 end
 
 export type BlockPickerProps = {
+	Open: () -> boolean,
 	Selected: () -> string,
 	Select: (name: string) -> (),
 }
 
-local function blockPicker(props: BlockPickerProps): Frame
-	local tiles = {}
-	for index, blockType in BlockTypes.List do
-		tiles[index] = tile({
-			BlockType = blockType,
-			LayoutOrder = index,
-			IsSelected = function()
-				return props.Selected() == blockType.Name
-			end,
-			Select = function()
-				props.Select(blockType.Name)
+local function blockPicker(props: BlockPickerProps)
+	local count = #BlockTypes.List
+	local panelSize = Vector2.new(
+		count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
+		TILE_SIZE + PANEL_PADDING * 2
+	)
+	-- Fully below the screen edge, with a little room for the spring to overshoot.
+	local hiddenOffset = panelSize.Y + PANEL_PADDING
+
+	-- This spring lives outside the shown panel so it keeps its state across open/close toggles:
+	-- reopening mid-slide just retargets it instead of remounting the panel.
+	local offset = spring(function()
+		return if props.Open() then SHOWN_OFFSET else hiddenOffset
+	end, SLIDE_PERIOD, SLIDE_DAMPING)
+
+	-- Stay mounted while open or while still sliding out; the spring snaps exactly to
+	-- hiddenOffset once it settles, which is what removes the panel.
+	local isMounted = derive(function()
+		return props.Open() or offset() ~= hiddenOffset
+	end)
+
+	return show(isMounted, function()
+		local selectedIndex = derive(function()
+			local name = props.Selected()
+			for index, blockType in BlockTypes.List do
+				if blockType.Name == name then
+					return index
+				end
+			end
+			return 1
+		end)
+
+		local tiles = {}
+		for index, blockType in BlockTypes.List do
+			tiles[index] = tile({
+				BlockType = blockType,
+				LayoutOrder = index,
+				Select = function()
+					props.Select(blockType.Name)
+				end,
+			})
+		end
+
+		return create("Frame")({
+			Name = "BlockPicker",
+			AnchorPoint = Vector2.new(0.5, 1),
+			Position = function()
+				return UDim2.new(0.5, 0, 1, offset())
 			end,
+			Size = UDim2.fromOffset(panelSize.X, panelSize.Y),
+			BackgroundColor3 = PANEL_COLOR,
+			BackgroundTransparency = 0.2,
+			-- Ignore presses while sliding away.
+			Interactable = props.Open,
+
+			create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
+
+			create("Frame")({
+				Name = "Tiles",
+				Position = UDim2.fromOffset(PANEL_PADDING, PANEL_PADDING),
+				Size = UDim2.new(1, -PANEL_PADDING * 2, 1, -PANEL_PADDING * 2),
+				BackgroundTransparency = 1,
+
+				create("UIListLayout")({
+					FillDirection = Enum.FillDirection.Horizontal,
+					SortOrder = Enum.SortOrder.LayoutOrder,
+					Padding = UDim.new(0, TILE_GAP),
+				}),
+
+				tiles,
+			}),
+
+			selectionRing(selectedIndex),
 		})
-	end
-
-	local count = #BlockTypes.List
-
-	return create("Frame")({
-		Name = "BlockPicker",
-		AnchorPoint = Vector2.new(0.5, 1),
-		Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN),
-		Size = UDim2.fromOffset(
-			count * TILE_SIZE + (count - 1) * TILE_GAP + PANEL_PADDING * 2,
-			TILE_SIZE + PANEL_PADDING * 2
-		),
-		BackgroundColor3 = PANEL_COLOR,
-		BackgroundTransparency = 0.2,
-
-		create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
-		create("UIPadding")({
-			PaddingLeft = UDim.new(0, PANEL_PADDING),
-			PaddingRight = UDim.new(0, PANEL_PADDING),
-			PaddingTop = UDim.new(0, PANEL_PADDING),
-			PaddingBottom = UDim.new(0, PANEL_PADDING),
-		}),
-		create("UIListLayout")({
-			FillDirection = Enum.FillDirection.Horizontal,
-			Padding = UDim.new(0, TILE_GAP),
-		}),
-
-		tiles,
-	})
+	end)
 end
 
 return blockPicker
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 0283e30..2080902 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -9,7 +9,6 @@ local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local create = Vide.create
 local mount = Vide.mount
-local show = Vide.show
 local source = Vide.source
 
 -- The UI is authored for a screen 1080 pixels tall and grows on larger screens.
@@ -97,12 +96,12 @@ local function app()
 		create("UIScale")({ Scale = uiScale }),
 		buildButton(),
 
-		show(isBuildMode, function()
-			return BlockPicker({
-				Selected = selected,
-				Select = BlockPlacer.setBlockType,
-			})
-		end),
+		-- The picker mounts itself while open and unmounts after it has slid away.
+		BlockPicker({
+			Open = isBuildMode,
+			Selected = selected,
+			Select = BlockPlacer.setBlockType,
+		}),
 	})
 end
 

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
index 4719bcf..b3780fb 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,6 +1,7 @@
 --[[
 	The block picker shown in build mode: a row of tiles along the bottom of the screen, one per
-	block type. The selected tile has a yellow outline.
+	block type. It slides up from below the screen when shown and back down when hidden, a yellow
+	highlight glides to the selected tile, and tiles sink when pressed.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
@@ -8,7 +9,10 @@ local ReplicatedStorage = game:GetService("ReplicatedStorage")
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
+local cleanup = Vide.cleanup
 local create = Vide.create
+local source = Vide.source
+local spring = Vide.spring
 
 type BlockType = BlockTypes.BlockType
 
@@ -21,40 +25,118 @@ local BOTTOM_MARGIN = 24
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
 local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
+local HIGHLIGHT_THICKNESS = 3
+
+local TILE_COUNT = #BlockTypes.List
+local PANEL_WIDTH = TILE_COUNT * TILE_SIZE + (TILE_COUNT - 1) * TILE_GAP + PANEL_PADDING * 2
+local PANEL_HEIGHT = TILE_SIZE + PANEL_PADDING * 2
+
+local SHOWN_POSITION = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
+-- The extra margin keeps the spring's last few pixels of travel below the screen edge.
+local HIDDEN_POSITION = UDim2.new(0.5, 0, 1, PANEL_HEIGHT + BOTTOM_MARGIN)
+
+local SLIDE_PERIOD = 0.4
+local HIGHLIGHT_PERIOD = 0.25
+local PRESS_PERIOD = 0.2
+-- Below 1 so a released tile bounces back.
+local PRESS_DAMPING = 0.45
+local PRESSED_SCALE = 0.86
+
+local function isPointerPress(input: InputObject): boolean
+	return input.UserInputType == Enum.UserInputType.MouseButton1
+		or input.UserInputType == Enum.UserInputType.Touch
+end
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
-	IsSelected: () -> boolean,
 	Select: () -> (),
 }
 
+--[[
+	Only the face scales, so the button's hit area stays put while the face shrinks under the
+	pointer.
+]]
 local function tile(props: TileProps): TextButton
+	local isPressed = source(false)
+	local releaseConnection: RBXScriptConnection? = nil
+
+	local function release()
+		isPressed(false)
+		if releaseConnection then
+			releaseConnection:Disconnect()
+			releaseConnection = nil
+		end
+	end
+
+	cleanup(release)
+
+	local faceScale = spring(function()
+		return if isPressed() then PRESSED_SCALE else 1
+	end, PRESS_PERIOD, PRESS_DAMPING)
+
 	return create("TextButton")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
 		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
-		BackgroundColor3 = props.BlockType.Color,
+		BackgroundTransparency = 1,
+		Text = "",
 
 		Activated = props.Select,
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
+		InputBegan = function(input: InputObject)
+			if not isPointerPress(input) then
+				return
+			end
+			release()
+			isPressed(true)
+			-- The button gets no InputEnded when the pointer is released off it.
+			releaseConnection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
+				if
+					input.UserInputState == Enum.UserInputState.End
+					or input.UserInputState == Enum.UserInputState.Cancel
+				then
+					release()
+				end
+			end)
+		end,
+
+		create("Frame")({
+			Name = "Face",
+			AnchorPoint = Vector2.new(0.5, 0.5),
+			Position = UDim2.fromScale(0.5, 0.5),
+			Size = UDim2.fromScale(1, 1),
+			BackgroundColor3 = props.BlockType.Color,
+
+			create("UIScale")({ Scale = faceScale }),
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
 
+local function tilePosition(index: number): UDim2
+	return UDim2.fromOffset((index - 1) * (TILE_SIZE + TILE_GAP), 0)
+end
+
+local function indexOf(name: string): number
+	for index, blockType in BlockTypes.List do
+		if blockType.Name == name then
+			return index
+		end
+	end
+	return 1
+end
+
 export type BlockPickerProps = {
 	Selected: () -> string,
 	Select: (name: string) -> (),
+	-- The `present` source of the show() that builds the picker.
+	Present: () -> boolean,
 }
 
 local function blockPicker(props: BlockPickerProps): Frame
@@ -63,27 +145,29 @@ local function blockPicker(props: BlockPickerProps): Frame
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
+	local position = spring(function()
+		return if props.Present() then SHOWN_POSITION else HIDDEN_POSITION
+	end, SLIDE_PERIOD)
+
+	local highlightPosition = spring(function()
+		return tilePosition(indexOf(props.Selected()))
+	end, HIGHLIGHT_PERIOD)
 
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
+		-- Build mode is already off while the picker slides away.
+		Interactable = props.Present,
 
 		create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
 		create("UIPadding")({
@@ -92,13 +176,41 @@ local function blockPicker(props: BlockPickerProps): Frame
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
+		-- Outside the tile row, so the list layout leaves its position to the spring.
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
 
-return blockPicker
+return {
+	new = blockPicker,
+	-- Seconds the picker needs to slide fully off screen once Present turns false.
+	ExitDuration = SLIDE_PERIOD,
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 0283e30..2999473 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -97,11 +97,14 @@ local function app()
 		create("UIScale")({ Scale = uiScale }),
 		buildButton(),
 
-		show(isBuildMode, function()
-			return BlockPicker({
+		-- Turning build mode back on before the exit delay ends reuses the leaving picker.
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
