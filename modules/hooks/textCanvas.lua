local Solyd = require("modules.solyd")
local canvases = require("modules.canvas")

---@return TextCanvas
local function useTextCanvas(w, h)
    local c = Solyd.useMemo(function()
        return canvases.TextCanvas(w, h)
    end, {w, h})

    return c
end

return useTextCanvas
