--- Adapted from Kilobyte's program configparse https://github.com/OpenPrograms/Kilobyte-Programs/tree/master/configparse

local configparse = {}

local ParseMode = {
    NONE = 0,
    TOKEN = 1,
    ESCAPED_STRING = 2,
    STRING = 3,
    COMMENT = 4,
    MULTI_COMMENT = 5
}

local function tokenize(data)
    local tokens = {}
    local pos = 1
    local line = 1
    local col = 1
    local mode = ParseMode.NONE
    local tmp

    local function next()
        local c = data:sub(pos, pos)
        pos = pos + 1
        if c == '\n' then
            line = line + 1
            col = 1
        else
            col = col + 1
        end
        return c
    end

    local function startToken(m)
        mode = m
        tmp = ""
    end

    local function finishToken()
        if mode == ParseMode.NONE then
            return
        end
        local t = {}
        if mode == ParseMode.TOKEN then
            if #tmp == 1 and tmp:match(("[:{},\n%[%]]")) then
                t.type = "syntax"
                t.value = tmp
            else
                local n = tonumber(tmp)
                if n then
                    t.type = "number"
                    t.value = n
                elseif tmp == "true" or tmp == "false" then
                    t.type = "boolean"
                    t.value = tmp == "true"
                else
                    t.type = "token"
                    t.value = tmp
                end
            end

        else
            t.type = "string"
            t.value = tmp
        end
        tmp = nil
        mode = ParseMode.NONE
        t.line = line
        table.insert(tokens, t)
    end

    while pos <= #data do
        local c = next()
        if mode == ParseMode.STRING then
            if c == '"' then
                finishToken()
            elseif c == '\\' then
                mode = ParseMode.ESCAPED_STRING
            else
                tmp = tmp .. c
            end
        elseif mode == ParseMode.ESCAPED_STRING then
            if c == 'n' then
                tmp = tmp .. '\n'
            elseif c == 't' then
                tmp = tmp .. '\t'
            else
                tmp = tmp .. c
            end
            mode = ParseMode.STRING
        elseif mode == ParseMode.COMMENT then
            if c == '\n' then
                mode = ParseMode.NONE
            end
        else
            -- other modes

            if c == ' ' or c == '\t' then
                finishToken()
            elseif c:match("[:{},\n%[%]]") then
                finishToken()
                startToken(ParseMode.TOKEN)
                tmp = c
                finishToken()
            elseif c == '"' then
                -- string
                finishToken()
                startToken(ParseMode.STRING)
            elseif c == '#' then
                finishToken()
                mode = ParseMode.COMMENT
            else
                if mode == ParseMode.NONE then
                    startToken(ParseMode.TOKEN)
                end
                tmp = tmp .. c
            end
        end
    end
    return tokens
end

local function parse(tokens)
    local pos = 1
    local e = error

    local function error(msg)
        e("line "..tokens[pos - 1].line..": "..msg, 2)
    end

    local function next()
        local ret = tokens[pos]
        pos = pos + 1
        return ret
    end

    local function parseScope(root)
        local options = {}
        while true do
            ::mainloop::
            if root and pos > #tokens then
                break
            end
            local t = next()
            if t.type == "syntax" then
                if t.value == "{" then
                    error("Unexpected '{'")
                elseif t.value == ';' then
                    goto mainloop
                elseif t.value == '}' then
                    break
                end
            else 
                local optionName = t.value
                local isArray = false
                while true do
                    t = next()
                    if t.type == "syntax" then
                        if t.value == "[" then
                          isArray = true
                          options[optionName] = {}
                        elseif isArray == false and t.value == '\n' then
                            break
                        elseif t.value == "]" then
                          break
                        elseif t.value == '{' then
                            options[optionName] = parseScope(false)
                            break
                        elseif t.value == '}' then
                            error("Unexpected '}'")
                        end
                    elseif isArray then
                      table.insert(options[optionName], t.value)
                    else
                      options[optionName] = t.value
                    end
                end
            end
        end
        return options
    end
    return parseScope(true)
end

function configparse.parse(data)
    local tokens = tokenize(data)
    return parse(tokens)
end

return configparse