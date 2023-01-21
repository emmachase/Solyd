local Solyd = require("modules.solyd")
local canvases = require("modules.canvas")
local display = require("modules.display")

---@return PixelCanvas
local function useCanvas(w,h)
    local c = Solyd.useMemo(function()
        if w then
            return canvases.PixelCanvas(w, h)
        else
            return display.ccCanvas.pixelCanvas:newFromSize()
        end
    end, {w, h})

    return c
end

return useCanvas
