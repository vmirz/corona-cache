local cacheDb = require "scripts.cache.cache_db"
local lfs = require( "lfs" )
local cache = {}

local cacheList = {}

local function loadCaches( )

	local doc_path = system.pathForFile( "", system.DocumentsDirectory )

	for file in lfs.dir( doc_path ) do
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

	local _cache = {}

	myCache_mt.__index = function( table, key)
		if(_cache[key]) then
			return _cache[key]
		else
			return myCacheDb:getValue( key )
		end
	end

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
				if(type(value) == "string" or type(value) == "number" or type(value) == "table" or type(value) == "boolean") then
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

loadCaches()

return cache