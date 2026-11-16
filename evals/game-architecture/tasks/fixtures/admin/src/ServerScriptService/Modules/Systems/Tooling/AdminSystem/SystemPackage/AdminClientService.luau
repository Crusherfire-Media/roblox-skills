--[[
	Client side of the admin tools: a small announcement panel that only admins see.
]]

local Players = game:GetService("Players")

local AdminNetwork = require("./AdminNetwork")
local AdminSharedService = require("./AdminSharedService")

local AdminClientService = setmetatable({}, AdminSharedService)

local function createPanel(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanel"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -16, 0, 64)
	frame.Size = UDim2.fromOffset(280, 44)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	frame.Parent = screenGui

	local textBox = Instance.new("TextBox")
	textBox.Position = UDim2.fromOffset(6, 6)
	textBox.Size = UDim2.new(1, -96, 1, -12)
	textBox.PlaceholderText = "Announcement"
	textBox.Text = ""
	textBox.ClearTextOnFocus = false
	textBox.TextScaled = true
	textBox.Parent = frame

	local sendButton = Instance.new("TextButton")
	sendButton.AnchorPoint = Vector2.new(1, 0)
	sendButton.Position = UDim2.new(1, -6, 0, 6)
	sendButton.Size = UDim2.new(0, 80, 1, -12)
	sendButton.Text = "Announce"
	sendButton.TextScaled = true
	sendButton.Parent = frame

	sendButton.Activated:Connect(function()
		local message = string.sub(textBox.Text, 1, AdminSharedService.MaxAnnouncementLength)
		if message ~= "" then
			AdminNetwork.Announce:FireServer(message)
			textBox.Text = ""
		end
	end)

	return screenGui
end

function AdminClientService:Start()
	local player = Players.LocalPlayer
	if not self:IsAdmin(player.UserId) then
		return
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		createPanel().Parent = playerGui
	end
end

return AdminClientService
