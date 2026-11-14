--!strict
--[[
	A ScreenGui that grows the UI inside it on screens larger than 1080p. Build
	every screen of game UI with it, so no component does its own screen math.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Screen = require(script.Parent.Screen)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

export type ScaledScreenGuiProps = {
	Name: string,
	DisplayOrder: number?,
	Children: { any },
}

local function scaledScreenGui(props: ScaledScreenGuiProps): ScreenGui
	return create("ScreenGui")({
		Name = props.Name,
		DisplayOrder = props.DisplayOrder,

		create("UIScale")({ Scale = Screen.uiScale }),
		props.Children,
	})
end

return scaledScreenGui
