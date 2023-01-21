local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

return Solyd.wrapComponent("Rect", function(props)
    local canvas = useCanvas(props.maxWidth or props.width, props.maxHeight or props.height)

    Solyd.useEffect(function()
        for x = 1, props.width do
            for y = 1, props.height do
                canvas:setPixel(x, y, props.color)
            end
        end

        return function()
            canvas:markRect(1, 1, props.width, props.height)
        end
    end, { canvas, props.color, props.width, props.height })

    return nil, { canvas = { canvas, props.x, props.y } }
end)
