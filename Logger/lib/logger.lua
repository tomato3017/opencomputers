--Simple Logger
--By Anthony Kirksey
--Version 1



local Logger = {}

Logger.Loggers = {}
Logger.DEBUG_LEVELS = {
	INFO = 1,
	WARN = 2,
	DEBUG = 10
}

local DEBUG_LEVEL_MAP = {}
for k,v in pairs(Logger.DEBUG_LEVELS) do
	DEBUG_LEVEL_MAP[v] = k
end

Logger.NextNum = 1


function Logger:write(msg, debuglevel)
	debuglevel = debuglevel or Logger.DEBUG_LEVELS.INFO
	if(debuglevel <= self.debuglevel) then
		local level = DEBUG_LEVEL_MAP[debuglevel] or DEBUG_LEVELS_MAP[1]

		if(self.outputstream and self.outputstream.write) then
			self.outputstream.write("[" ..self:GetName() .. "] " .. level .. ": " .. msg)
		else
			print("[" ..self:GetName() .. "] " .. level .. ": " .. msg)
		end
	end
end

function Logger.new(loggername, debuglevel, outputstream)
	loggername = loggername or "Logger_" .. Logger.NextNum
	Logger.NextNum = Logger.NextNum + 1
	debuglevel = debuglevel or Logger.DEBUG_LEVELS.INFO

	if(Logger.Loggers[loggername]) then
		return Logger.Loggers[loggername]
	end


	local tbl = {
		GetName = function() return loggername end,
		outputstream = outputstream,
		debuglevel = debuglevel
	}

	setmetatable(tbl, {__index = Logger, __newindex = Logger,})

	Logger.Loggers[loggername] = tbl

	return tbl
end


return Logger