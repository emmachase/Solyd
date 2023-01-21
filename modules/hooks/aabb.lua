local Solyd = require("modules.solyd")

local function useBoundingBox(x, y, w, h, onClick, allowlist)
    local box = Solyd.useRef(function()
        return { x = x, y = y, w = w, h = h, onClick = onClick, allowlist = allowlist }
    end).value

    box.x = x
    box.y = y
    box.w = w
    box.h = h
    box.onClick = onClick
    box.allowlist = allowlist

    return box
end

local function findNodeAt(boxes, x, y, actor)
    -- x, y = x*2, y*3
    for i = #boxes, 1, -1 do
        local box = boxes[i]
        if type(box) == "table" then
            if box.__type == "list" then
                local node = findNodeAt(box, x, y, actor)
                if type(node) == "table" then
                    return node
                end
            else
                if actor == box.allowlist or not box.allowlist then
                    if  x*2 >= box.x and x*2-1 < box.x + box.w
                    and y*3 >= box.y and y*3-2 < box.y + box.h then
                        return box
                    end
                end
            end
        end
    end
end

return {
    useBoundingBox = useBoundingBox,
    findNodeAt = findNodeAt,
}
