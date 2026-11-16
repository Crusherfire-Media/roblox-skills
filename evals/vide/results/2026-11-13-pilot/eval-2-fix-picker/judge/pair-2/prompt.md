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
Testers found bugs in the build mode block picker (BlockPicker.luau and Main.client.luau in StarterPlayerScripts). Pressing B enters build mode and shows the picker; pressing B again should leave build mode and hide it.

- Clicking a tile changes which block gets placed, but the yellow outline stays on Brick.
- Hovering a tile should pop up a small info card above it. Instead the output shows "cannot create a new reactive scope inside another reactive scope".
- After going in and out of build mode a few times, old pickers are still on screen, and pressing E skips several blocks at once instead of one. Q and E also still change the block when you're not in build mode.

Please fix these, plus anything else in those two files that's using Vide wrong. Otherwise keep the picker looking and working the way it does now.
</task>

## Rubric

Score each criterion from 1 to 5 for each attempt (1 poor, 3 acceptable, 5 excellent):

1. Fixes the outline: the selected tile's outline follows the selection. The original read `props.Selected()` once in the tile's body (`local isSelected = ...`) and used it as a plain value, so the outline never changed; the fix binds the stroke's properties to a function or source.
2. Fixes the info card error: the original returned `infoCard(...)` from a function child that reads `isHovered()` (a children binding), so the card's own `Text` binding was created inside a reactive scope. The fix builds the card in a stable scope, for example with Vide's `show(isHovered, ...)`, or builds it once and binds its `Visible`.
3. Fixes the stacking Q/E handler: the `UserInputService.InputBegan` connection made in `blockPicker`'s body is disconnected when the picker goes away (for example with Vide's `cleanup`), so handlers don't pile up and Q and E do nothing outside build mode.
4. Fixes the leftover pickers: in the original, destroying the `root` scope did not remove the ScreenGui it had parented to PlayerGui. After the fix, leaving build mode removes the picker's UI, for example with one long-lived mount that uses `show` on a build mode source, or with `cleanup` of the ScreenGui inside the scope.
5. Also fixes the unreported misuses in those files: the `WaitForChild` yield inside the `root` function moves out of the Vide scope, and the selected-name label computed by an `effect` that writes a source becomes a plain function or `derive`.
6. Keeps the look and behavior otherwise unchanged, keeps changes to those two files plus anything strictly needed, and luau-lsp, selene, and StyLua pass on the changed files. Extra supporting files, such as a preview story, count neither for nor against.

## Attempt A

<attempt_a_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [fail] stylua --check passes on the changed Luau files
  Diff in src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau:
  153 153  | 	end
  154 154  | 
  155 155  | 	-- Disconnected when the picker's scope is destroyed, so Q and E only work while it is shown.
  156      |-	cleanup(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
  157      |-		if gameProcessedEvent then
  158      |-			return
  159      |-		end
  160      |-		if input.KeyCode == Enum.KeyCode.Q then
  161      |-			step(-1)
  162      |-		elseif input.KeyCode == Enum.KeyCode.E then
  163      |-			step(1)
- [pass] The tile no longer reads the selection once into a plain local (planted bug 1 is gone)
- [pass] The info card is no longer built directly inside a children binding (planted bug 2 is gone)
- [pass] The selected name is no longer computed by an effect that writes a source
</attempt_a_checks>

<attempt_a_diff>
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index 4ddf4b5..87d0638 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -10,8 +10,10 @@ local UserInputService = game:GetService("UserInputService")
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
+local cleanup = Vide.cleanup
 local create = Vide.create
-local effect = Vide.effect
+local derive = Vide.derive
+local show = Vide.show
 local source = Vide.source
 
 type BlockType = BlockTypes.BlockType
@@ -88,7 +90,9 @@ type TileProps = {
 
 local function tile(props: TileProps): TextButton
 	local isHovered = source(false)
-	local isSelected = props.Selected() == props.BlockType.Name
+	local isSelected = derive(function()
+		return props.Selected() == props.BlockType.Name
+	end)
 
 	return create("TextButton")({
 		Name = props.BlockType.Name,
@@ -109,21 +113,21 @@ local function tile(props: TileProps): TextButton
 		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
 		create("UIStroke")({
 			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
-			Color = if isSelected then SELECTED_COLOR else IDLE_COLOR,
-			Thickness = if isSelected then 3 else 1,
+			Color = function()
+				return if isSelected() then SELECTED_COLOR else IDLE_COLOR
+			end,
+			Thickness = function()
+				return if isSelected() then 3 else 1
+			end,
 		}),
 
-		function()
-			if isHovered() then
-				return infoCard({
-					BlockType = props.BlockType,
-					IsSelected = function()
-						return props.Selected() == props.BlockType.Name
-					end,
-				})
-			end
-			return nil
-		end,
+		-- show() builds the card in its own scope, so the card can have reactive properties.
+		show(isHovered, function()
+			return infoCard({
+				BlockType = props.BlockType,
+				IsSelected = isSelected,
+			})
+		end),
 	})
 end
 
@@ -133,10 +137,9 @@ export type BlockPickerProps = {
 }
 
 local function blockPicker(props: BlockPickerProps): Frame
-	local selectedDisplayName = source("")
-	effect(function()
-		selectedDisplayName(BlockTypes.ByName[props.Selected()].DisplayName)
-	end)
+	local function selectedDisplayName(): string
+		return BlockTypes.ByName[props.Selected()].DisplayName
+	end
 
 	local function step(direction: number)
 		local current = 1
@@ -149,7 +152,8 @@ local function blockPicker(props: BlockPickerProps): Frame
 		props.Select(BlockTypes.List[nextIndex].Name)
 	end
 
-	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
+	-- Disconnected when the picker's scope is destroyed, so Q and E only work while it is shown.
+	cleanup(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
 		if gameProcessedEvent then
 			return
 		end
@@ -158,7 +162,7 @@ local function blockPicker(props: BlockPickerProps): Frame
 		elseif input.KeyCode == Enum.KeyCode.E then
 			step(1)
 		end
-	end)
+	end))
 
 	local tiles = {}
 	for index, blockType in BlockTypes.List do
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 7277fa5..d36fa12 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -6,6 +6,7 @@ local BlockPicker = require(script.Parent.BlockPicker)
 local BlockPlacer = require(script.Parent.BlockPlacer)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
+local cleanup = Vide.cleanup
 local create = Vide.create
 local root = Vide.root
 local source = Vide.source
@@ -17,21 +18,30 @@ BlockPlacer.BlockTypeChanged:Connect(function(name: string)
 	selected(name)
 end)
 
+-- Wait here rather than inside root(): Vide scopes must not yield.
+local playerGui = localPlayer:WaitForChild("PlayerGui")
+
 local destroyPicker: (() -> ())? = nil
 
 local function openPicker()
-	destroyPicker = root(function()
-		local playerGui = localPlayer:WaitForChild("PlayerGui")
+	if destroyPicker then
+		return
+	end
 
-		return create("ScreenGui")({
+	destroyPicker = root(function()
+		local gui = create("ScreenGui")({
 			Name = "BlockPickerGui",
-			Parent = playerGui,
+			ResetOnSpawn = false,
 
 			BlockPicker({
 				Selected = selected,
 				Select = BlockPlacer.setBlockType,
 			}),
 		})
+		-- Vide does not destroy instances it created when a root is destroyed, so do it here.
+		cleanup(gui)
+		gui.Parent = playerGui
+		return gui
 	end)
 end
 

</attempt_a_diff>

## Attempt B

<attempt_b_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] The tile no longer reads the selection once into a plain local (planted bug 1 is gone)
- [pass] The info card is no longer built directly inside a children binding (planted bug 2 is gone)
- [pass] The selected name is no longer computed by an effect that writes a source
</attempt_b_checks>

<attempt_b_diff>
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index 4ddf4b5..af23bc9 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -10,8 +10,9 @@ local UserInputService = game:GetService("UserInputService")
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
+local cleanup = Vide.cleanup
 local create = Vide.create
-local effect = Vide.effect
+local show = Vide.show
 local source = Vide.source
 
 type BlockType = BlockTypes.BlockType
@@ -88,7 +89,9 @@ type TileProps = {
 
 local function tile(props: TileProps): TextButton
 	local isHovered = source(false)
-	local isSelected = props.Selected() == props.BlockType.Name
+	local function isSelected(): boolean
+		return props.Selected() == props.BlockType.Name
+	end
 
 	return create("TextButton")({
 		Name = props.BlockType.Name,
@@ -109,21 +112,20 @@ local function tile(props: TileProps): TextButton
 		create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
 		create("UIStroke")({
 			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
-			Color = if isSelected then SELECTED_COLOR else IDLE_COLOR,
-			Thickness = if isSelected then 3 else 1,
+			Color = function()
+				return if isSelected() then SELECTED_COLOR else IDLE_COLOR
+			end,
+			Thickness = function()
+				return if isSelected() then 3 else 1
+			end,
 		}),
 
-		function()
-			if isHovered() then
-				return infoCard({
-					BlockType = props.BlockType,
-					IsSelected = function()
-						return props.Selected() == props.BlockType.Name
-					end,
-				})
-			end
-			return nil
-		end,
+		show(isHovered, function()
+			return infoCard({
+				BlockType = props.BlockType,
+				IsSelected = isSelected,
+			})
+		end),
 	})
 end
 
@@ -133,10 +135,9 @@ export type BlockPickerProps = {
 }
 
 local function blockPicker(props: BlockPickerProps): Frame
-	local selectedDisplayName = source("")
-	effect(function()
-		selectedDisplayName(BlockTypes.ByName[props.Selected()].DisplayName)
-	end)
+	local function selectedDisplayName(): string
+		return BlockTypes.ByName[props.Selected()].DisplayName
+	end
 
 	local function step(direction: number)
 		local current = 1
@@ -149,16 +150,20 @@ local function blockPicker(props: BlockPickerProps): Frame
 		props.Select(BlockTypes.List[nextIndex].Name)
 	end
 
-	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
-		if gameProcessedEvent then
-			return
-		end
-		if input.KeyCode == Enum.KeyCode.Q then
-			step(-1)
-		elseif input.KeyCode == Enum.KeyCode.E then
-			step(1)
-		end
-	end)
+	cleanup(
+		UserInputService.InputBegan:Connect(
+			function(input: InputObject, gameProcessedEvent: boolean)
+				if gameProcessedEvent then
+					return
+				end
+				if input.KeyCode == Enum.KeyCode.Q then
+					step(-1)
+				elseif input.KeyCode == Enum.KeyCode.E then
+					step(1)
+				end
+			end
+		)
+	)
 
 	local tiles = {}
 	for index, blockType in BlockTypes.List do
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 7277fa5..99020b5 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,16 +1,19 @@
 local Players = game:GetService("Players")
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local RunService = game:GetService("RunService")
 local UserInputService = game:GetService("UserInputService")
 
 local BlockPicker = require(script.Parent.BlockPicker)
 local BlockPlacer = require(script.Parent.BlockPlacer)
 local Vide = require(ReplicatedStorage.Packages.Vide)
+Vide.strict = RunService:IsStudio()
 
+local cleanup = Vide.cleanup
 local create = Vide.create
-local root = Vide.root
+local mount = Vide.mount
 local source = Vide.source
 
-local localPlayer = Players.LocalPlayer
+local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
 
 local selected = source(BlockPlacer.getBlockType())
 BlockPlacer.BlockTypeChanged:Connect(function(name: string)
@@ -19,27 +22,28 @@ end)
 
 local destroyPicker: (() -> ())? = nil
 
-local function openPicker()
-	destroyPicker = root(function()
-		local playerGui = localPlayer:WaitForChild("PlayerGui")
+local function closePicker()
+	if destroyPicker then
+		destroyPicker()
+		destroyPicker = nil
+	end
+end
 
-		return create("ScreenGui")({
+local function openPicker()
+	closePicker()
+	destroyPicker = mount(function()
+		local gui = create("ScreenGui")({
 			Name = "BlockPickerGui",
-			Parent = playerGui,
 
 			BlockPicker({
 				Selected = selected,
 				Select = BlockPlacer.setBlockType,
 			}),
 		})
-	end)
-end
-
-local function closePicker()
-	if destroyPicker then
-		destroyPicker()
-		destroyPicker = nil
-	end
+		-- Destroying a mount scope leaves its root instance parented.
+		cleanup(gui)
+		return gui
+	end, playerGui)
 end
 
 -- B toggles build mode: the picker shows and clicks place blocks only while it is on.

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
