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

local function msg(msg, isDebug)
    if((isDebug and debug and msg)) then
        print("POWERCTL-DEBUG: " .. msg)
    elseif(not isDebug and msg) then
        print("POWERCTL: " .. msg)
    end
end

local function processUDPMessage(_, source, port, message)
    local command, parameters = message:match("^POWERCTL|.-|(.-)|(.*)")

    if(command == "VARUPDATE") then
        print("VARUPDATE")
    elseif(command == "STATE") then
        print("STATE")
    end
end






function start( msg )
    msg("Daemon Starting!")
    event.listen("datagram", processUDPMessage)
    msg("Done!")
end

function stop( msg )
    msg("Daemon Stopping")
    event.ignore("datagram", processUDPMessage)
    msg("Done!")
end