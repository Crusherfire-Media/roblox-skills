--[[
	The root of every UI screen: a ScreenGui that stays inside the device's safe area, survives
	respawns, and scales its contents with `Responsive.scale()`. Write everything inside it in
	design units (see Responsive).

		Screen({
			Name = "InventoryGui",
			Children = { inventoryPanel() },
		})
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Responsive = require(script.Parent.Responsive)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

export type ScreenProps = {
	Name: string,
	DisplayOrder: number?,
	Children: { any },
}

local function screen(props: ScreenProps): ScreenGui
	return create("ScreenGui")({
		Name = props.Name,
		DisplayOrder = props.DisplayOrder or 0,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		-- Keeps content clear of the Roblox topbar, notches, and rounded corners.
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("UIScale")({ Scale = Responsive.scale }),

		props.Children,
	})
end

return screen
