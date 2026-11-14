--!strict
--[[
	The ScreenGui every game screen is built in. It keeps interactive UI clear
	of Roblox's own buttons and grows everything inside it on screens whose
	short side is over 1080, so UI authored for 1080p keeps its share of a
	1440p or 4K monitor or a TV.
]]

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local Screen = require("./Screen")

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
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,

		create("UIScale")({ Scale = Screen.uiScale }),

		props.Children,
	})
end

return gameScreenGui
