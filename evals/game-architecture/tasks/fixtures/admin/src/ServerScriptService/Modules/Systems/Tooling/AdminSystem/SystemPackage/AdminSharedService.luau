--[[
	What the server and client sides of the admin tools share.
]]

local AdminList = require("./AdminList")

-- Longest announcement, in characters.
local MAX_ANNOUNCEMENT_LENGTH = 120

local AdminSharedService = {}
AdminSharedService.__index = AdminSharedService

AdminSharedService.MaxAnnouncementLength = MAX_ANNOUNCEMENT_LENGTH

function AdminSharedService:IsAdmin(userId: number): boolean
	return table.find(AdminList, userId) ~= nil
end

return AdminSharedService
