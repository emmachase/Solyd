-- Make log directory if not exists
if not fs.exists("logs") then
    fs.makeDir("logs")
end

if fs.getFreeSpace("logs") < 1024*64 then
    error("Not enough space in logs directory")
end

-- Open log file for today
local handle
do
    local unix = os.epoch("utc") / 1000
    local date = os.date("*t", unix)
    handle = fs.open(string.format("logs/%04d-%02d-%02d.log", date.year, date.month, date.day), "a")
end

local function timestamp()
    local unix = os.epoch("utc") / 1000
    local date = os.date("*t", unix)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec)
end

return {
    log = function(...)
        local args = {timestamp(), ...}
        local str = table.concat(args, " ")
        handle.writeLine(str)
    end,

    close = function()
        handle.close()
    end
}
