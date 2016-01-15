A simple and easy-to-use key-value persistance layer for the Corona SDK.

Example:

-- 
local cache = require "cache"

-- Create a new cache and save a table value

local myCache  = cache.newCache( "myCache" )
myCache.smile = ":)"

-- Later look up a value in the cache

local myCache  = cache.getCache( "myCache" )
print(myCache.smile)