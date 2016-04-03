--PowerCTL controller
--By tomato3017

local debug = true

local fs = require("filesystem")
local appconf = require("applicationconfparser")
local event = require("event")

local config
local timers = {}


local function loadconfig(filename)
	if(fs.exists(filename)) then
		local file = io.open(filename)
		local config = appconf.parse(file:read("*a"))
		file:close()

		return config
	end
end

local function msg(msg, isDebug)
	if((isDebug and debug and msg)) then
		print("POWERCTL-DEBUG: " .. msg)
	elseif(not isDebug and msg) then
		print("POWERCTL: " .. msg)
	end
end

local function isRunning()
	return not not timers.powerpoll
end

local function powerpoll()
	msg("Polling Power", true)
end



function start()
	if(isRunning()) then
		msg("POWERCTL is already running")
		return
	end

	config = loadconfig("/etc/powerctl.cfg")

	timers.powerpoll = event.timer(config.general.pollrate, powerpoll, math.huge)
	
end


function stop()
	if(not isRunning()) then
		msg("POWERCTL is already stopped!")
		return
	end
	event.cancel(timers.powerpoll)
	timers.powerpoll = nil
end