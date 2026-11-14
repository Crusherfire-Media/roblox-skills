--[[
	The ScreenGui every game screen is built in. It carries the one UIScale that grows the whole
	UI on screens taller than 1080, so no screen does its own scaling and none can forget to.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Screen = require(script.Parent.Screen)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

export type GameScreenGuiProps = {
	Name: string,
	DisplayOrder: number?,
	Children: { any },
}

local function gameScreenGui(props: GameScreenGuiProps): ScreenGui
	return create("ScreenGui")({
		Name = props.Name,
		DisplayOrder = props.DisplayOrder or 0,

		create("UIScale")({ Scale = Screen.uiScale }),
		props.Children,
	})
end

return gameScreenGui
