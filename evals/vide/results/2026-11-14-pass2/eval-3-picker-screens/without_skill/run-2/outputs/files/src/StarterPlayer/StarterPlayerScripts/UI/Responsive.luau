--[[
	Shared screen-size and input information for every UI screen.

	Screens are laid out in "design units": one design unit is one pixel on a 1080p monitor. Each
	Screen (see Screen.luau) measures the area it can draw in, picks a UI scale so content keeps
	roughly the same physical size on bigger monitors, and hands its contents a Responsive value
	through `Responsive.context`. Components read it with `Responsive.use()` and react to:

	- Size: the drawable area in design units (already excludes the topbar and device notches).
	- Scale: design units to screen pixels. 1 on phones, tablets, laptops and 1080p; larger above.
	- SizeClass: "Compact" (phones, tiny windows), "Medium" (tablets, small laptops) or
	  "Expanded" (desktop monitors).
	- IsPortrait: whether the drawable area is taller than it is wide.
	- Input: what the player is using right now: "Touch", "KeyboardAndMouse" or "Gamepad".

	All of these are Vide sources, so anything built from them updates when the player rotates a
	device, resizes the window, or switches input mid-session.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)

local source = Vide.source

export type SizeClass = "Compact" | "Medium" | "Expanded"
export type InputKind = "Touch" | "KeyboardAndMouse" | "Gamepad"

export type Responsive = {
	Size: () -> Vector2,
	Scale: () -> number,
	SizeClass: () -> SizeClass,
	IsPortrait: () -> boolean,
	Input: () -> InputKind,
}

-- Shorter side of the drawable area on a 1080p monitor once the topbar is taken out. Screens at
-- or below this keep a scale of 1; bigger ones scale up in proportion.
local REFERENCE_SHORT_SIDE = 1020
local MAX_SCALE = 3
-- Scale moves in steps of this size so dragging a window edge doesn't relayout every pixel.
local SCALE_STEP = 0.05

-- Shorter side, in design units, below which each size class starts.
local MEDIUM_MIN_SHORT_SIDE = 600
local EXPANDED_MIN_SHORT_SIDE = 900

local function toInputKind(preferredInput: Enum.PreferredInput): InputKind
	if preferredInput == Enum.PreferredInput.Touch then
		return "Touch"
	elseif
		preferredInput == Enum.PreferredInput.Gamepad
		or preferredInput == Enum.PreferredInput.MicroGamepad
	then
		return "Gamepad"
	end
	return "KeyboardAndMouse"
end

local input = source(toInputKind(UserInputService.PreferredInput))
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
	input(toInputKind(UserInputService.PreferredInput))
end)

local Responsive = {}

--[[
	The player's current input kind. Usable anywhere, inside a Screen or not.
]]
Responsive.input = function(): InputKind
	return input()
end

--[[
	Design units to screen pixels for a drawable area of the given size in pixels.
]]
function Responsive.computeScale(pixelSize: Vector2): number
	local shortSide = math.min(pixelSize.X, pixelSize.Y)
	local raw = math.clamp(shortSide / REFERENCE_SHORT_SIDE, 1, MAX_SCALE)
	return math.max(1, math.floor(raw / SCALE_STEP) * SCALE_STEP)
end

--[[
	The size class for a drawable area of the given size in design units.
]]
function Responsive.computeSizeClass(size: Vector2): SizeClass
	local shortSide = math.min(size.X, size.Y)
	if shortSide >= EXPANDED_MIN_SHORT_SIDE then
		return "Expanded"
	elseif shortSide >= MEDIUM_MIN_SHORT_SIDE then
		return "Medium"
	end
	return "Compact"
end

-- Set by Screen around its contents. Holds nil outside a Screen.
Responsive.context = Vide.context(nil :: Responsive?)

--[[
	The Responsive value of the Screen this component is being built inside. Call it while
	building a component, not later from an event handler.
]]
function Responsive.use(): Responsive
	local responsive = Responsive.context()
	assert(responsive, "Responsive.use() must be called inside a Screen")
	return responsive
end

return Responsive
