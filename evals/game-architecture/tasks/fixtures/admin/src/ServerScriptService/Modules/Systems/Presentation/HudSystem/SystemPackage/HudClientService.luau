--[[
	The HUD: a title bar at the top of the screen.
]]

local Players = game:GetService("Players")

local HudClientService = {}

local title = ""
local titleLabel: TextLabel? = nil

--[[
	Sets the text in the title bar.
]]
function HudClientService:SetTitle(text: string)
	title = text
	if titleLabel then
		titleLabel.Text = text
	end
end

function HudClientService:Init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Hud"
	screenGui.ResetOnSpawn = false

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 8)
	label.Size = UDim2.fromOffset(320, 32)
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Text = title
	label.Parent = screenGui
	titleLabel = label

	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		screenGui.Parent = playerGui
	end
end

return HudClientService
