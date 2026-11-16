--[[
	Lays out the building plots on the baseplate, in two rows on either side of the spawn.
]]

local Workspace = game:GetService("Workspace")

local PLOT_COUNT = 8
local PLOTS_PER_ROW = 4
-- Edge length of a plot, in studs. A multiple of the block size, so blocks line up with it.
local PLOT_SIZE = 64
local PLOT_GAP = 16
local PLOT_THICKNESS = 0.2
local PLOT_COLOR = Color3.fromRGB(120, 160, 90)

local PlotServerService = {}

local plots: { BasePart }? = nil

--[[
	Returns the plot parts.
]]
function PlotServerService:GetPlots(): { BasePart }
	return plots :: { BasePart }
end

function PlotServerService:Init()
	local folder = Instance.new("Folder")
	folder.Name = "Plots"

	local created = {}
	local spacing = PLOT_SIZE + PLOT_GAP
	for index = 1, PLOT_COUNT do
		local column = (index - 1) % PLOTS_PER_ROW
		local row = (index - 1) // PLOTS_PER_ROW

		local plot = Instance.new("Part")
		plot.Name = `Plot{index}`
		plot.Anchored = true
		plot.Size = Vector3.new(PLOT_SIZE, PLOT_THICKNESS, PLOT_SIZE)
		plot.Position = Vector3.new(
			(column - (PLOTS_PER_ROW - 1) / 2) * spacing,
			PLOT_THICKNESS / 2,
			(row - 0.5) * spacing
		)
		plot.Color = PLOT_COLOR
		plot.Material = Enum.Material.Grass
		plot.Parent = folder
		table.insert(created, plot)
	end

	folder.Parent = Workspace
	plots = created
end

return PlotServerService
