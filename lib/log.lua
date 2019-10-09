local colors = require("lib.ansicolors")

--[[
    Log will print the log msg with a status applied in front of the message.
    @param type - the log type: info, debug, fail, pass or fatal.
    @msg - the message to log.
]]

local function log(type, msg)
    colored_status = ""

    if type == "info" then
        colored_status = colors("%{blue} info%{reset}")
    elseif type == "debug" then
        colored_status = colors("%{dim white}debug%{reset}")
    elseif type == "error" then
        colored_status = colors("%{dim red}error%{reset}")
    elseif type == "fail" then
        colored_status = colors("%{red} fail%{reset}")
    elseif type == "pass" then
        colored_status = colors("%{green} pass%{reset}")
    else
        colored_status = colors("%{bright red}fatal%{reset}")
    end

    print(string.format("[%s] %s", colored_status, msg))
end

return log