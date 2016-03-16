--[[
Cache Data structure
By Anthony Kirksey

11/24/2015 - Initial Commit




]]

local Cache = {}

function Cache:__index(k)
	local mt = getmetatable(self)

	if(mt[k]) then return mt[k] end

	local kv_pair = self._data[k]

	if kv_pair then
		local t = self
		local is_valid, newvalue = self._compfunc(t, k, kv_pair.v, kv_pair.control)

		if(is_valid) then
			if newvalue ~= nil then kv_pair.control = newvalue end
			return kv_pair.v
		else
			self._data[k] = nil --Expired
		end
	end
end

function Cache:__newindex(k,v)
	if(v) then
		local control = self._insertfunc(self, k, v)

		self._data[k] = {['v'] = v, ['control'] = control}
	else
		self._data[k] = nil
	end
end

function Cache:iterate()
	local pos = 1
	local keys = {}

	for k in pairs(self._data) do
		table.insert(keys,k)
	end

	return function()
		while pos < #keys+1 do
			local value = self[keys[pos]] -- this will return nil if it doesnt pass the check

			pos = pos + 1

			if value then return keys[pos-1], value end
		end

		return nil
	end
end

function Cache:cleanup()
	local t = self
	for k,kv_pair in pairs(self._data) do
		if kv_pair then
			local is_valid = self._compfunc(t,k,kv_pair.v, kv_pair.control)

			if(not is_valid) then
				self._data[k] = nil --Expired
			end
		end
	end
end

function Cache:new(tableComp, tableInsert)
	assert(type(tableComp) == "function" and type(tableInsert) == "function", "Non-functions passed!!!!")
	local tbl = {
					['_data'] = {},
					['_compfunc'] = tableComp,
					['_insertfunc'] = tableInsert
				}

	setmetatable(tbl,Cache)
	return tbl
end


return Cache
