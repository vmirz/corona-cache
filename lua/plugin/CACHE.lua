local Library = require "CoronaLibrary"
local sqlite = require "sqlite3"
local json = require "json"
local lfs = require "lfs" 

local cache = Library:new{ name='cache', publisherId='REVERSE_PUBLISHER_URL' }
local cacheList = {}
local cacheDb = {}

function cacheDb.new( database_name )

	local myDb = {}
	myDb.dbNamePrefix = "cdb_"
	local dbName = myDb.dbNamePrefix..database_name

	-- Handle the "applicationExit" event to close the database
	local function onSystemEvent( event )
		local db = myDb.db
	    if ( event.type == "applicationExit" and db:isopen()) then        
	        db:close()
	    end
	end

	function myDb:getValue( key )
		if(not key or key == "") then
			error("Key expected.")
		end

		local db = self.db
		local query = string.format("SELECT 1 Value, Type FROM KeyValue WHERE Key = '%s'", tostring(key))
		for row in db:nrows(query) do
			if(row.Type == "table") then
				return json.decode( row.Value )
			elseif(row.Type == "number") then
				return tonumber(row.Value)
			elseif(row.Type == "string") then
				return tostring(row.Value)
			else
				error("Invalid cache type.")
			end 
		end
	end

	function myDb:setValue( key, value )

		if(not key or key == "") then
			error("Key expected.")
		end

		if(not value) then
			error("Value expected.")
		end

		--myDb:openDatabase()
		local db = self.db
		local query

		if(type(value) == "table") then
			query = string.format("INSERT OR REPLACE INTO KeyValue (Key, Value, Type) VALUES ('%s', '%s', '%s');", key, json.encode(value), tostring(type(value)) )
		else
			query = string.format("INSERT OR REPLACE INTO KeyValue (Key, Value, Type) VALUES ('%s', '%s', '%s');", key, value, tostring(type(value)) )
		end

		local result = db:exec( query )
		if(result ~= 0) then error("Error executing sql insert. Error: " .. result) end
	end

	function myDb:deleteValue( key )
		local db = self.db
		local query = string.format("DELETE FROM KeyValue WHERE Key = '%s'", tostring(key))
		local result = db:exec( query )
	end

	function myDb:getValues( key, limit )

		local _limit = ""
		if(limit) then
			_limit = " LIMIT ".. limit
		end

		local db = self.db
		local query = [[SELECT Value, Type FROM KeyValue WHERE Key LIKE '%]] .. key .. [[' or Value LIKE '%Name":"]] .. key ..[[%' ]] .. _limit

		local results = {}
		for row in db:nrows(query) do
			if(row.Type == "table") then
				local t = json.decode( row.Value )
				table.insert(results, t)
			elseif(row.Type == "number") then
				table.insert(results, tonumber(row.Value))
			elseif(row.Type == "string") then
				table.insert(results, tostring(row.Value))
			else
				error("Invalid cache type.")
			end
		end

		return results
	end

	-- Delete the entire cache database
	function myDb:removeSelf( ... )
		local db = myDb.db

		if(db:isopen()) then
			db:close()
		end

		Runtime:removeEventListener( "system", onSystemEvent )

		local destDir = system.DocumentsDirectory  -- where the file is stored
		local results, reason = os.remove( system.pathForFile(dbName, system.DocumentsDirectory) )

		if results then
		   --print( "file removed" )
		else
		   --print( "file does not exist", reason )
		end
	end

	function myDb:openDatabase( ... )
		local path = system.pathForFile(dbName, system.DocumentsDirectory)
		myDb.db = sqlite.open(path)
	end

	local function initiateNew( )
		if(dbName == nil or dbName == "") then
			error("Invalid database name.")
		end
		dbName = dbName..".db"
		myDb:openDatabase()
		local db = myDb.db

		-- If the table doesn't exit, we need to create it
		check = [[SELECT count(*) FROM KeyValue]]
		if db:exec(check) ~= 0 then
			db:exec( [[CREATE TABLE IF NOT EXISTS KeyValue (Key STRING, Value, Type, UNIQUE(Key)) ]] )
		else
			--print("database is already present")
		end
	end

	initiateNew( )

	Runtime:addEventListener( "system", onSystemEvent )

	return myDb
end

function cacheDb.load( file_name )
	local path = system.pathForFile(file_name, system.DocumentsDirectory)
	local db = sqlite.open(path)

	local data = {}
	for row in db:nrows([[SELECT * FROM KeyValue]]) do
		--print(row.Key, row.Value, row.Type)
		if(row.Type == "table") then
			data[row.Key] = json.decode( row.Value )
		elseif(row.Type == "number") then
			data[row.Key] =  tonumber(row.Value)
		elseif(row.Type == "string") then
			data[row.Key] = tostring(row.Value)
		else
			error("Invalid cache type.")
		end 
	end

	return data
end

function cache.loadCaches( )
	-- Get raw path to the app documents directory
	local doc_path = system.pathForFile( "", system.DocumentsDirectory )

	for file in lfs.dir( doc_path ) do
	    -- "file" is the current file or directory name
	    local fileName = string.match(file, 'cdb_.*.db')
	    if(fileName) then
	    	local cacheData = cacheDb.load(fileName)
	    	local cacheKey = string.match(fileName, 'cdb_(%a+).db')
	    	local cache = cache.newCache(cacheKey, { data = cacheData })
	    end
	end
end

function cache.bulkInsert( _cache, table )
	local cacheDb = _cache.cacheDb
	cacheDb.db:exec("BEGIN IMMEDIATE TRANSACTION");
	
	for key, value in pairs(table) do
		_cache[key] = value
	end

	cacheDb.db:exec("COMMIT TRANSACTION");
end

function cache.newCache( key, params )
	key = tostring(key)

	local _params = params or {}
	_params.data = _params.data

	local myCache 		= {}
	local myCache_mt	= {}	
	local myCacheDb

	-- This is the internal cache table
	local _cache = {}

	-- Invoked when retrieving value from cache
	myCache_mt.__index = function( table, key)
		if(_cache[key]) then
			return _cache[key]
		else
			return myCacheDb:getValue( key )
		end
	end

	-- Invoked when assigning value to cache
	myCache_mt.__newindex = function( table, key, value)
		if(value == nil) then
			myCacheDb:deleteValue( key )
			_cache[key] = nil
			return
		end

		if(type(value) == "function" or type(value) == "userdata") then
			error("Attempting to cache an invalid value type.")
		end

		myCacheDb:setValue( key, value )
		_cache[key] = value

	end

	function myCache:search( search, limit )
		if limit then
			assert(limit and type(limit) == "number", "Limit must be a number")
		end
		return myCacheDb:getValues( search, limit )
	end
	
	function myCache:removeSelf( )
		myCacheDb:removeSelf()
		myCacheDb = nil
	end

	local function initiateNew(key)

		myCacheDb = cacheDb.new( key )
		myCache.cacheDb = myCacheDb

		if( _params.data ) then
			for key, value in pairs(_params.data) do
				if(type(value) == "string" or type(value) == "number" or type(value) == "table") then
					_cache[key] = value
				end
			end
		end

	end

	if(not cacheList[key]) then
		initiateNew(key)
		cacheList[key] = myCache
		return setmetatable(myCache, myCache_mt)
	else
		return cacheList[key]
	end
end

function cache.deleteCache( key )
	if(cacheList[key]) then
		cacheList[key]:removeSelf()
		cacheList[key] = nil
	end
end

function cache.deleteAll(  )
	for key, cache in pairs(cacheList) do
		cache:removeSelf()
		cache = nil
	end
end

function cache.getCache( key )
	return cacheList[key]
end

return cache