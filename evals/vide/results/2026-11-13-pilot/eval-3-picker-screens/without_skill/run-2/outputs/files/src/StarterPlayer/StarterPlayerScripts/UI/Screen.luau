--[[
	A ScreenGui that every UI screen should be built in.

	It keeps its contents out of the topbar and device notches, measures the area left over, and
	scales its contents so a size in design units looks about the same on a phone, a laptop and a
	4K monitor. Contents fill a "Root" frame that covers that area in design units, so
	UDim2.fromScale(1, 1) is the whole drawable area and offsets are design units.

	Contents are built by `Content`, inside the Screen's Responsive context; call
	`Responsive.use()` from any component in there to lay out by size class, orientation and
	input kind.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Responsive = require(script.Parent.Responsive)
local Vide = require(ReplicatedStorage.Packages.Vide)

local changed = Vide.changed
local create = Vide.create
local derive = Vide.derive
local source = Vide.source

export type ScreenProps = {
	Name: string,
	DisplayOrder: number?,
	Content: () -> any,
}

local function screen(props: ScreenProps): ScreenGui
	local pixelSize = source(Vector2.zero)
	local scale = derive(function()
		return Responsive.computeScale(pixelSize())
	end)
	local size = derive(function()
		return pixelSize() / scale()
	end)

	local responsive: Responsive.Responsive = {
		Size = size,
		Scale = scale,
		SizeClass = derive(function()
			return Responsive.computeSizeClass(size())
		end),
		IsPortrait = derive(function()
			local current = size()
			return current.Y > current.X
		end),
		Input = Responsive.input,
	}

	return create("ScreenGui")({
		Name = props.Name,
		DisplayOrder = props.DisplayOrder or 0,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,

		changed("AbsoluteSize", function(absoluteSize: Vector2)
			pixelSize(absoluteSize)
		end),

		create("Frame")({
			Name = "Root",
			BackgroundTransparency = 1,
			-- Sized at 1 / scale so that, once UIScale multiplies it by scale, it exactly covers
			-- the ScreenGui.
			Size = function()
				local current = scale()
				return UDim2.fromScale(1 / current, 1 / current)
			end,

			create("UIScale")({ Scale = scale }),

			Responsive.context(responsive, props.Content),
		}),
	})
end

return screen
