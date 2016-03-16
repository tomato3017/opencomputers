--[[
Timed cache
By Anthony Kirksey
Purpose: Set auto expire time in seconds on table entries

11/25/2015 - Initial Commit



]]

local TimedCache = {}

function TimedCache:new(expiretime,updateonaccess)
	local cache = require "tomatolib.structs.cache"
	local time = require "tomatolib.util.time"
	expiretime = expiretime or 30

	local c = cache:new(
		function(t,k,v,c)
			local is_valid = (c + tonumber(rawget(t,"_expiretime"))) > time.getTimeSeconds()

			if(is_valid and rawget(t,"_updateonaccess")) then
				return is_valid, time.getTimeSeconds()
			end
			return is_valid
		end,
		function()
			return time.getTimeSeconds()
		end
		)

	rawset(c,"_expiretime", expiretime)
	rawset(c,"_updateonaccess", updateonaccess)

	return c
end

return TimedCache