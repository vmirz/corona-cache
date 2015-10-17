local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name='CACHE', publisherId='REVERSE_PUBLISHER_URL' }

-------------------------------------------------------------------------------
-- BEGIN (Insert your implementation starting here)
-------------------------------------------------------------------------------

local json = require "json"

local defaults = require "plugin.CACHE.defaults"
local _directories = defaults.directories
local _isDirWriteable = defaults.writePermissions
local _isDirReadable = defaults.readPermissions

lib.loadTable = function( filename, baseDir )
	local result = nil
	baseDir = baseDir or _directories.loadDir

	-- Validate params
	assert( type(filename) == "string", "'loadTable' invalid filename" )
	assert( _isDirReadable[baseDir], "'loadTable' invalid baseDir" )

	local path = system.pathForFile( filename, baseDir )

	local file = io.open( path, "r" )
	if file then
		-- read all contents of file into a string
		local contents = file:read( "*a" )
		result = json.decode( contents )
		io.close( file )
	end

	return result
end

lib.saveTable = function( t, filename, baseDir )
	local result = false
	baseDir = baseDir or _directories.saveDir

	-- Validate params
	assert( type(t) == "table", "'saveTable' invalid table" )
	assert( type(filename) == "string", "'saveTable' invalid filename" )
	assert( _isDirWriteable[baseDir], "'saveTable' invalid baseDir" )

	local path = system.pathForFile( filename, baseDir )

	local file = io.open( path, "w" )
	if file then
		local contents = json.encode( t )
		file:write( contents )
		io.close( file )
		result = true
	end

    return result
end

-- printTable( t [, label [, level ]] )
local function printTable( t, label, level )
	-- Validate params
	assert(
		"table" == type(t),
		"Bad argument 1 to 'printTable' (table expected, got " .. type(t) .. ")" )

	if label then print( label ) end
	level = level or 1

	for k,v in pairs( t ) do
		-- Indent according to nesting 'level'
		local prefix = ""
		for i=1,level do
			prefix = prefix .. "\t"
		end

		-- Print key/value pair
		print( prefix .. "[" .. tostring(k) .. "] = " .. tostring(v) )

		-- Recurse on tables
		if type( v ) == "table" then
			print( prefix .. "{" )
			printTable( v, nil, level + 1 )
			print( prefix .. "}" )
		end
	end
end
lib.printTable = printTable

-------------------------------------------------------------------------------
-- END
-------------------------------------------------------------------------------

-- Return library instance
return lib
