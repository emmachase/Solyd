local Ease = {}

function Ease.linear(t, b, c, d)
    return c * t / d + b
end

function Ease.inQuad(t, b, c, d)
    t = t / d
    return c * t * t + b
end

function Ease.outQuad(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
end

function Ease.inOutQuad(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t + b
    else
        t = t - 1
        return -c / 2 * (t * (t - 2) - 1) + b
    end
end

function Ease.outInQuad(t, b, c, d)
    if t < d / 2 then
        return Ease.outQuad(t * 2, b, c / 2, d)
    else
        return Ease.inQuad((t * 2) - d, b + c / 2, c / 2, d)
    end
end

function Ease.inCubic(t, b, c, d)
    t = t / d
    return c * t * t * t + b
end

function Ease.outCubic(t, b, c, d)
    t = t / d - 1
    return c * (t * t * t + 1) + b
end

function Ease.inOutCubic(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t * t + b
    else
        t = t - 2
        return c / 2 * (t * t * t + 2) + b
    end
end

function Ease.outInCubic(t, b, c, d)
    if t < d / 2 then
        return Ease.outCubic(t * 2, b, c / 2, d)
    else
        return Ease.inCubic((t * 2) - d, b + c / 2, c / 2, d)
    end
end

function Ease.inQuart(t, b, c, d)
    t = t / d
    return c * t * t * t * t + b
end

function Ease.outQuart(t, b, c, d)
    t = t / d - 1
    return -c * (t * t * t * t - 1) + b
end

function Ease.inOutQuart(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t * t * t + b
    else
        t = t - 2
        return -c / 2 * (t * t * t * t - 2) + b
    end
end

function Ease.outInQuart(t, b, c, d)
    if t < d / 2 then
        return Ease.outQuart(t * 2, b, c / 2, d)
    else
        return Ease.inQuart((t * 2) - d, b + c / 2, c / 2, d)
    end
end

return Ease
