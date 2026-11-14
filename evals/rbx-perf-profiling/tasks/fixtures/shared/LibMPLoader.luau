--[[
	Returns the place's copy of LibMP, Roblox's MicroProfiler data library. The LibMP ModuleScript
	is added to ReplicatedStorage in Studio and kept out of this repo (and out of published
	builds), so its types aren't known here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local libMPModule = ReplicatedStorage:WaitForChild("LibMP") :: ModuleScript

return require(libMPModule) :: any
