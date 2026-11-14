--!strict
--[[
	Block placement rules shared by the client (ghost preview) and the server (request validation).

	Usage:
		local cell, reason = PlacementRules.check(player, blockType, position, blocksFolder)
		if not cell then
			warn(`{player.Name} placement rejected: {reason}`)
			return
		end
		-- cell is the snapped block centre; place the block there.

	Client preview: turn a raycast hit into a cell with snapFromSurface(result.Position, result.Normal),
	then call check() with that cell to decide whether to tint the ghost red. Keep the ghost itself
	out of blocksFolder.
]]

export type BlockType = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"

local BLOCK_SIZE = 4
local GROUND_Y = 0 -- top face of Workspace.Baseplate (2048 x 16 x 2048 centred at Y = -8)
local MAX_HEIGHT = 200 -- highest a block's top face may reach, measured from GROUND_Y
local MAX_REACH = 24 -- max distance from HumanoidRootPart to the block centre

-- Blocks that touch share a face exactly; this tolerance keeps float error from calling that an overlap.
local OVERLAP_EPSILON = 0.01

local BLOCK_TYPES = table.freeze({ "Brick", "Dirt", "Grass", "Window", "Wood" } :: { BlockType })

local VALID_TYPES: { [string]: boolean } = {}
for _, name in BLOCK_TYPES do
	VALID_TYPES[name] = true
end

local function isFinite(n: number): boolean
	-- NaN fails both comparisons; +/-inf fails one of them.
	return n > -math.huge and n < math.huge
end

local function snapAxis(value: number, origin: number): number
	return origin + math.floor((value - origin) / BLOCK_SIZE) * BLOCK_SIZE + BLOCK_SIZE / 2
end

local PlacementRules = {}

PlacementRules.BLOCK_SIZE = BLOCK_SIZE
PlacementRules.GROUND_Y = GROUND_Y
PlacementRules.MAX_HEIGHT = MAX_HEIGHT
PlacementRules.MAX_REACH = MAX_REACH
PlacementRules.BLOCK_TYPES = BLOCK_TYPES

function PlacementRules.isValidBlockType(value: unknown): boolean
	return type(value) == "string" and VALID_TYPES[value] == true
end

-- Returns the centre of the grid cell that contains `position`. The grid is BLOCK_SIZE studs,
-- aligned to X = 0 / Z = 0 and to GROUND_Y vertically, so a ground-level cell rests on the Baseplate.
-- Idempotent: snapping a cell centre returns the same centre.
function PlacementRules.snap(position: Vector3): Vector3
	return Vector3.new(
		snapAxis(position.X, 0),
		snapAxis(position.Y, GROUND_Y),
		snapAxis(position.Z, 0)
	)
end

-- Returns the cell a new block would occupy when placed against the surface at a raycast hit.
-- A hit point lies exactly on a cell boundary, so it is pushed half a block out along the normal
-- before snapping; otherwise float error could pick the cell inside the surface.
function PlacementRules.snapFromSurface(hitPosition: Vector3, normal: Vector3): Vector3
	return PlacementRules.snap(hitPosition + normal * (BLOCK_SIZE / 2))
end

-- Validates a placement request. `blockType` and `position` may be anything (they come straight
-- from a remote). On success returns the snapped block centre; on failure returns nil and a short
-- reason. Never errors on bad input.
function PlacementRules.check(
	player: Player,
	blockType: unknown,
	position: unknown,
	blocksFolder: Instance
): (Vector3?, string?)
	if not PlacementRules.isValidBlockType(blockType) then
		return nil, "invalid block type"
	end

	if typeof(position) ~= "Vector3" then
		return nil, "position is not a Vector3"
	end
	if not (isFinite(position.X) and isFinite(position.Y) and isFinite(position.Z)) then
		return nil, "position is not finite"
	end

	local cell = PlacementRules.snap(position)

	local half = BLOCK_SIZE / 2
	if cell.Y - half < GROUND_Y then
		return nil, "below ground"
	end
	if cell.Y + half > GROUND_Y + MAX_HEIGHT then
		return nil, "too high"
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (rootPart and rootPart:IsA("BasePart")) then
		return nil, "no character"
	end
	-- Written as "not <=" so a non-finite distance (huge coordinates) is rejected too.
	if not ((cell - rootPart.Position).Magnitude <= MAX_REACH) then
		return nil, "too far away"
	end

	-- Axis-aligned box test against every placed block. Blocks are expected to be unrotated
	-- BaseParts or Models; anything else in the folder is ignored.
	local blockHalfSize = Vector3.one * half
	for _, child in blocksFolder:GetChildren() do
		local otherPosition: Vector3, otherSize: Vector3
		if child:IsA("BasePart") then
			otherPosition, otherSize = child.Position, child.Size
		elseif child:IsA("Model") then
			local boxCFrame, boxSize = child:GetBoundingBox()
			otherPosition, otherSize = boxCFrame.Position, boxSize
		else
			continue
		end

		local penetration = (blockHalfSize + otherSize / 2) - (otherPosition - cell):Abs()
		if
			penetration.X > OVERLAP_EPSILON
			and penetration.Y > OVERLAP_EPSILON
			and penetration.Z > OVERLAP_EPSILON
		then
			return nil, "overlaps a placed block"
		end
	end

	return cell, nil
end

return table.freeze(PlacementRules)
