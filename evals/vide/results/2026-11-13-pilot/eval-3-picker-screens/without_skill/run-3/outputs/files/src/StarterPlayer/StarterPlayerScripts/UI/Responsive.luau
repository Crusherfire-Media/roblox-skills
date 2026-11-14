--[[
	Reactive facts about the player's screen and input device, shared by every UI screen.

	Screens are authored in design units: one unit is one pixel on a 1080p monitor, or one point on
	a phone or tablet. Each Screen root applies `Responsive.scale()` with a UIScale, so sizes written
	in design units come out at a sensible physical size on every device.

	Everything here is a Vide source or a plain function that reads sources, so reading it inside a
	property function or effect keeps that UI up to date as the player rotates a device, resizes the
	window, or switches between touch, keyboard and mouse, and gamepad.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Vide = require(ReplicatedStorage.Packages.Vide)

local source = Vide.source

export type InputMode = "Touch" | "Gamepad" | "KeyboardMouse"

-- Smallest comfortable tap target, in design units (Apple and Google both use about 44).
local MIN_TOUCH_TARGET = 44

-- Desktop viewports are in physical pixels, so a 4K monitor reports 3840 x 2160. Scaling by the
-- short edge against 1080 keeps UI the same physical size as on the 1080p monitor it was built on.
local DESKTOP_REFERENCE_SHORT_EDGE = 1080
local DESKTOP_MAX_SCALE = 4

-- Phone and tablet viewports are in points (a phone's short edge is about 360 to 430, a tablet's
-- about 740 to 1030). Phones stay at 1; tablets grow a little to use their extra room.
local TOUCH_REFERENCE_SHORT_EDGE = 720
local TOUCH_MAX_SCALE = 1.5

-- Gamepad players usually sit further from a TV, so their UI is drawn a bit larger.
local GAMEPAD_SCALE_BOOST = 1.25

-- Rounding the scale stops UI re-laying out on every pixel while a window is dragged.
local SCALE_STEP = 0.05

-- A screen whose short edge is under this many design units is treated as compact.
local COMPACT_SHORT_EDGE = 500

local function readInputMode(): InputMode
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

local viewportSize =
	source(Vector2.new(DESKTOP_REFERENCE_SHORT_EDGE * 16 / 9, DESKTOP_REFERENCE_SHORT_EDGE))
local inputMode = source(readInputMode())

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

	viewportSize(camera.ViewportSize)
	cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		viewportSize(camera.ViewportSize)
	end)
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
	inputMode(readInputMode())
end)

local Responsive = {}

Responsive.MIN_TOUCH_TARGET = MIN_TOUCH_TARGET

--[[
	The viewport size in physical pixels (desktop) or points (phones and tablets).
]]
Responsive.viewportSize = viewportSize :: () -> Vector2

--[[
	How the player is controlling the game right now. Changes as soon as they touch the screen,
	press a key, or pick up a gamepad.
]]
Responsive.inputMode = inputMode :: () -> InputMode

function Responsive.isTouch(): boolean
	return inputMode() == "Touch"
end

function Responsive.isPortrait(): boolean
	local size = viewportSize()
	return size.Y > size.X
end

--[[
	The factor that turns design units into screen pixels. Screen roots apply it with a UIScale, so
	most components never need to read it themselves.
]]
function Responsive.scale(): number
	local size = viewportSize()
	local shortEdge = math.min(size.X, size.Y)
	local mode = inputMode()

	local scale
	if mode == "Touch" then
		scale = math.clamp(shortEdge / TOUCH_REFERENCE_SHORT_EDGE, 1, TOUCH_MAX_SCALE)
	else
		scale = math.clamp(shortEdge / DESKTOP_REFERENCE_SHORT_EDGE, 1, DESKTOP_MAX_SCALE)
		if mode == "Gamepad" then
			scale *= GAMEPAD_SCALE_BOOST
		end
	end

	return math.round(scale / SCALE_STEP) * SCALE_STEP
end

--[[
	How much room a screen has, in design units. Use it to decide whether a layout fits.
]]
function Responsive.designSize(): Vector2
	return viewportSize() / Responsive.scale()
end

--[[
	True on small screens such as phones and very small windows.
]]
function Responsive.isCompact(): boolean
	local size = Responsive.designSize()
	return math.min(size.X, size.Y) < COMPACT_SHORT_EDGE
end

return table.freeze(Responsive)
