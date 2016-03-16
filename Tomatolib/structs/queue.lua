--Queue based table

local Queue = {}

function Queue:new()
	local tbl = {}
	tbl.queueData = {}
	tbl.first = 0
	tbl.last = -1
	setmetatable(tbl,{__index = Queue, __newindex = Queue})

	return tbl
end

function Queue:push(value)
	self.last = self.last + 1
	self.queueData[self.last] = value
end

function Queue:pop()
	if(self.first > self.last) then return nil, "Queue is empty" end
	local value = self.queueData[self.first]
	self.queueData[self.first] = nil
	self.first = self.first + 1

	return value
end

function Queue:pairs()
	local function iterate(self, current)
		if current then 
			current = current + 1
		else
			current = self.first
		end

		local v  = self.queueData[current]
		
		if v then
			return current, v
		end
	end
	return iterate, self, nil
end

function Queue:poppairs()
	local function iterate(self, current)
		return self:pop()	
	end

	return iterate,self,nil
end

function Queue:count()
	return self.last-self.first + 1
end


return Queue