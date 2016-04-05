--PowerCTL controller
--By tomato3017

--PowerCTL network format
--HEADER|VERSION|COMMAND|K_VPairs
--ex: "POWERCTL|1|VARUPDATE|MPL=10000;PL=1000"

--Commands
--[[
    --Outbound
    VARUPDATE: Sends updates on power levels
        kvpairs of power and max power(PL and MPL)
    STATE: Sends current mode and state 
        CurrentState|kvpairs of mappings;

    --Inbound
    SETMODE:
        parameters:
            MODE_Name - String
]]

local debug = false
local VERSION = "1"
local HEADER = "POWERCTL|" .. VERSION

local fs = require("filesystem")
local appconf = require("applicationconfparser")
local event = require("event")
local component = require("component")
local colors = require("colors")
local sides = require("sides")
local network = require("network")

local config
local timers = {}
local MODES ={
    ["NORMAL"] = 1,
    ["BYPASS"] = 2,
    ["OFFLINE"] = 3,
    ["CUSTOM"] = 4,
    ["CHARGING"] = 5
}


local current_mode = 0
local linestate = {}



local function sendMsgToServer(command, msg)
    local serveraddr = config.general.serveraddr
    local serverport = config.general.serverport

    network.udp.send(serveraddr, serverport, HEADER .. "|" .. command .. "|" .. msg)
end


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

local function setLine(line, value)
    if(line and value) then
        line = string.lower(line)
        local color = config.general.mappings[line]
        if not color then return false end

        local rs = component.redstone

        rs.setBundledOutput(sides.left, colors[color], value)
        linestate[line] = value
    end
end

local function setMode(mode, settings)
    msg("SETTING MODE:" .. tostring(mode), true)

    if not config then config = loadconfig("/etc/powerctl.cfg") end

    local rs = component.redstone
    
    if(mode == MODES.NORMAL) then
        for k,v in pairs(config.general.mappings) do
            msg("Setting Line to on: " .. k,true)
            setLine(k, 0)
        end
        current_mode = mode
    elseif(mode == MODES.BYPASS) then
        for k,v in pairs(config.general.mappings) do
            if(k:match("bypass")) then
                msg("Setting Line to on: " .. k,true)
                setLine(k, 255)
            end
        end
        current_mode = mode
    elseif(mode == MODES.OFFLINE) then
        for k,v in pairs(config.general.mappings) do
            msg("Setting Line to on: " .. k,true)
            if(k:match("bypass") or k:match("chargeline")) then
                setLine(k, 0)
            else
                setLine(k, 255)
            end
        end  
        current_mode = mode
    elseif(mode == MODES.CHARGING) then
        setLine("chargeline", 255)
        current_mode = mode
    end
end

local function modemHandler(name, _, _, port, _, message)
    if(tonumber(port) == 10) then
        local powerlevel, maxpowerlevel = string.match(message,"PL=(%d+)|MPL=(%d+)")

        --Forward the data to the server
        sendMsgToServer("VARUPDATE", "PL=" .. powerlevel .. ";" .. "MPL=" .. maxpowerlevel)

        if(config.general.automanage and powerlevel) then
            powerlevel, maxpowerlevel = tonumber(powerlevel), tonumber(maxpowerlevel)
            if(debug) then msg("Current Power Level:" .. tostring((powerlevel/maxpowerlevel) * 100), true) end
            if(current_mode == MODES.NORMAL) then
                if((powerlevel/maxpowerlevel) * 100 < config.general.lowpowerpercent) then
                    setMode(MODES.CHARGING)
                end
            elseif(current_mode == MODES.CHARGING) then
                if((powerlevel/maxpowerlevel) * 100 > config.general.highpowerpercent) then
                    setMode(MODES.NORMAL)
                end
            end
        end
    end
end

local function powerpoll()
    if(config.general.powerpoller) then
        local powerlevel = 0
        local maxpowerlevel = 0

        for addr, compType in component.list() do 
            if(compType:match("mfe") or compType:match("mfsu")) then
                local dev = component.proxy(addr)
                powerlevel = powerlevel + dev.getEUStored()
                maxpowerlevel = maxpowerlevel + dev.getEUCapacity()
            end
        end

        local cmdString = "PL=" .. powerlevel .. "|MPL=" .. maxpowerlevel

        --hack, call the the modem handler

        modemHandler("modem_message", nil, nil, 10, nil, cmdString)
    end
end

local function getState()
    local state = {}

    for k,v in pairs(MODES) do
        if(v == current_mode) then
            state.current_mode = k
        end
    end

    state.mappings = {}

    for k,v in pairs(linestate) do
        state.mappings[k] = v
    end

    return state
end

local function sendStateMsg()
    local state = getState()

    local mappingsStr = {}

    for k,v in pairs(state.mappings) do
        table.insert(mappingsStr, k.."="..v)
    end

    sendMsgToServer("STATE", state.current_mode .. "|" .. table.concat( mappingsStr,";") )
end

local function processUDPMessage(_, source, port, message)
    local command, parameters = message:match("^POWERCTL|.-|(.-)|(.*)")

    msg(command, true)

    if(command == "SETMODE") then
        if(#parameters > 0) then
            setMode(MODES[parameters])
        end
    end
end

function mode(msg)
    if msg then
        msg=string.upper(msg)
    end

    if(msg and MODES[msg]) then
        setMode(MODES[msg])
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

    network.udp.open(config.general.listenport)
    event.listen("datagram", processUDPMessage)
    
    timers.statesend = event.timer(config.general.statesendrate, sendStateMsg, math.huge)

    --let the server know we are here
    sendStateMsg()
end


function stop()
    if(not isRunning()) then
        msg("POWERCTL is already stopped!")
        return
    end
    event.cancel(timers.powerpoll)
    event.cancel(timers.statesend)
    timers.powerpoll = nil

    event.ignore("modem_message", modemHandler)
    network.udp.close(config.general.listenport)

    event.ignore("datagram", processUDPMessage)
end