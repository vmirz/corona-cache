A simple and easy-to-use key-value persistance layer for the Corona SDK.

Example:

-- 
local cache = require "cache"

-- Create a new cache and save a table value

local myCache  = cache.newCache( "demo" )

myCache.hello = "hello!"

-- Later look up a value in the cache

local myCache  = cache.getCache( "demo" )

print(myCache.hello)