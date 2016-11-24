--Initialize File Lib
--Purpose: This lib will handle file saving and loading from a ini file


INIFILE_VERSION=INIFILE_VERSION or 1.0

inifile = inifile or {}

local fs=require("filesystem")


local function ProcessIniLine(iniLine)
  local dataKey,dataValue = iniLine:match("%s*([^=]+)=(.*)")

  if dataKey ~= nil then
    return dataKey, dataValue
  end

  return nil
end

function inifile.ReadIniFile(filepath, defaultSettings)
  checkArg(1,filepath,"string")

  --Lets check to make sure the path exists
  if(not fs.exists(filepath)) then
      if(defaultSettings) then
        local success, errorMsg = inifile.WriteIniFile(filepath, defaultSettings)
        if not success then
          return nil, "File does not exist and " .. errorMsg
        end
      else
        return nil, "File does not exist"
      end
  end

  local iniData = {}
  local currentTableKey = ""
  local currentTable
  for line in io.lines(filepath) do
    --First lets check is this line is the beginning of a new section
    local header=line:match("^%s-%[(.*)%]%s-$")

    if header ~= nil then
      currentTableKey=header
      iniData[currentTableKey] = {}
    else
      local key, value = ProcessIniLine(line)

      if key ~= nil then
        iniData[currentTableKey][key] = value
      end
    end
  end
  return iniData
end

function inifile.WriteIniFile(filepath, iniData)
  local filedata= {}

  local filehandle = io.open(filepath, "w")

  if not filehandle then return nil, "Unable to write file: " .. filepath end
  for sectionname, sectiondata in pairs(iniData) do
    filehandle:write("["..sectionname.."]", "\n")
    if(type(sectiondata) == "table") then
      for key, value in pairs(sectiondata) do
        filehandle:write(key .. "=" .. value, "\n")
      end
    end
    filehandle:write("\n")
  end

  filehandle:close()

  return true
end

return inifile