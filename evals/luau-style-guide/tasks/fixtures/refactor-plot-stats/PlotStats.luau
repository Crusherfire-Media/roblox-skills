-- Stats for a player's plot, shown on the plot sign and the build leaderboard.
-- Each block is a table like { Type = "Brick", Position = Vector3 }, where
-- Position is the block's center.

local PlotStats = {}

local T = {
	"Brick",
	"Dirt",
	"Grass",
	"Window",
	"Wood",
	Brick = 5,
	Dirt = 2,
	Grass = 3,
	Window = 8,
	Wood = 4,
}

function fmt(n, c, d)
	local s
	if d then
		s = string.format("%.1f", n)
	else
		s = tostring(math.floor(n))
	end
	if c then
		local int, frac = string.match(s, "^(%-?%d+)(.*)$")
		local out = int
		while true do
			local nxt, k = string.gsub(out, "^(%-?%d+)(%d%d%d)", "%1,%2")
			out = nxt
			if k == 0 then
				break
			end
		end
		s = out .. frac
	end
	return s
end

function PlotStats.summarize(blks)
	assert(typeof(blks) == "table", "summarize expected a table of blocks, got " .. typeof(blks))
	local cnts = {}
	local tot = 0
	local cost = 0
	local h = 0
	for _, b in ipairs(blks) do
		if b ~= nil then
			if b.Position ~= nil then
				if T[b.Type] ~= nil then
					cnts[b.Type] = (cnts[b.Type] or 0) + 1
					tot = tot + 1
					cost = cost + T[b.Type]
					local top = b.Position.Y + 2
					if top > h then
						h = top
					end
				end
			end
		end
	end
	if tot > 50 then
		cost = math.floor(cost * 0.9)
	end
	local v = 0
	for _, name in ipairs(T) do
		if cnts[name] then
			v = v + 1
		end
	end
	local score = tot * 10 + math.floor(h) * 2 + v * 25
	if v == 5 then
		score = score + 100
	end
	return {
		Counts = cnts,
		Total = tot,
		Cost = cost,
		Height = h,
		Score = score,
		Variety = v,
	}
end

function PlotStats.getTallest(blks)
	local best = nil
	for _, b in ipairs(blks) do
		if b ~= nil then
			if b.Position ~= nil then
				if T[b.Type] ~= nil then
					if best == nil or b.Position.Y > best.Position.Y then
						best = b
					end
				end
			end
		end
	end
	if best == nil then
		return
	end
	return best
end

function PlotStats.format(sum, short)
	local word = sum.Total == 1 and "block" or "blocks"
	if not short then
		local typeWord = sum.Variety == 1 and "type" or "types"
		return fmt(sum.Total, true, false)
			.. " "
			.. word
			.. ", "
			.. sum.Variety
			.. " "
			.. typeWord
			.. ", "
			.. fmt(sum.Height, false, true)
			.. " studs tall, score "
			.. fmt(sum.Score, true, false)
	else
		return fmt(sum.Total, true, false) .. " " .. word
	end
end

function PlotStats.compare(a, b)
	if a.Score ~= b.Score then
		return a.Score > b.Score
	end
	return a.Total > b.Total
end

return PlotStats
