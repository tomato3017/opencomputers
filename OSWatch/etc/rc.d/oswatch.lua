--OS Watchdog
--By tomato3017

local fs = require("filesystem")
local appconf = require("applicationconfparser")
local event = require("event")
local component = require("component")
local network = require("network")
local computer = require("computer")

local watchdog_local_timer
local watchdog_remote_timer

local STATE = {
    NORMAL = 0,
    REBOOT = 1,
    SHUTDOWN = 2,
    OFFLINE = 3
}

local currentState = STATE.OFFLINE
local config

local function loadconfig(filename)
    if(fs.exists(filename)) then
        local file = io.open(filename)
        local config = appconf.parse(file:read("*a"))
        file:close()

        return config
    end
end

local function reboot_system()
    computer.shutdown(true)
end

local function watchdog_remote()

end

local function watchdog_local()
    if(currentState == STATE.NORMAL) then
        --First lets check the memory
        local freeMemory = computer.freeMemory()
        local maxMemory = computer.totalMemory()

        if((freeMemory/maxMemory) * 100 > config.general.maxmemorypercent) then
            currentState = STATE.REBOOT
            computer.pushSignal("oswatch_shutdown", true) --Bool is if rebooting
            event.timer(2, reboot_system, 1)
        end
    end
end

function start(msg)
    if(currentState == STATE.OFFLINE) then
        if(fs.exists("/etc/oswatch.cfg")) then
            fs.copy("/etc/oswatch.cfg.default", "/etc/oswatch.cfg")
        end

        config = loadconfig("/etc/oswatch.cfg")

        event.timer(config.general.pollrate, watchdog_local, math.huge)

        currentState = STATE.NORMAL
    else
        print("OSWATCHDOG is already running!")
    end
end