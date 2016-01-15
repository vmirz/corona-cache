local sqlite = require "sqlite3"
local json = require "json"

local db = {}

function db.new( database_name )

	local myDb = {}
	myDb.dbNamePrefix = "cdb_"
	local dbName = myDb.dbNamePrefix..database_name

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
			elseif(row.Type == "boolean") then
				return row.Value == "true"
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

		if(value == nil) then
			error("Value expected.")
		end

		local db = self.db
		local query

		if(type(value) == "table") then
			local escaped = json.encode(value):gsub( "'", "''")
			query = string.format("INSERT OR REPLACE INTO KeyValue (Key, Value, Type) VALUES ('%s', '%s', '%s');", key, escaped, tostring(type(value)) )
		else
			query = string.format("INSERT OR REPLACE INTO KeyValue (Key, Value, Type) VALUES ('%s', '%s', '%s');", key, tostring(value), tostring(type(value)) )
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
		local query = [[SELECT Value, Type FROM KeyValue WHERE Key LIKE '%]] .. key .. [[%' or Value LIKE '%Name":"]] .. key ..[[%' ]] .. _limit

		local results = {}
		for row in db:nrows(query) do
			if(row.Type == "table") then
				local t = json.decode( row.Value )
				table.insert(results, t)
			elseif(row.Type == "number") then
				table.insert(results, tonumber(row.Value))
			elseif(row.Type == "boolean") then
				table.insert(results, tostring(row.Value) == "true")
			elseif(row.Type == "string") then
				table.insert(results, tostring(row.Value))
			else
				error("Invalid cache type.")
			end
		end

		return results
	end

	function myDb:removeSelf( ... )
		local db = myDb.db

		if(db:isopen()) then
			db:close()
		end

		Runtime:removeEventListener( "system", onSystemEvent )

		local destDir = system.DocumentsDirectory
		local results, reason = os.remove( system.pathForFile(dbName, system.DocumentsDirectory) )
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

		check = [[SELECT count(*) FROM KeyValue]]
		if db:exec(check) ~= 0 then
			db:exec( [[CREATE TABLE IF NOT EXISTS KeyValue (Key STRING, Value, Type, UNIQUE(Key)) ]] )
		end
	end

	initiateNew( );

	Runtime:addEventListener( "system", onSystemEvent )

	return myDb
end

function db.load( file_name )
	local path = system.pathForFile(file_name, system.DocumentsDirectory)
	local db = sqlite.open(path)

	local data = {}
	for row in db:nrows([[SELECT * FROM KeyValue]]) do
		if(row.Type == "table") then
			data[row.Key] = json.decode( row.Value )
		elseif(row.Type == "number") then
			data[row.Key] =  tonumber(row.Value)
		elseif(row.Type == "boolean") then
			data[row.Key] = row.Value == "true"
		elseif(row.Type == "string") then
			data[row.Key] = tostring(row.Value)
		else
			error("Invalid cache type.")
		end 
	end

	return data
end

return db