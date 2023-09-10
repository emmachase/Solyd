local canvases = require("modules.canvas")
local PixelCanvas = canvases.PixelCanvas
local TeletextCanvas = canvases.TeletextCanvas
local TextCanvas = canvases.TextCanvas


local mon = peripheral.find("monitor") ---@type Term?
if mon then
    ---@cast mon MonitorPeripheral
    mon.setTextScale(0.5)
else
    mon = term
end

mon.setCursorBlink(false)

-- Set Riko Palette
require("util.riko")(mon)

local ccCanvas = TeletextCanvas(colors.green, mon.getSize())
ccCanvas:outputFlush(mon)

local bgCanvas = ccCanvas.pixelCanvas:newFromSize()
for y = 1, bgCanvas.height do
    for x = 1, bgCanvas.width do
        -- T-Piece
        bgCanvas:setPixel(x, y, math.floor(((x)+y)/5) % 2 == 0 and colors.lime or colors.green)
        if math.floor(((-x)+y)/5) % 2 == 0 then
            bgCanvas:setPixel(x, y, colors.green)
        end

        -- 2x2 grid
        -- bgCanvas:setPixel(x, y, (x % 4 < 2) ~= (y % 4 < 2) and colors.green or colors.lime)

        -- bgCanvas:setPixel(x, y, (x/2-y/2) % 2 < 1 and colors.green or colors.lime)
    end
end

return {
    ccCanvas = ccCanvas,
    bgCanvas = bgCanvas,
    mon = mon,
}
