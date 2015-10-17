-- 
-- Abstract: CACHE Library Plugin Test Project
-- 
-- Sample code is MIT licensed, see http://www.coronalabs.com/links/code/license
-- Copyright (C) 2015 Corona Labs Inc. All Rights Reserved.
--
------------------------------------------------------------

-- Load plugin library
local CACHE = require "plugin.CACHE"

-------------------------------------------------------------------------------
-- BEGIN (Insert your sample test starting here)
-------------------------------------------------------------------------------

local colorsOriginal = 
{
	{ name = "red",		value = { 1, 0, 0, 1 }, },
	{ name = "green",	value = { 0, 1, 0, 1 }, },
	{ name = "blue",	value = { 0, 0, 1, 1 }, },
	{ name = "cyan",	value = { 0, 1, 1, 1 }, },
	{ name = "magenta",	value = { 1, 0, 1, 1 }, },
	{ name = "yellow",	value = { 1, 1, 0, 1 }, },
}

print( "TEST printTable" )
CACHE.printTable( colorsOriginal )

print( "TEST: saveTable" )
CACHE.saveTable( colorsOriginal, "colors.json" )

print( "TEST: loadTable" )
local colorsLoaded = CACHE.loadTable( "colors.json" )

-- Helper function that draws a 2x3 grid of squares
local function drawGrid( colors, x, y, w, h, label )
	if label then
		display.newText{ text=label, x=x, y=y-2*h, fontSize=12 }
	end

	-- Create 2x3 grid of squares
	local index = 1
	for j=-1,0 do
		for i=-1,1 do
			local r = display.newRect( x + i*w, y + j*h, w, h )
			r:setFillColor( unpack( colors[index].value ) )
			index = index + 1
		end
	end
end

local w, h = 50, 50
local x, y = display.contentCenterX, display.contentCenterY

-- Top grid
drawGrid( colorsOriginal, x, y - 2*h, w, h, "Original Colors" )

-- Bottom grid
drawGrid( colorsLoaded, x, y + 2*h, w, h, "Loaded Colors" )

-------------------------------------------------------------------------------
-- END
-------------------------------------------------------------------------------
