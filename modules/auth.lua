local sensor = peripheral.find("manipulator")

local monitorWidth, monitorHeight -- = monitor.getSize()
local disabled = false

-- Some experimental values good enough to just calculate the monitor plane since we can snap to blocks
-- These are mutated later to be exact, these are NOT constants!!!
local blockWidthPerChar = 1/21.2093023255814
local blockHeightPerChar = 1/14.13953488372093

local borderX = 2   / 16 -- mc pixels
local borderY = 2   / 16 -- mc pixels
local bleedX  = 2.5 / 16 -- mc pixels
local bleedY  = 2.5 / 16 -- mc pixels

local epsilon = 1e-6

local function isPlayer(sense)
    return sense.key == "minecraft:player"
end

local function getPlayers()
    local entities = sensor.sense()
    local players = {}
    for i = 1, #entities do
        if isPlayer(entities[i]) then
            players[#players + 1] = entities[i]
        end
    end

    return players
end

local function getOnePlayer()
    local players = getPlayers()
    if #players == 1 then
        return players[1]
    end

    return error("THERES ANOTHER PLAYER AROUND LOL")
end



local Ray = {}
local V3 = {}

function Ray.new(details)
    local x = details.x
    local y = details.y
    local z = details.z
    local yaw = math.rad(details.yaw)
    local pitch = math.rad(-details.pitch)
    local dirZ = math.cos(yaw) * math.cos(pitch)
    local dirY = math.sin(pitch)
    local dirX = math.sin(-yaw) * math.cos(pitch)

    local x2 = x + dirX
    local y2 = y + dirY
    local z2 = z + dirZ

    local data = {
        x=x, y=y, z=z,
        x2=x2, y2=y2, z2=z2,
        dirX=dirX, dirY=dirY, dirZ=dirZ,
        yaw=yaw, pitch=pitch
    }
    return setmetatable(data, {__index=Ray})
end

setmetatable(Ray, {__call = function(_, ...) return Ray.new(...) end})

function Ray:pos()
    return V3(self.x, self.y, self.z)
end

function V3.new(x, y, z)
    return setmetatable(
        {x=x, y=y, z=z},
        {
            __index=V3,
            __unm=V3.negate,
            __add=V3.add,
            __sub=V3.sub,
            __mul=V3.mul,
            __div=V3.div,
        }
    )
end

function V3.from(ray)
    return V3(ray.x, ray.y, ray.z)
end

function V3:dot(b)
    return self.x * b.x + self.y * b.y + self.z * b.z
end

function V3:cross(b)
    return V3.new(
        self.y * b.z - self.z * b.y,
        self.z * b.x - self.x * b.z,
        self.x * b.y - self.y * b.x
    )
end

function V3:negate()
    return V3.new(-self.x, -self.y, -self.z)
end

function V3:add(b)
    return V3.new(self.x + b.x, self.y + b.y, self.z + b.z)
end

function V3:sub(b)
    return V3.new(self.x - b.x, self.y - b.y, self.z - b.z)
end

function V3:mul(b)
    return V3.new(self.x * b, self.y * b, self.z * b)
end

function V3:div(b)
    return V3.new(self.x / b, self.y / b, self.z / b)
end

function V3:sqrMag()
    return self.x * self.x + self.y * self.y + self.z * self.z
end

function V3:mag()
    return math.sqrt(self:sqrMag())
end

function V3:normalize()
    return self / self:mag()
end

function V3:mask(mask)
    local x = self.x
    local y = self.y
    local z = self.z
    if mask.x == 0 then
        x = 0
    end
    if mask.y == 0 then
        y = 0
    end
    if mask.z == 0 then
        z = 0
    end
    return V3.new(x, y, z)
end

function V3:toString()
    return string.format("(%f, %f, %f)", self.x, self.y, self.z)
end

local function ceil5(x)
    return math.ceil(x + 0.5) - 0.5
end

local function floor5(x)
    return math.floor(x + 0.5) - 0.5
end

function V3:roundDirection5(dir)
    if dir.x > 0 then
        return V3.new(ceil5(self.x), self.y, self.z)
    elseif dir.x < 0 then
        return V3.new(floor5(self.x), self.y, self.z)
    elseif dir.y > 0 then
        return V3.new(self.x, ceil5(self.y), self.z)
    elseif dir.y < 0 then
        return V3.new(self.x, floor5(self.y), self.z)
    elseif dir.z > 0 then
        return V3.new(self.x, self.y, ceil5(self.z))
    elseif dir.z < 0 then
        return V3.new(self.x, self.y, floor5(self.z))
    end
end

function V3:round()
    return V3.new(math.floor(self.x + 0.5), math.floor(self.y + 0.5), math.floor(self.z + 0.5))
end

setmetatable(V3, {__call = function(_, ...) return V3.new(...) end})

function Ray:getLookPlane()
    local magX = math.abs(self.dirX)
    local magY = math.abs(self.dirY)
    local magZ = math.abs(self.dirZ)

    if magX > magY and magX > magZ then
        if self.dirX > 0 then
            return V3(1, 0, 0)
        else
            return V3(-1, 0, 0)
        end

    elseif magY > magX and magY > magZ then
        if self.dirY > 0 then
            return V3(0, 1, 0)
        else
            return V3(0, -1, 0)
        end

    elseif magZ > magX and magZ > magY then
        if self.dirZ > 0 then
            return V3(0, 0, 1)
        else
            return V3(0, 0, -1)
        end
    end
end

function Ray:dir()
    return V3(self.dirX, self.dirY, self.dirZ)
end

function Ray:intersectPlane(plane, pos)
    local denom = plane:dot(self:dir())
    if math.abs(denom) > epsilon then -- if not parallel
        local t = plane:dot(pos - self) / denom
        return self + self:dir() * t
    end

    return error("Ray is parallel to plane")
end

local function eq3(a, b)
    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end


local calibration

-- Try to find a player that is looking at that position on the monitor
local function reconcileTouch(x, y)
    if disabled then
        return { name = "dummy" }
    end

    local players = getPlayers()

    local foundPlayer = nil
    for i = 1, #players do
        local ray = Ray(players[i])

        -- Check if they are facing the monitor
        if ray:dir():dot(calibration.lookPlane) > epsilon then
            local screenHit = ray:intersectPlane(-calibration.lookPlane, calibration.screenPlane)
            -- Check if they are in reach
            if (screenHit - ray:pos()):mag() < 5*2 then -- *2 because the player could have moved since the touch TODO : validate this
                local monHitX = (screenHit - calibration.origin):dot(calibration.xDir)
                local monHitY = (screenHit - calibration.origin):dot(calibration.yDir)
                local screenX = (monHitX - bleedX)/blockWidthPerChar  + 1
                local screenY = (monHitY - bleedY)/blockHeightPerChar + 1

                if monHitX < borderX or monHitX > monitorWidth + borderX or monHitY < borderY or monHitY > monitorHeight + borderY then
                    -- Not on the screen
                else
                    -- Cap to bleed
                    screenX = math.max(1, math.min(monitorWidth, screenX))
                    screenY = math.max(1, math.min(monitorHeight, screenY))

                    local error = V3(screenX - x + 0.5, screenY - y + 0.5, 0):mag()
                    if error < 2 then
                        if foundPlayer ~= nil then
                            -- Multiple players are looking at this point
                            return nil
                        end

                        -- TODO: Check theyre not moving around by constantly sensing and checking eye ray is consistent

                        foundPlayer = players[i]
                    end
                end
            end
        end
    end

    return foundPlayer
end

local function getLookPosition()
    local players = getPlayers()

    local foundPlayer = nil
    for i = 1, #players do
        local ray = Ray(players[i])

        -- Check if they are facing the monitor
        if ray:dir():dot(calibration.lookPlane) > epsilon then
            local screenHit = ray:intersectPlane(-calibration.lookPlane, calibration.screenPlane)
            -- Check if they are in reach
            if (screenHit - ray:pos()):mag() < 5*2 then -- *2 because the player could have moved since the touch TODO : validate this
                local monHitX = (screenHit - calibration.origin):dot(calibration.xDir)
                local monHitY = (screenHit - calibration.origin):dot(calibration.yDir)
                local screenX = (monHitX - bleedX)/blockWidthPerChar  + 1
                local screenY = (monHitY - bleedY)/blockHeightPerChar + 1

                if monHitX < borderX or monHitX > monitorWidth + borderX or monHitY < borderY or monHitY > monitorHeight + borderY then
                    -- Not on the screen
                else
                    -- Cap to bleed
                    screenX = math.max(1, math.min(monitorWidth, screenX))
                    screenY = math.max(1, math.min(monitorHeight, screenY))

                    return screenX, screenY, players[i]
                end
            end
        end
    end
end

return {
    initialize = function(monitor)
        if not monitor.setTextScale then
            disabled = true
            return -- Not a monitor
        end

        monitorWidth, monitorHeight = monitor.getSize()

        if fs.exists("calibration") then
            local handle = fs.open("calibration", "r") ---@cast handle FileHandle
            local cVals = textutils.unserialize(handle.readAll())
            handle.close()

            calibration = {
                xDir        = V3.from(cVals.xDir),
                yDir        = V3.from(cVals.yDir),
                origin      = V3.from(cVals.origin),
                lookPlane   = V3.from(cVals.lookPlane),
                screenPlane = V3.from(cVals.screenPlane),
                blockWidth  = cVals.blockWidth,
                blockHeight = cVals.blockHeight,
            }

            -- Fix blockWidthPerChar and blockHeightPerChar
            blockWidthPerChar  = (calibration.blockWidth  - (bleedX * 2.0)) / monitorWidth
            blockHeightPerChar = (calibration.blockHeight - (bleedY * 2.0)) / monitorHeight
        else
            error("No calibration file found")
        end
    end,
    reconcileTouch = reconcileTouch,
    getLookPosition = getLookPosition,
}
