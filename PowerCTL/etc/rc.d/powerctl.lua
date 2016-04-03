--PowerCTL controller
--By tomato3017

local debug = true

local fs = require("filesystem")
local appconf = require("applicationconfparser")
local event = require("event")
local component = require("component")

local config
local timers = {}
local MODES ={
    ["NORMAL"] = 1,
    ["BYPASS"] = 2,
    ["OFFLINE"] = 3,
    ["CUSTOM"] = 4
}


local current_mode = 0
local lowpowerpercent = 20
local highpowerpercent = 90

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
    --msg("Polling Power", true)
end

local function modemHandler(name, _, _, port, _, msg)
    if(tonumber(port) == 10) then
        local powerlevel, maxpowerlevel = string.match(msg,"PL=(%d+)|MPL=(%d+)")

        if((current_mode == MODES.NORMAL) and ((powerlevel/maxpowerlevel) * 100) < lowpowerpercent) then
            msg("Low power detected! Switching to bypass mode")
            setMode(MODES.BYPASS)
        end
    end
end

local function setMode(mode, settings)
    msg("SETTING MODE:" .. tostring(mode), true)

    if(mode == MODES.NORMAL) then
        print("NORMAL MODE")
    elseif(mode == MODES.BYPASS)
        print("BYPASS MODE")
    elseif(mode == MODES.OFFLINE)
        print("OFFLINE MODE")
    end
end


function mode(msg)
    if msg then
        msg=string.upper(msg)
    end

    if(mode and MODES[msg]) then
        setMode(mode[msg])
    end
end


function start()
    if(isRunning()) then
        msg("POWERCTL is already running")
        return
    end

    config = loadconfig("/etc/powerctl.cfg")

    event.listen("modem_message", modemHandler)
    component.modem.open(10)

    setMode(MODES.NORMAL)
    timers.powerpoll = event.timer(config.general.pollrate, powerpoll, math.huge)
    
end


function stop()
    if(not isRunning()) then
        msg("POWERCTL is already stopped!")
        return
    end
    event.cancel(timers.powerpoll)
    timers.powerpoll = nil

    event.ignore("modem_message", modemHandler)
end