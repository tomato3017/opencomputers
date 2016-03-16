--Trimming cache queue

local TrimQueue = {}

function TrimQueue:new(trimCount)
	trimCount = trimCount or 100
	local tbl = {}
	tbl.queueData = {}
	tbl.first = 0
	tbl.last = -1
	tbl.trimCount = trimCount
	setmetatable(tbl,{__index = TrimQueue, __newindex = TrimQueue})

	return tbl
end

function TrimQueue:push(value)
	self.last = self.last + 1
	self.queueData[self.last] = value

	if(self:count() > self.trimCount) then
		return self:pop()
	end
end

function TrimQueue:pop()
	if(self.first > self.last) then return nil, "TrimQueue is empty" end
	local value = self.queueData[self.first]
	self.queueData[self.first] = nil
	self.first = self.first + 1

	return value
end

function TrimQueue:pairs()
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

function TrimQueue:poppairs()
	local function iterate(self, current)
		return self:pop()	
	end

	return iterate,self,nil
end

function TrimQueue:count()
	return self.last-self.first + 1
end


return TrimQueue