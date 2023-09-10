---@diagnostic disable
-- TODO: Fix up this file

local sensor = peripheral.find("manipulator")
local monitor = peripheral.find("monitor") ---@type MonitorPeripheral

monitor.setTextScale(0.5)
local monitorWidth, monitorHeight = monitor.getSize()

-- Some experimental values good enough to just calculate the monitor plane since we can snap to blocks
-- These are mutated later to be exact, these are NOT constants!!!
local blockWidthPerChar = 1/21.2093023255814
local blockHeightPerChar = 1/14.13953488372093
local expectedArea = blockWidthPerChar*(monitorWidth - 1) * blockHeightPerChar*(monitorHeight - 1)

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

    -- Find player with name "anemonemma"
    for i = 1, #players do
        if players[i].name == "anemonemma" then
            return players[i]
        end
    end

    if #players == 1 then
        return players[1]
    end

    return error("THERES ANOTHER PLAYER AROUND LOL")
end


---@class Ray
---@field x number
---@field y number
---@field z number
---@field x2 number
---@field y2 number
---@field z2 number
---@field dirX number
---@field dirY number
---@field dirZ number
---@field yaw number
---@field pitch number
---@overload fun(details: table): Ray
local Ray = {}

---@class V3
---@field x number
---@field y number
---@field z number
---@overload fun(x: number, y: number, z: number): V3
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

local function vmax(...)
    local args = {...}
    local max = args[1]
    local maxVal = max:mag()
    for i = 2, #args do
        local val = args[i]:mag()
        if val > maxVal then
            max = args[i]
            maxVal = val
        end
    end

    return max
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
    -- Perform calibration by displaying calibration points on the monitor
    -- and doing planar approximation to find the transformation matrix
    -- between the monitor and the sensor.
    calibration = {}

    -- Display the calibration points on the monitor
    local function cls()
        monitor.setBackgroundColor(colors.lightGray)
        monitor.setTextColor(colors.black)
        monitor.clear()

        local text = "Press the + to calibrate"
        monitor.setCursorPos(math.floor((monitorWidth - #text) / 2), math.floor(monitorHeight / 2))
        monitor.write(text)
    end

    -- Wait for the user to touch the calibration points
    local function waitForTouch(expectedX, expectedY)
        while true do
            local event, side, x, y = os.pullEvent("monitor_touch")
            if x == expectedX and y == expectedY then
                return getOnePlayer()
            end
        end
    end

    cls()
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(1, 1)
    monitor.write("+")

    local p00 = waitForTouch(1, 1)
    local r00 = Ray(p00)

    cls()
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(monitorWidth, 1)
    monitor.write("+")

    local p10 = waitForTouch(monitorWidth, 1)
    local r10 = Ray(p10)

    cls()
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(monitorWidth, monitorHeight)
    monitor.write("+")

    local p11 = waitForTouch(monitorWidth, monitorHeight)
    local r11 = Ray(p11)

    cls()
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(1, monitorHeight)
    monitor.write("+")

    local p01 = waitForTouch(1, monitorHeight)
    local r01 = Ray(p01)

    -- Find the plane that best fits the calibration points
    local lookPlane = r00:getLookPlane()
    -- Sanity check that all the rays are looking at the same plane
    assert(eq3(lookPlane, r10:getLookPlane()), "Rays are not looking at the same plane")
    assert(eq3(lookPlane, r11:getLookPlane()), "Rays are not looking at the same plane")
    assert(eq3(lookPlane, r01:getLookPlane()), "Rays are not looking at the same plane")

    local worldPlaneCenter = -lookPlane * 0.5
    local worldPlaneCenterNorm = worldPlaneCenter:normalize()

    -- Max along look direction
    local marchPlaneStart = vmax(r00:pos(), r10:pos(), r11:pos(), r01:pos()):roundDirection5(lookPlane):mask(lookPlane)

    -- March until area is closest to expected size
    local marchPlane = marchPlaneStart
    local areaError = math.huge
    local ip00, ip10, ip11, ip01
    repeat
        ip00 = r00:intersectPlane(-lookPlane, marchPlane)
        ip10 = r10:intersectPlane(-lookPlane, marchPlane)
        ip11 = r11:intersectPlane(-lookPlane, marchPlane)
        ip01 = r01:intersectPlane(-lookPlane, marchPlane)

        -- Calculate area formed by the 4 calibration points
        local area = (ip00 - ip10):cross(ip00 - ip01):mag()/2
                   + (ip11 - ip10):cross(ip11 - ip01):mag()/2

        areaError = expectedArea - area
        print("March plane: " .. marchPlane:toString())
        print("Area error: " .. areaError .. " (" .. area .. " vs e@" .. expectedArea .. ")")

        marchPlane = marchPlane + lookPlane
    until math.abs(areaError) < 0.5

    marchPlane = marchPlane - lookPlane

    local xDir = (ip10 - ip00):normalize():round()
    local yDir = (ip01 - ip00):normalize():round()
    local origin = ip00:roundDirection5(-xDir):roundDirection5(-yDir)

    -- Fix blockWidthPerChar and blockHeightPerChar
    local blockWidth = math.ceil((ip10 - ip00):mag())
    local blockHeight = math.ceil((ip01 - ip00):mag())
    blockWidthPerChar  = (blockWidth  - (bleedX * 2)) / monitorWidth
    blockHeightPerChar = (blockHeight - (bleedY * 2)) / monitorHeight

    -- add bleed
    -- origin = origin + xDir * bleedX * blockWidthPerChar
    -- origin = origin + yDir * bleedY * blockHeightPerChar

    print("Look plane: " .. lookPlane:toString())
    print("Found plane: " .. marchPlane:toString())
    print("xDir: " .. xDir:toString())
    print("yDir: " .. yDir:toString())
    print(ip01:toString() .. " - " .. ip00:toString())
    print((ip01 - ip00):toString())
    print((ip01 - ip00):normalize():toString())
    print((ip01 - ip00):normalize():round():toString())
    print(ip01:toString() .. " = " .. r01:pos():toString() .. ">" .. r01:dir():toString() .. " intersect by " .. (-lookPlane):toString() .. "@" .. marchPlane:toString())
    print("Origin: " .. origin:toString())

    calibration = {
        xDir        = xDir,
        yDir        = yDir,
        origin      = origin,
        lookPlane   = lookPlane,
        screenPlane = marchPlane,
        blockWidth  = blockWidth,
        blockHeight = blockHeight,
    }

    local handle = fs.open("calibration", "w")
    handle.write(textutils.serialize(calibration))
    handle.close()
end



-- Try to find a player that is looking at that position on the monitor
local function reconcileTouch(x, y)
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
                -- print(screenHit:toString() .. " (" .. (screenHit - calibration.origin):toString() .. ")")

                if monHitX < borderX or monHitX > monitorWidth + borderX or monHitY < borderY or monHitY > monitorHeight + borderY then
                    -- Not on the screen
                else
                    -- Cap to bleed
                    screenX = math.max(1, math.min(monitorWidth, screenX))
                    screenY = math.max(1, math.min(monitorHeight, screenY))

                    -- print("thikning about " .. players[i].name .. " at " .. screenX .. ", " .. screenY)

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
                -- print(screenHit:toString() .. " (" .. (screenHit - calibration.origin):toString() .. ")")

                if monHitX < borderX or monHitX > monitorWidth + borderX or monHitY < borderY or monHitY > monitorHeight + borderY then
                    -- Not on the screen
                else
                    -- Cap to bleed
                    screenX = math.max(1, math.min(monitorWidth, screenX))
                    screenY = math.max(1, math.min(monitorHeight, screenY))

                    -- print("thikning about " .. players[i].name .. " at " .. screenX .. ", " .. screenY)

                    monitor.setCursorPos(screenX, screenY)
                    monitor.setBackgroundColor(2^math.random(0,15))
                    monitor.write("X")
                    -- local error = V3(screenX - x + 0.5, screenY - y + 0.5, 0):mag()
                    -- if error < 2 then
                    --     if foundPlayer ~= nil then
                    --         -- Multiple players are looking at this point
                    --         return nil
                    --     end

                    --     -- TODO: Check theyre not moving around by constantly sensing and checking eye ray is consistent

                    --     foundPlayer = players[i]
                    -- end
                end
            end
        end
    end

    return foundPlayer
end

-- term.redirect(monitor)
-- term.setBackgroundColor(colors.black)
-- term.setTextColor(colors.white)
-- term.clear()
-- term.setCursorPos(1,1)
-- while true do
--     -- getLookPosition()
--     -- sleep()
--     local event, side, x, y = os.pullEvent("monitor_touch")
--     local player = reconcileTouch(x, y)
--     if player ~= nil then
--         print("Player " .. player.name .. " touched " .. x .. ", " .. y)
--     else
--         print("No player touched " .. x .. ", " .. y)
--     end
-- end

return {
    reconcileTouch = reconcileTouch,
    getLookPosition = getLookPosition,
}
