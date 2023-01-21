local Solyd = require("modules.solyd")

local animationRequests = {}
local animationFinished = {}

---@return number?
local function useAnimation(playing)
    -- local anim = Solyd.useRef(function()
    --     return { playing = playing, frame = 0, time = 0 }
    -- end).value
    local t, setT = Solyd.useState(0)

    if playing then
        -- Request animation frame
        animationRequests[#animationRequests + 1] = {t, setT}

        return t
    elseif t ~= 0 then
        setT(0)
        return
    end
end

local function tickAnimations(dt)
    -- Clone the queue to avoid mutating it while iterating
    local animationQueue = {unpack(animationRequests)}
    animationRequests = {}
    for _, v in ipairs(animationQueue) do
        local aT, setT = v[1], v[2]
        setT(aT + dt)
    end
end

return {
    useAnimation = useAnimation,
    tickAnimations = tickAnimations,
    animationFinished = animationFinished,
}
