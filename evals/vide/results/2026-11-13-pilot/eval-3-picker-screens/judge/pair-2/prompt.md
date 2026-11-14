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
diff --git a/README.md b/README.md
index cb3047d..33df64e 100644
--- a/README.md
+++ b/README.md
@@ -22,6 +22,16 @@ are ModuleScripts.
 pesde installs packages from `pesde.toml`. Vide 0.4.1 is installed:
 `require(ReplicatedStorage.Packages.Vide)`.
 
+## UI
+
+Build each screen with `StarterPlayerScripts/UI/Screen.luau`. It keeps content clear of the topbar
+and device notches, and scales it so sizes look the same on phones, laptops and 4K monitors. Size
+everything in design units (1 unit = 1 px on a 1080p monitor). Inside a Screen,
+`Responsive.use()` (`UI/Responsive.luau`) gives you live `Size`, `Scale`, `SizeClass`
+(`Compact`/`Medium`/`Expanded`), `IsPortrait` and `Input` (`Touch`/`KeyboardAndMouse`/`Gamepad`).
+Lay out from those so the screen keeps up with rotation, resizing and input changes.
+`BlockPicker.luau` is an example.
+
 ## Checks
 
 Tools come from Rokit (`rokit.toml`). Run each command on its own from the project root:
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index b45f323..c371c3f 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,69 +1,193 @@
 --[[
-	The block picker: a column of tiles down the left side of the screen, one per block type, each
-	with the block's name beside it, under a title naming the selected block.
+	The block picker: one tile per block type under a title naming the selected block.
+
+	It has two layouts and switches between them live, using the Responsive value of the Screen it
+	is built in:
+
+	- Column: down the left side, with each block's name beside its tile. Used with a keyboard and
+	  mouse or a gamepad when the screen is tall enough for it.
+	- Bar: a row of larger tiles along the top centre. Used for touch, because the movement
+	  thumbstick and jump button live in the bottom corners, and on any screen too small for the
+	  column.
+
+	With a keyboard and mouse, each tile shows the number key that selects it.
 ]]
 
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
 local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
+local Responsive = require(script.Parent.UI.Responsive)
 local Vide = require(ReplicatedStorage.Packages.Vide)
 
 local create = Vide.create
+local derive = Vide.derive
 
 type BlockType = BlockTypes.BlockType
 
+-- All sizes are design units (see UI/Responsive.luau).
 local TILE_SIZE = 40
 local TILE_GAP = 6
+-- Touch tiles meet the usual 44 to 48 point minimum for something a thumb has to hit.
+local TOUCH_TILE_SIZE = 48
+local TOUCH_TILE_GAP = 8
 local TILE_RADIUS = 6
+local RING_THICKNESS = 1
+local SELECTED_RING_THICKNESS = 3
 local NAME_WIDTH = 96
+local NAME_TEXT_SIZE = 16
+local KEY_HINT_TEXT_SIZE = 12
 local TITLE_HEIGHT = 30
 local TITLE_MAX_TEXT_SIZE = 24
 local PANEL_PADDING = 10
 local PANEL_RADIUS = 10
+local SCREEN_MARGIN = 20
+local TOUCH_SCREEN_MARGIN = 8
+-- BlockPlacer binds the number keys 1 to this to the first block types.
+local HOTKEY_COUNT = 5
+
 local PANEL_COLOR = Color3.fromRGB(28, 28, 34)
 local SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
-local IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
+local IDLE_RING_COLOR = Color3.fromRGB(70, 70, 80)
 local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
+local KEY_HINT_STROKE_COLOR = Color3.fromRGB(0, 0, 0)
+
+type Metrics = {
+	IsBar: boolean,
+	TileSize: number,
+	Gap: number,
+	-- Width of the title and of the tiles under it.
+	ContentWidth: number,
+	Margin: number,
+	ShowKeyHints: boolean,
+}
+
+local function computeMetrics(
+	size: Vector2,
+	sizeClass: Responsive.SizeClass,
+	input: Responsive.InputKind
+): Metrics
+	local isTouch = input == "Touch"
+	local tileSize = if isTouch then TOUCH_TILE_SIZE else TILE_SIZE
+	local gap = if isTouch then TOUCH_TILE_GAP else TILE_GAP
+	local count = #BlockTypes.List
+
+	local columnHeight = 2 * PANEL_PADDING + TITLE_HEIGHT + count * (tileSize + gap)
+	local columnFits = columnHeight + 2 * SCREEN_MARGIN <= size.Y
+	local isBar = isTouch or sizeClass == "Compact" or not columnFits
+
+	return {
+		IsBar = isBar,
+		TileSize = tileSize,
+		Gap = gap,
+		ContentWidth = if isBar
+			then count * tileSize + (count - 1) * gap
+			else tileSize + gap + NAME_WIDTH,
+		Margin = if isTouch then TOUCH_SCREEN_MARGIN else SCREEN_MARGIN,
+		ShowKeyHints = input == "KeyboardAndMouse",
+	}
+end
 
 type TileProps = {
 	BlockType: BlockType,
-	LayoutOrder: number,
+	Index: number,
+	Metrics: () -> Metrics,
 	IsSelected: () -> boolean,
 	Select: () -> (),
 }
 
 local function tile(props: TileProps): TextButton
+	local metrics = props.Metrics
+
+	local ringThickness = function()
+		return if props.IsSelected() then SELECTED_RING_THICKNESS else RING_THICKNESS
+	end
+
 	return create("TextButton")({
 		Name = props.BlockType.Name,
-		LayoutOrder = props.LayoutOrder,
-		Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TILE_SIZE),
+		LayoutOrder = props.Index,
 		BackgroundTransparency = 1,
+		Size = function()
+			local current = metrics()
+			local width = if current.IsBar then current.TileSize else current.ContentWidth
+			return UDim2.fromOffset(width, current.TileSize)
+		end,
 
 		Activated = props.Select,
 
+		-- The swatch's own background is the ring around the block colour, so the ring scales
+		-- with the rest of the UI.
 		create("Frame")({
 			Name = "Swatch",
-			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
-			BackgroundColor3 = props.BlockType.Color,
+			Size = function()
+				local tileSize = metrics().TileSize
+				return UDim2.fromOffset(tileSize, tileSize)
+			end,
+			BackgroundColor3 = function()
+				return if props.IsSelected() then SELECTED_COLOR else IDLE_RING_COLOR
+			end,
 
 			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
-			create("UIStroke")({
-				Color = function()
-					return if props.IsSelected() then SELECTED_COLOR else IDLE_STROKE_COLOR
+			create("UIPadding")({
+				PaddingLeft = function()
+					return UDim.new(0, ringThickness())
 				end,
-				Thickness = function()
-					return if props.IsSelected() then 3 else 1
+				PaddingRight = function()
+					return UDim.new(0, ringThickness())
+				end,
+				PaddingTop = function()
+					return UDim.new(0, ringThickness())
+				end,
+				PaddingBottom = function()
+					return UDim.new(0, ringThickness())
 				end,
 			}),
+
+			create("Frame")({
+				Name = "Fill",
+				Size = UDim2.fromScale(1, 1),
+				BackgroundColor3 = props.BlockType.Color,
+
+				create("UICorner")({
+					CornerRadius = function()
+						return UDim.new(0, math.max(0, TILE_RADIUS - ringThickness()))
+					end,
+				}),
+
+				create("TextLabel")({
+					Name = "KeyHint",
+					Visible = function()
+						return metrics().ShowKeyHints and props.Index <= HOTKEY_COUNT
+					end,
+					Position = UDim2.fromOffset(3, 1),
+					Size = UDim2.fromOffset(KEY_HINT_TEXT_SIZE, KEY_HINT_TEXT_SIZE),
+					BackgroundTransparency = 1,
+					Font = Enum.Font.GothamBold,
+					TextSize = KEY_HINT_TEXT_SIZE,
+					TextColor3 = TEXT_COLOR,
+					TextStrokeColor3 = KEY_HINT_STROKE_COLOR,
+					TextStrokeTransparency = 0.3,
+					TextXAlignment = Enum.TextXAlignment.Left,
+					TextYAlignment = Enum.TextYAlignment.Top,
+					Text = tostring(props.Index),
+				}),
+			}),
 		}),
 
 		create("TextLabel")({
 			Name = "BlockName",
-			Position = UDim2.fromOffset(TILE_SIZE + TILE_GAP, 0),
-			Size = UDim2.fromOffset(NAME_WIDTH, TILE_SIZE),
+			Visible = function()
+				return not metrics().IsBar
+			end,
+			Position = function()
+				local current = metrics()
+				return UDim2.fromOffset(current.TileSize + current.Gap, 0)
+			end,
+			Size = function()
+				return UDim2.fromOffset(NAME_WIDTH, metrics().TileSize)
+			end,
 			BackgroundTransparency = 1,
 			Font = Enum.Font.Gotham,
-			TextSize = 16,
+			TextSize = NAME_TEXT_SIZE,
 			TextColor3 = TEXT_COLOR,
 			TextXAlignment = Enum.TextXAlignment.Left,
 			Text = props.BlockType.DisplayName,
@@ -76,12 +200,21 @@ export type BlockPickerProps = {
 	Select: (name: string) -> (),
 }
 
+--[[
+	Must be built inside a Screen.
+]]
 local function blockPicker(props: BlockPickerProps): Frame
+	local responsive = Responsive.use()
+	local metrics = derive(function()
+		return computeMetrics(responsive.Size(), responsive.SizeClass(), responsive.Input())
+	end)
+
 	local tiles = {}
 	for index, blockType in BlockTypes.List do
 		tiles[index] = tile({
 			BlockType = blockType,
-			LayoutOrder = index + 1,
+			Index = index,
+			Metrics = metrics,
 			IsSelected = function()
 				return props.Selected() == blockType.Name
 			end,
@@ -93,8 +226,16 @@ local function blockPicker(props: BlockPickerProps): Frame
 
 	return create("Frame")({
 		Name = "BlockPicker",
-		AnchorPoint = Vector2.new(0, 0.5),
-		Position = UDim2.new(0, 20, 0.5, 0),
+		AnchorPoint = function()
+			return if metrics().IsBar then Vector2.new(0.5, 0) else Vector2.new(0, 0.5)
+		end,
+		Position = function()
+			local current = metrics()
+			return if current.IsBar
+				then UDim2.new(0.5, 0, 0, current.Margin)
+				else UDim2.new(0, current.Margin, 0.5, 0)
+		end,
+		Size = UDim2.new(),
 		AutomaticSize = Enum.AutomaticSize.XY,
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
@@ -108,18 +249,26 @@ local function blockPicker(props: BlockPickerProps): Frame
 		}),
 		create("UIListLayout")({
 			FillDirection = Enum.FillDirection.Vertical,
-			Padding = UDim.new(0, TILE_GAP),
+			Padding = function()
+				return UDim.new(0, metrics().Gap)
+			end,
 		}),
 
 		create("TextLabel")({
 			Name = "Title",
 			LayoutOrder = 1,
-			Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TITLE_HEIGHT),
+			Size = function()
+				return UDim2.fromOffset(metrics().ContentWidth, TITLE_HEIGHT)
+			end,
 			BackgroundTransparency = 1,
 			Font = Enum.Font.GothamBold,
 			TextScaled = true,
 			TextColor3 = TEXT_COLOR,
-			TextXAlignment = Enum.TextXAlignment.Left,
+			TextXAlignment = function()
+				return if metrics().IsBar
+					then Enum.TextXAlignment.Center
+					else Enum.TextXAlignment.Left
+			end,
 			Text = function()
 				return BlockTypes.ByName[props.Selected()].DisplayName
 			end,
@@ -127,7 +276,26 @@ local function blockPicker(props: BlockPickerProps): Frame
 			create("UITextSizeConstraint")({ MaxTextSize = TITLE_MAX_TEXT_SIZE }),
 		}),
 
-		tiles,
+		create("Frame")({
+			Name = "Tiles",
+			LayoutOrder = 2,
+			Size = UDim2.new(),
+			AutomaticSize = Enum.AutomaticSize.XY,
+			BackgroundTransparency = 1,
+
+			create("UIListLayout")({
+				FillDirection = function()
+					return if metrics().IsBar
+						then Enum.FillDirection.Horizontal
+						else Enum.FillDirection.Vertical
+				end,
+				Padding = function()
+					return UDim.new(0, metrics().Gap)
+				end,
+			}),
+
+			tiles,
+		}),
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 04bc27a..277570a 100644
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
+		Content = function()
+			return BlockPicker({
+				Selected = selected,
+				Select = BlockPlacer.setBlockType,
+			})
+		end,
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau
new file mode 100644
index 0000000..4631bbe
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Responsive.luau
@@ -0,0 +1,110 @@
+--[[
+	Shared screen-size and input information for every UI screen.
+
+	Screens are laid out in "design units": one design unit is one pixel on a 1080p monitor. Each
+	Screen (see Screen.luau) measures the area it can draw in, picks a UI scale so content keeps
+	roughly the same physical size on bigger monitors, and hands its contents a Responsive value
+	through `Responsive.context`. Components read it with `Responsive.use()` and react to:
+
+	- Size: the drawable area in design units (already excludes the topbar and device notches).
+	- Scale: design units to screen pixels. 1 on phones, tablets, laptops and 1080p; larger above.
+	- SizeClass: "Compact" (phones, tiny windows), "Medium" (tablets, small laptops) or
+	  "Expanded" (desktop monitors).
+	- IsPortrait: whether the drawable area is taller than it is wide.
+	- Input: what the player is using right now: "Touch", "KeyboardAndMouse" or "Gamepad".
+
+	All of these are Vide sources, so anything built from them updates when the player rotates a
+	device, resizes the window, or switches input mid-session.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+local UserInputService = game:GetService("UserInputService")
+
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local source = Vide.source
+
+export type SizeClass = "Compact" | "Medium" | "Expanded"
+export type InputKind = "Touch" | "KeyboardAndMouse" | "Gamepad"
+
+export type Responsive = {
+	Size: () -> Vector2,
+	Scale: () -> number,
+	SizeClass: () -> SizeClass,
+	IsPortrait: () -> boolean,
+	Input: () -> InputKind,
+}
+
+-- Shorter side of the drawable area on a 1080p monitor once the topbar is taken out. Screens at
+-- or below this keep a scale of 1; bigger ones scale up in proportion.
+local REFERENCE_SHORT_SIDE = 1020
+local MAX_SCALE = 3
+-- Scale moves in steps of this size so dragging a window edge doesn't relayout every pixel.
+local SCALE_STEP = 0.05
+
+-- Shorter side, in design units, below which each size class starts.
+local MEDIUM_MIN_SHORT_SIDE = 600
+local EXPANDED_MIN_SHORT_SIDE = 900
+
+local function toInputKind(preferredInput: Enum.PreferredInput): InputKind
+	if preferredInput == Enum.PreferredInput.Touch then
+		return "Touch"
+	elseif
+		preferredInput == Enum.PreferredInput.Gamepad
+		or preferredInput == Enum.PreferredInput.MicroGamepad
+	then
+		return "Gamepad"
+	end
+	return "KeyboardAndMouse"
+end
+
+local input = source(toInputKind(UserInputService.PreferredInput))
+UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
+	input(toInputKind(UserInputService.PreferredInput))
+end)
+
+local Responsive = {}
+
+--[[
+	The player's current input kind. Usable anywhere, inside a Screen or not.
+]]
+Responsive.input = function(): InputKind
+	return input()
+end
+
+--[[
+	Design units to screen pixels for a drawable area of the given size in pixels.
+]]
+function Responsive.computeScale(pixelSize: Vector2): number
+	local shortSide = math.min(pixelSize.X, pixelSize.Y)
+	local raw = math.clamp(shortSide / REFERENCE_SHORT_SIDE, 1, MAX_SCALE)
+	return math.max(1, math.floor(raw / SCALE_STEP) * SCALE_STEP)
+end
+
+--[[
+	The size class for a drawable area of the given size in design units.
+]]
+function Responsive.computeSizeClass(size: Vector2): SizeClass
+	local shortSide = math.min(size.X, size.Y)
+	if shortSide >= EXPANDED_MIN_SHORT_SIDE then
+		return "Expanded"
+	elseif shortSide >= MEDIUM_MIN_SHORT_SIDE then
+		return "Medium"
+	end
+	return "Compact"
+end
+
+-- Set by Screen around its contents. Holds nil outside a Screen.
+Responsive.context = Vide.context(nil :: Responsive?)
+
+--[[
+	The Responsive value of the Screen this component is being built inside. Call it while
+	building a component, not later from an event handler.
+]]
+function Responsive.use(): Responsive
+	local responsive = Responsive.context()
+	assert(responsive, "Responsive.use() must be called inside a Screen")
+	return responsive
+end
+
+return Responsive
diff --git a/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
new file mode 100644
index 0000000..b817cae
--- /dev/null
+++ b/src/StarterPlayer/StarterPlayerScripts/UI/Screen.luau
@@ -0,0 +1,79 @@
+--[[
+	A ScreenGui that every UI screen should be built in.
+
+	It keeps its contents out of the topbar and device notches, measures the area left over, and
+	scales its contents so a size in design units looks about the same on a phone, a laptop and a
+	4K monitor. Contents fill a "Root" frame that covers that area in design units, so
+	UDim2.fromScale(1, 1) is the whole drawable area and offsets are design units.
+
+	Contents are built by `Content`, inside the Screen's Responsive context; call
+	`Responsive.use()` from any component in there to lay out by size class, orientation and
+	input kind.
+]]
+
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+
+local Responsive = require(script.Parent.Responsive)
+local Vide = require(ReplicatedStorage.Packages.Vide)
+
+local changed = Vide.changed
+local create = Vide.create
+local derive = Vide.derive
+local source = Vide.source
+
+export type ScreenProps = {
+	Name: string,
+	DisplayOrder: number?,
+	Content: () -> any,
+}
+
+local function screen(props: ScreenProps): ScreenGui
+	local pixelSize = source(Vector2.zero)
+	local scale = derive(function()
+		return Responsive.computeScale(pixelSize())
+	end)
+	local size = derive(function()
+		return pixelSize() / scale()
+	end)
+
+	local responsive: Responsive.Responsive = {
+		Size = size,
+		Scale = scale,
+		SizeClass = derive(function()
+			return Responsive.computeSizeClass(size())
+		end),
+		IsPortrait = derive(function()
+			local current = size()
+			return current.Y > current.X
+		end),
+		Input = Responsive.input,
+	}
+
+	return create("ScreenGui")({
+		Name = props.Name,
+		DisplayOrder = props.DisplayOrder or 0,
+		ResetOnSpawn = false,
+		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
+
+		changed("AbsoluteSize", function(absoluteSize: Vector2)
+			pixelSize(absoluteSize)
+		end),
+
+		create("Frame")({
+			Name = "Root",
+			BackgroundTransparency = 1,
+			-- Sized at 1 / scale so that, once UIScale multiplies it by scale, it exactly covers
+			-- the ScreenGui.
+			Size = function()
+				local current = scale()
+				return UDim2.fromScale(1 / current, 1 / current)
+			end,
+
+			create("UIScale")({ Scale = scale }),
+
+			Responsive.context(responsive, props.Content),
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
diff --git a/src/ReplicatedStorage/Shared/UI/Screen.luau b/src/ReplicatedStorage/Shared/UI/Screen.luau
new file mode 100644
index 0000000..68d1d0d
--- /dev/null
+++ b/src/ReplicatedStorage/Shared/UI/Screen.luau
@@ -0,0 +1,167 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	The facts about the player's screen that UI lays out from: viewport size,
+	topbar inset, whether touch controls are up, and the TV size class. Each
+	getter reads Vide sources, so bind it to a property or call it inside a
+	binding and the UI follows the live screen as the window resizes, a
+	tablet rotates, or a keyboard is plugged in.
+
+	UI is authored for a screen 1080 tall, in offsets. Larger screens grow
+	it with one UIScale per ScreenGui (gameScreenGui adds it), and smaller
+	screens change layout instead of shrinking.
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
+export type SimulatedScreen = {
+	Size: Vector2,
+	Inset: Vector2?,
+	IsTouch: boolean?,
+	IsLargeDisplay: boolean?,
+}
+
+const REFERENCE_SHORT_SIDE = 1080
+const MINIMUM_SCALE = 1
+const MAXIMUM_SCALE = 3
+-- A TV is read from a couch.
+const LARGE_DISPLAY_BOOST = 1.25
+-- Phones held sideways are 360 to 440 tall; tablets start near 600.
+const PHONE_SHORT_SIDE = 600
+const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)
+
+local Module = {}
+
+local realViewport = source(FALLBACK_VIEWPORT)
+local realInset = source(Vector2.zero)
+local prefersTouch = source(false)
+local isLargeDisplay = source(false)
+local isSimulating = false
+local viewportConnection: RBXScriptConnection? = nil
+
+local function refresh()
+	if isSimulating then
+		return
+	end
+
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
+	How much the whole UI grows on this screen: the short side over 1080,
+	never below 1. Bind it to a UIScale under every ScreenGui the game builds.
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
+	Whether touch is the primary input, which is when Roblox shows its
+	thumbstick and jump button.
+]]
+function Module.isTouch(): boolean
+	return prefersTouch()
+end
+
+--[[
+	Whether the screen is phone sized: a short side under 600 UI units. A
+	desktop window dragged that small counts too.
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
+	return prefersTouch() or Module.isPhone()
+end
+
+--[[
+	Replaces the live readings with the given screen, for a story or a spec.
+	Pass nil to go back to them.
+]]
+function Module:Simulate(screen: SimulatedScreen?)
+	isSimulating = screen ~= nil
+	if not screen then
+		refresh()
+		return
+	end
+
+	batch(function()
+		realViewport(screen.Size)
+		realInset(screen.Inset or Vector2.zero)
+		prefersTouch(screen.IsTouch == true)
+		isLargeDisplay(screen.IsLargeDisplay == true)
+	end)
+end
+
+-- UI Labs loads a fresh copy of this module on every reload, and a connection
+-- made in edit mode would keep each copy in memory.
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
diff --git a/src/ReplicatedStorage/Shared/UI/gameScreenGui.luau b/src/ReplicatedStorage/Shared/UI/gameScreenGui.luau
new file mode 100644
index 0000000..bec0272
--- /dev/null
+++ b/src/ReplicatedStorage/Shared/UI/gameScreenGui.luau
@@ -0,0 +1,35 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	Builds a ScreenGui for the game's own UI, with the UIScale that grows it
+	on screens taller than 1080. Build every game screen with this, so none
+	misses the scale. Keep GUIs that place things in real pixels (from
+	WorldToViewportPoint or AbsolutePosition) out of it.
+]]
+
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const Screen = require("./Screen")
+
+const create = Vide.create
+
+export type GameScreenGuiProps = {
+	Name: string,
+	DisplayOrder: number?,
+	-- Anything a Vide create table accepts as children: instances, arrays,
+	-- or children bindings.
+	Children: { any },
+}
+
+local function gameScreenGui(props: GameScreenGuiProps): ScreenGui
+	return create("ScreenGui")({
+		Name = props.Name,
+		DisplayOrder = props.DisplayOrder or 0,
+
+		create("UIScale")({ Scale = Screen.uiScale }),
+		props.Children,
+	})
+end
+
+return gameScreenGui
diff --git a/src/ServerScriptService/Stories/BlockPicker.story.luau b/src/ServerScriptService/Stories/BlockPicker.story.luau
new file mode 100644
index 0000000..d29bffd
--- /dev/null
+++ b/src/ServerScriptService/Stories/BlockPicker.story.luau
@@ -0,0 +1,50 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	The block picker in both layouts. Clicking a tile selects it, as it would
+	in game.
+]]
+
+const BlockPicker = require("@game/StarterPlayer/StarterPlayerScripts/BlockPicker")
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
+
+const source = Vide.source
+
+-- Plain values, since the project has no UI Labs utility package for ordered
+-- or grouped controls.
+const CONTROLS = {
+	-- Off: the desktop column with names. On: the touch row.
+	IsRowLayout = false,
+}
+
+type StoryProps = {
+	controls: {
+		IsRowLayout: () -> boolean,
+	},
+	target: Frame,
+}
+
+local function story(props: StoryProps)
+	local selected = source(BlockTypes.List[1].Name)
+
+	return BlockPicker({
+		Selected = selected,
+		Select = function(name: string)
+			selected(name)
+		end,
+		Layout = function(): BlockPicker.Layout
+			return if props.controls.IsRowLayout() then "Row" else "Column"
+		end,
+		AnchorPoint = Vector2.new(0.5, 0.5),
+		Position = UDim2.fromScale(0.5, 0.5),
+	})
+end
+
+return {
+	summary = "The block picker: a named column for desktop, a thumb-sized row for touch.",
+	vide = Vide,
+	controls = CONTROLS,
+	story = story,
+}
diff --git a/src/ServerScriptService/Stories/GameUI.storybook.luau b/src/ServerScriptService/Stories/GameUI.storybook.luau
new file mode 100644
index 0000000..f9087ca
--- /dev/null
+++ b/src/ServerScriptService/Stories/GameUI.storybook.luau
@@ -0,0 +1,12 @@
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	UI Labs storybook for the game's UI. Studio-only: nothing in the game
+	requires this folder.
+]]
+
+return {
+	name = "Game UI",
+	storyRoots = { script.Parent },
+}
diff --git a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
index b45f323..caca854 100644
--- a/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau
@@ -1,49 +1,99 @@
---[[
-	The block picker: a column of tiles down the left side of the screen, one per block type, each
-	with the block's name beside it, under a title naming the selected block.
+--!strict
+--@author: Crusherfire
+--@date: 2026-11-13
+--[[@description:
+	The block picker: one tile per block type under a title naming the
+	selected block. The Column layout stacks the tiles with each block's name
+	beside it, for mouse and keyboard. The Row layout lines up larger tiles
+	with no names, sized for thumbs. The screen that mounts it picks the
+	layout and places it.
 ]]
 
-local ReplicatedStorage = game:GetService("ReplicatedStorage")
+const BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
+const Vide = require("@game/ReplicatedStorage/Packages/Vide")
 
-local BlockTypes = require(ReplicatedStorage.Shared.BlockTypes)
-local Vide = require(ReplicatedStorage.Packages.Vide)
-
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
+	TileSize: number,
+	TileGap: number,
+	PanelPadding: number,
+	TitleHeight: number,
+	TitleTextSize: number,
+	ShowsNames: boolean,
+	TileDirection: Enum.FillDirection,
+}
+
+const COLUMN: Metrics = table.freeze({
+	TileSize = 40,
+	TileGap = 6,
+	PanelPadding = 10,
+	TitleHeight = 30,
+	TitleTextSize = 22,
+	ShowsNames = true,
+	TileDirection = Enum.FillDirection.Vertical,
+})
+-- Tiles stay above 44, the smallest size a thumb hits reliably.
+const ROW: Metrics = table.freeze({
+	TileSize = 52,
+	TileGap = 8,
+	PanelPadding = 8,
+	TitleHeight = 22,
+	TitleTextSize = 18,
+	ShowsNames = false,
+	TileDirection = Enum.FillDirection.Horizontal,
+})
+
+const NAME_WIDTH = 96
+const NAME_TEXT_SIZE = 16
+const TILE_RADIUS = 6
+const PANEL_RADIUS = 10
+const SELECTED_STROKE = 3
+const IDLE_STROKE = 1
+const PANEL_COLOR = Color3.fromRGB(28, 28, 34)
+const SELECTED_COLOR = Color3.fromRGB(255, 200, 60)
+const IDLE_STROKE_COLOR = Color3.fromRGB(70, 70, 80)
+const TEXT_COLOR = Color3.fromRGB(240, 240, 240)
 
 type TileProps = {
 	BlockType: BlockType,
 	LayoutOrder: number,
+	Metrics: () -> Metrics,
 	IsSelected: () -> boolean,
 	Select: () -> (),
 }
 
+local function tileWidth(metrics: Metrics): number
+	if metrics.ShowsNames then
+		return metrics.TileSize + metrics.TileGap + NAME_WIDTH
+	end
+	return metrics.TileSize
+end
+
 local function tile(props: TileProps): TextButton
 	return create("TextButton")({
 		Name = props.BlockType.Name,
 		LayoutOrder = props.LayoutOrder,
-		Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TILE_SIZE),
+		Size = function()
+			local metrics = props.Metrics()
+			return UDim2.fromOffset(tileWidth(metrics), metrics.TileSize)
+		end,
 		BackgroundTransparency = 1,
 
 		Activated = props.Select,
 
 		create("Frame")({
 			Name = "Swatch",
-			Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
+			Size = function()
+				local tileSize = props.Metrics().TileSize
+				return UDim2.fromOffset(tileSize, tileSize)
+			end,
 			BackgroundColor3 = props.BlockType.Color,
 
 			create("UICorner")({ CornerRadius = UDim.new(0, TILE_RADIUS) }),
@@ -52,20 +102,29 @@ local function tile(props: TileProps): TextButton
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
+			Visible = function()
+				return props.Metrics().ShowsNames
+			end,
+			Position = function()
+				local metrics = props.Metrics()
+				return UDim2.fromOffset(metrics.TileSize + metrics.TileGap, 0)
+			end,
+			Size = function()
+				return UDim2.fromOffset(NAME_WIDTH, props.Metrics().TileSize)
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
@@ -74,14 +133,33 @@ end
 export type BlockPickerProps = {
 	Selected: () -> string,
 	Select: (name: string) -> (),
+	Layout: (Layout | () -> Layout)?,
+	AnchorPoint: (Vector2 | () -> Vector2)?,
+	Position: (UDim2 | () -> UDim2)?,
 }
 
 local function blockPicker(props: BlockPickerProps): Frame
+	-- Derived, so bindings rerun when the layout flips, not on every pixel of
+	-- a window resize.
+	local metrics = derive(function(): Metrics
+		return if read(props.Layout) == "Row" then ROW else COLUMN
+	end)
+
+	local function contentWidth(): number
+		local current = metrics()
+		if current.ShowsNames then
+			return tileWidth(current)
+		end
+		local count = #BlockTypes.List
+		return count * current.TileSize + (count - 1) * current.TileGap
+	end
+
 	local tiles = {}
 	for index, blockType in BlockTypes.List do
 		tiles[index] = tile({
 			BlockType = blockType,
-			LayoutOrder = index + 1,
+			LayoutOrder = index,
+			Metrics = metrics,
 			IsSelected = function()
 				return props.Selected() == blockType.Name
 			end,
@@ -91,43 +169,70 @@ local function blockPicker(props: BlockPickerProps): Frame
 		})
 	end
 
+	local function padding(): UDim
+		return UDim.new(0, metrics().PanelPadding)
+	end
+
+	local function gap(): UDim
+		return UDim.new(0, metrics().TileGap)
+	end
+
 	return create("Frame")({
 		Name = "BlockPicker",
-		AnchorPoint = Vector2.new(0, 0.5),
-		Position = UDim2.new(0, 20, 0.5, 0),
+		AnchorPoint = props.AnchorPoint,
+		Position = props.Position,
+		Size = UDim2.new(),
 		AutomaticSize = Enum.AutomaticSize.XY,
 		BackgroundColor3 = PANEL_COLOR,
 		BackgroundTransparency = 0.2,
 
 		create("UICorner")({ CornerRadius = UDim.new(0, PANEL_RADIUS) }),
 		create("UIPadding")({
-			PaddingLeft = UDim.new(0, PANEL_PADDING),
-			PaddingRight = UDim.new(0, PANEL_PADDING),
-			PaddingTop = UDim.new(0, PANEL_PADDING),
-			PaddingBottom = UDim.new(0, PANEL_PADDING),
+			PaddingLeft = padding,
+			PaddingRight = padding,
+			PaddingTop = padding,
+			PaddingBottom = padding,
 		}),
 		create("UIListLayout")({
 			FillDirection = Enum.FillDirection.Vertical,
-			Padding = UDim.new(0, TILE_GAP),
+			Padding = gap,
 		}),
 
 		create("TextLabel")({
 			Name = "Title",
 			LayoutOrder = 1,
-			Size = UDim2.fromOffset(TILE_SIZE + TILE_GAP + NAME_WIDTH, TITLE_HEIGHT),
+			Size = function()
+				return UDim2.fromOffset(contentWidth(), metrics().TitleHeight)
+			end,
 			BackgroundTransparency = 1,
 			Font = Enum.Font.GothamBold,
-			TextScaled = true,
+			TextSize = function()
+				return metrics().TitleTextSize
+			end,
 			TextColor3 = TEXT_COLOR,
 			TextXAlignment = Enum.TextXAlignment.Left,
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
+			Size = UDim2.new(),
+			AutomaticSize = Enum.AutomaticSize.XY,
+			BackgroundTransparency = 1,
+
+			create("UIListLayout")({
+				FillDirection = function()
+					return metrics().TileDirection
+				end,
+				Padding = gap,
+			}),
+
+			tiles,
+		}),
 	})
 end
 
diff --git a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
index 04bc27a..aac7d25 100644
--- a/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
+++ b/src/StarterPlayer/StarterPlayerScripts/Main.client.luau
@@ -1,13 +1,25 @@
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
+const Screen = require("@game/ReplicatedStorage/Shared/UI/Screen")
+const gameScreenGui = require("@game/ReplicatedStorage/Shared/UI/gameScreenGui")
+
+Vide.strict = RunService:IsStudio()
+
+const mount = Vide.mount
+const source = Vide.source
+
+-- Desktop: the column hugs the left edge, centered vertically.
+const COLUMN_ANCHOR = Vector2.new(0, 0.5)
+const COLUMN_POSITION = UDim2.new(0, 20, 0.5, 0)
+-- Touch: the row sits in the top right, clear of the thumbstick (left 40
+-- percent, lower two thirds) and the jump button (lower right).
+const ROW_ANCHOR = Vector2.new(1, 0)
+const ROW_POSITION = UDim2.new(1, -12, 0, 12)
 
 local localPlayer = Players.LocalPlayer
 local playerGui = localPlayer:WaitForChild("PlayerGui")
@@ -17,14 +29,26 @@ BlockPlacer.BlockTypeChanged:Connect(function(name: string)
 	selected(name)
 end)
 
+local function pickerLayout(): BlockPicker.Layout
+	return if Screen.isTouchLayout() then "Row" else "Column"
+end
+
 local function app()
-	return create("ScreenGui")({
+	return gameScreenGui({
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
+				Layout = pickerLayout,
+				AnchorPoint = function()
+					return if pickerLayout() == "Row" then ROW_ANCHOR else COLUMN_ANCHOR
+				end,
+				Position = function()
+					return if pickerLayout() == "Row" then ROW_POSITION else COLUMN_POSITION
+				end,
+			}),
+		},
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
