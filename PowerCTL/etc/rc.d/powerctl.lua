--PowerCTL controller
--By tomato3017

local fs = require("filesystem")
local appconf = require("applicationconfparser")

local function loadconfig(filename)
	if(fs.exists(filename)) then
		local file = io.open(filename)
		local config = appconf.parse(file:read("*a"))
		file:close()

		return config
	end
end


local config


function start()
	config = loadconfig("/etc/powerctl.cfg")

	print(config.pollrate)
end