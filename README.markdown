# About
A simple and easy-to-use persistance layer for the Corona SDK

# Usage

Drop `cache.lua` and `cache_db.lua` in your root project folder (with main.lua)

##### Creating a cache
* cache.newCache( cacheName )
```lua
    local cache = require("cache")
    local usersCache = cache.newCache("users")
```
##### Saving to cache
* Save string, number, boolean, or table value types
```lua
    local cache = require("cache")
    -- Create a new cache
    local usersCache = cache.newCache("users")
    usersCache.viktor = { ["age"] = "26", ["location"] = "Washington D.C" }
```

##### Reading from cache
* cache.getCache( cacheName )
```lua 
    local cache = require("cache")
    local usersCache  = cache.getCache( "users" )
    
    -- Output: Washington D.C
    print(usersCache.viktor.location)
```
##### Updating cache value
* To update a cached value is to overwrite it
```lua
    local cache = require("cache")
    local usersCache = cache.getCache("users")
    local userInfo = usersCache.viktor
    userInfo.age = 27
    usersCache.viktor = userInfo
```

##### Removing value from cache
* Setting to nil will delete the value from cache
```lua
    local cache = require("cache")
    local usersCache = cache.getCache("users")
    usersCache.viktor = nil
```

##### Bulk add
* When adding or updating many values at once (ie. in a loop), you will want to do this operation in bulk for performance reason.
* cache.bulkInsert( cache, tableOfValues )
```lua
    local cache = require("cache")
    local usersCache = cache.getCache("users")
    
    local t = {}
    for i=1, 100 do
     t["user"..i] = { ["age"] = math.random(1, 70) }
    end
    cache.bulkInsert(usersCache, t)
```

##### Deleting cache
* cache.deleteCache( cacheName )
```lua
    local cache = require("cache")
    local usersCache = cache.getCache("users")
    -- ...
    -- Later if you want to delete the cache
    cache.deleteCache("users")
```
