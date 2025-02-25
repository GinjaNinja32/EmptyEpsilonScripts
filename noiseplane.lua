--- Utility for procedurally generating planes of random noise by various methods.

require "gn32/lang"
require "gn32/random"

--- The global seed for all procedural generation.
-- Initialised to a random seed. If you do not require run-to-run determinism, you can safely ignore this value.
-- @table globalseed
-- @within Globals
G.globalseed = random.genseed()

local noisePlane
G.NoisePlane, noisePlane = makeClass()

--- Types.
-- @section types

--- A table containing positional information passed to all generation functions.
-- Each generation function invocation receives a unique pos table.
-- @table pos
-- @int cx The x index of the current chunk.
-- @int cy The y index of the current chunk.
-- @int csize The size of the current chunk.
-- @int x0 The low x position of the current chunk.
-- @int x1 The high x position of the current chunk.
-- @int y0 The low y position of the current chunk.
-- @int y1 The high y position of the current chunk.

--- A table to store and pass arbitrary data between generation functions.
-- When generating a base-layer chunk, a data table is constructed to pass to all generation functions that will be called to generate that chunk.
-- By default, this is an empty table; to change this, see `noisePlane:makeData`.
-- @table data

--- Functions .
-- @section functions

--- Create a new NoisePlane.
-- @function NoisePlane
-- @return The new NoisePlane instance.
function noisePlane:_init()
	self.seed = random.genseed()
	self.layers = {}
	self.dataFn = function() return {} end
end

--- Set the seed for this NoisePlane.
-- Each NoisePlane instance begins with its seed initialised randomly. If you do not require run-to-run determinism, you can safely ignore this function.
-- Each NoisePlane in a scenario should use a different seed.
-- @int seed The seed to set.
-- @return self
function noisePlane:setSeed(seed)
	self.seed = seed
	return self
end

--- Provide a function to set the initial `data` table for generating a chunk.
-- If this function is not used, the data table will be initialised as a new empty table.
-- @tparam function fn The function to generate the table.
-- @return self
function noisePlane:makeData(fn)
	self.dataFn = fn
	return self
end

--- Add a function called over a window of chunks below this layer.
-- The function will be called over a `size`x`size` area centred on the chunk being generated.
-- This function must be followed by an invocation of `noisePlane:chunks` to result in a valid NoisePlane instance.
-- @int size The size of the desired window.
-- @tparam function fn The function to call, which will be called with (`pos`, `data`)
-- @return self
function noisePlane:windows(size, fn)
	table.insert(self.layers, 1, {
		ty = "windows",
		size = size,
		fn = fn,
	})
	return self
end

--- Add a function that merges several chunks below this layer into one.
-- The function will merge an area of `size`x`size` into a single chunk; all layers above this one will see the new chunk size.
-- @int size The size of the desired area to merge into one chunk.
-- @tparam function fn The function to call, which will be called with (`pos`, `data`)
-- @return self
function noisePlane:chunks(size, fn)
	table.insert(self.layers, 1, {
		ty = "chunks",
		size = size,
		fn = fn,
	})
	return self
end

function noisePlane:_setSeed(cx, cy, i)
	math.randomseed(globalseed)
	for _, mix in ipairs{self.seed, cx, cy, i} do
		math.randomseed(mix ~ random.genseed())
	end
end

function noisePlane:_posFor(cx, cy, csize)
	return {
		cx = cx,
		cy = cy,

		csize = csize,

		x0 = ( cx      * csize),
		x1 = ((cx + 1) * csize),
		y0 = ( cy      * csize),
		y1 = ((cy + 1) * csize),
	}
end

function noisePlane:_run(cx, cy, csize, data, idx)
	local layer = self.layers[idx]
	if not layer then return end

	if layer.ty == "windows" then
		self:_run(cx, cy, csize, data, idx+1)

		local function runForOffset(xoff, yoff)
			local pos = self:_posFor(cx + xoff, cy + yoff, csize)
			pos.dist = math.max(math.abs(xoff), math.abs(yoff))
			pos.dist_euclid = math.sqrt(xoff^2 + yoff^2)

			self:_setSeed(pos.cx, pos.cy, idx-1)
			layer.fn(pos, data)
		end

		local lo = -((layer.size-1) // 2)
		local hi = layer.size // 2
		for xoff = lo, hi do
			for yoff = lo, hi do
				if xoff ~= 0 or yoff ~= 0 then
					runForOffset(xoff, yoff)
				end
			end
		end
		runForOffset(0, 0)
	elseif layer.ty == "chunks" then
		cx = cx // layer.size
		cy = cy // layer.size
		csize = csize * layer.size

		self:_run(cx, cy, csize, data, idx+1)

		local pos = self:_posFor(cx, cy, csize)

		self:_setSeed(pos.cx, pos.cy, idx-1)
		layer.fn(pos, data)
	else
		error(layer.ty)
	end
end

--- Sample this NoisePlane at the given coordinates.
-- @tparam integer cx The x index to sample.
-- @tparam integer cy The y index to sample.
-- @treturn table The `data` table after all generation functions have completed.
function noisePlane:sample(cx, cy)
	if self.layers[1].ty ~= "chunks" then
		error("final layer must be chunks", 2)
	end

	local data = self.dataFn()

	cx = cx * self.layers[1].size
	cy = cy * self.layers[1].size

	self:_run(cx, cy, 1, data, 1)

	return data
end
