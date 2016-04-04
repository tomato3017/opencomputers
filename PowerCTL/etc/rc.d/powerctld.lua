--PowerCTL controller daemon
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
local network = require("network")

local reporters = {}

local function msg(message, isDebug)
    if((isDebug and debug and message)) then
        print("POWERCTL-DEBUG: " .. message)
    elseif(not isDebug and message) then
        print("POWERCTL: " .. message)
    end
end

local function newreporter(source)
    reporters[source] = {
        ["lastreported"] = (os.time() * (1000/60/60)/20)
    }
end

local function updatelevels(reporter, levels)
    reporter.PL = levels.PL
    reporter.MPL = levels.MPL
    reporter.lastreported = (os.time() * (1000/60/60)/20)
end

local function updatestate(reporter, currentstate, mappings)
    reporter.currentstate = currentstate
    reporter.mappings = kv_to_table(mappings)
end



local function kv_to_table(data)
    local rtn = {}

    for k in data:gmatch("[^;]+") do
        local key, value = k:match("(.*)=(.*)")

        if(key and value) then
            rtn[key] = value
        end
    end

    return rtn
end

local function processUDPMessage(_, source, port, message)
    local command, parameters = message:match("^POWERCTL|.-|(.-)|(.*)")

    if(command == "VARUPDATE") then
        print("VARUPDATE")
        local levels = kv_to_table(parameters)

        if(not reporter[source]) then
            newreporter(source)
        end

        updatelevels(reporter[source], levels)
    elseif(command == "STATE") then
        print("STATE")
        local CurrentState, mappings = parameters:match("(.*)|(.*)")

        if(not reporter[source]) then
            newreporter(source)
        end

        updatestate(reporter[source], currentstate, mappings)
    end
end






function start( message )
    msg("Daemon Starting!")
    
    event.listen("datagram", processUDPMessage)

    --==PORT OPEN==
    network.udp.open(16000)
    msg("Done!")
end

function stop( message )
    msg("Daemon Stopping")
    event.ignore("datagram", processUDPMessage)
    network.udp.close(16000)
    msg("Done!")
end