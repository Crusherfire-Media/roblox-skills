--[[
	Live facts about the player's screen and input device, as Vide sources, for every UI screen to
	build on. Each one updates when the player resizes the window, rotates a device, or switches
	between touch, keyboard and mouse, and gamepad, and only notifies when its value actually
	changes.

	UI is designed in "design units": the size things should be on a 1080p monitor with a mouse.
	`scale()` turns design units into screen pixels for the current device, and `Screen` applies it
	with a UIScale, so components write fixed design-unit sizes and never read `scale()`
	themselves.

	- `inputKind()`: "KeyboardMouse", "Touch" or "Gamepad", following the same signal Roblox's
	  own controls use (for example, the touch thumbstick hides when a keyboard is used).
	- `scale()`: screen pixels per design unit.
	- `canvasSize()`: the screen's size in design units, which is the space components lay out in.
	- `sizeClass()`: "Compact" (phones, tiny windows), "Medium" (tablets, small laptop windows) or
	  "Large" (laptops and monitors), from `canvasSize()`.
	- `viewportSize()`: the raw viewport size in screen pixels.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Vide = require(ReplicatedStorage.Packages.Vide)

local source = Vide.source

export type InputKind = "KeyboardMouse" | "Touch" | "Gamepad"
export type SizeClass = "Compact" | "Medium" | "Large"

-- Pointer devices scale with the screen's short side, relative to a 1080p screen. Desktop clients
-- report the viewport in physical pixels, so a 4K monitor gets 2x and a 768p laptop gets the
-- minimum.
local POINTER_REFERENCE = 1080
local POINTER_MIN_SCALE = 0.8
local POINTER_MAX_SCALE = 3

-- Touch clients report the viewport in points (a phone is around 390 tall). The minimum keeps a
-- 40-unit tile at 48 points, a comfortable finger target; tablets grow up to the maximum.
local TOUCH_REFERENCE = 600
local TOUCH_MIN_SCALE = 1.2
local TOUCH_MAX_SCALE = 1.6

-- Gamepad players usually sit further from the screen.
local GAMEPAD_BOOST = 1.25

-- Canvas thresholds, in design units, for the size classes.
local COMPACT_MAX_HEIGHT = 480
local COMPACT_MAX_WIDTH = 600
local MEDIUM_MAX_HEIGHT = 800

local function readInputKind(): InputKind
	local preferred = UserInputService.PreferredInput
	if preferred == Enum.PreferredInput.Touch then
		return "Touch"
	elseif
		preferred == Enum.PreferredInput.Gamepad
		or preferred == Enum.PreferredInput.MicroGamepad
	then
		return "Gamepad"
	end
	return "KeyboardMouse"
end

local function computeScale(viewport: Vector2, kind: InputKind): number
	local shortSide = math.max(math.min(viewport.X, viewport.Y), 1)
	if kind == "Touch" then
		return math.clamp(shortSide / TOUCH_REFERENCE, TOUCH_MIN_SCALE, TOUCH_MAX_SCALE)
	end
	local scale = math.clamp(shortSide / POINTER_REFERENCE, POINTER_MIN_SCALE, POINTER_MAX_SCALE)
	if kind == "Gamepad" then
		scale *= GAMEPAD_BOOST
	end
	return scale
end

local function computeSizeClass(canvas: Vector2): SizeClass
	if canvas.Y < COMPACT_MAX_HEIGHT or canvas.X < COMPACT_MAX_WIDTH then
		return "Compact"
	elseif canvas.Y < MEDIUM_MAX_HEIGHT then
		return "Medium"
	end
	return "Large"
end

local viewportSize = source(Vector2.new(1920, 1080))
local inputKind = source(readInputKind())
local scale = source(1)
local canvasSize = source(Vector2.new(1920, 1080))
local sizeClass = source("Large" :: SizeClass)

local function recompute()
	local viewport = viewportSize()
	local newScale = computeScale(viewport, inputKind())
	local canvas = viewport / newScale
	scale(newScale)
	canvasSize(canvas)
	sizeClass(computeSizeClass(canvas))
end

local cameraConnection: RBXScriptConnection? = nil

local function watchCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local function update()
		viewportSize(camera.ViewportSize)
		recompute()
	end
	cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
	inputKind(readInputKind())
	recompute()
end)
watchCamera()
recompute()

local Responsive = {
	viewportSize = viewportSize :: () -> Vector2,
	inputKind = inputKind :: () -> InputKind,
	scale = scale :: () -> number,
	canvasSize = canvasSize :: () -> Vector2,
	sizeClass = sizeClass :: () -> SizeClass,
}

return table.freeze(Responsive)
