---@class WaypointUtils
local utils = {}

function utils.hexToRgb(hex)
    hex = hex:gsub('#', '')
    return tonumber(hex:sub(1, 2), 16) or 255,
        tonumber(hex:sub(3, 4), 16) or 255,
        tonumber(hex:sub(5, 6), 16) or 255
end

function utils.drawTexturedTriangle(pos, width, height, r, g, b, a, txd, txn)
    local camPos = GetFinalRenderedCamCoord()
    local halfW = width / 2

    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = camPos - pos
    local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
    local right = norm(cross(up, forward))

    local topLeft = pos - (right * halfW) + (up * height)
    local topRight = pos + (right * halfW) + (up * height)
    local bottom = pos

    DrawTexturedPoly(
        topRight.x, topRight.y, topRight.z,
        topLeft.x, topLeft.y, topLeft.z,
        bottom.x, bottom.y, bottom.z,
        r, g, b, a,
        txd, txn,
        1.0, 0.0, 0.0, -- topRight UV
        0.0, 0.0, 0.0, -- topLeft UV
        0.5, 1.0, 0.0  -- bottom UV (centered horizontally)
    )
end

---@param worldPos vector3
---@return boolean onScreen
---@return number screenX
---@return number screenY
function utils.worldToScreen(worldPos)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(worldPos.x, worldPos.y, worldPos.z)
    return onScreen == true or onScreen == 1, screenX, screenY
end

---@param basePos vector3
---@param width number
---@param height number
---@return boolean onScreen
---@return number screenX
---@return number screenY
---@return number screenWidth
---@return number screenHeight
function utils.getBillboardScreenRect(basePos, width, height)
    local camPos = GetFinalRenderedCamCoord()
    local halfW = width / 2

    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = camPos - basePos
    local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
    local right = norm(cross(up, forward))

    local bottom = basePos
    local topLeft = basePos - (right * halfW) + (up * height)
    local topRight = basePos + (right * halfW) + (up * height)

    local bottomVisible, bottomX, bottomY = GetScreenCoordFromWorldCoord(bottom.x, bottom.y, bottom.z)
    local leftVisible, leftX, leftY = GetScreenCoordFromWorldCoord(topLeft.x, topLeft.y, topLeft.z)
    local rightVisible, rightX, rightY = GetScreenCoordFromWorldCoord(topRight.x, topRight.y, topRight.z)

    local onScreen = (bottomVisible == true or bottomVisible == 1)
        and (leftVisible == true or leftVisible == 1)
        and (rightVisible == true or rightVisible == 1)

    if not onScreen then
        return false, 0.0, 0.0, 0.0, 0.0
    end

    local screenWidth = math.abs(rightX - leftX)
    local topY = (leftY + rightY) * 0.5
    local screenHeight = math.abs(bottomY - topY)
    local screenX = (leftX + rightX) * 0.5

    return true, screenX, bottomY, screenWidth, screenHeight
end

---@param distance number
---@param width number
---@param height number
---@return number screenWidth
---@return number screenHeight
function utils.getScreenSizeFromWorldSize(distance, width, height)
    distance = math.max(distance, 0.01)

    local fov = math.rad(GetGameplayCamFov())
    local aspectRatio = GetAspectRatio(false)
    local verticalSpan = 2.0 * distance * math.tan(fov * 0.5)
    local horizontalSpan = verticalSpan * aspectRatio

    local screenWidth = width / horizontalSpan
    local screenHeight = height / verticalSpan

    return screenWidth, screenHeight
end

---@param fromPos vector3
---@param toPos vector3
---@param thickness number
---@return boolean onScreen
---@return number screenX
---@return number screenY
function utils.getWorldLineTopScreenAnchor(fromPos, toPos, thickness)
    local camPos = GetFinalRenderedCamCoord()
    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = camPos - fromPos
    local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
    local right = norm(cross(up, forward))
    local halfW = math.max(thickness or 0.0, 0.0) * 0.5

    local topLeft = toPos - (right * halfW)
    local topRight = toPos + (right * halfW)

    local leftVisible, leftX, leftY = GetScreenCoordFromWorldCoord(topLeft.x, topLeft.y, topLeft.z)
    local rightVisible, rightX, rightY = GetScreenCoordFromWorldCoord(topRight.x, topRight.y, topRight.z)

    local onScreen = (leftVisible == true or leftVisible == 1)
        and (rightVisible == true or rightVisible == 1)

    if not onScreen then
        return false, 0.0, 0.0
    end

    return true, (leftX + rightX) * 0.5, (leftY + rightY) * 0.5
end

---@param fromPos vector3
---@param toPos vector3
---@param r number
---@param g number
---@param b number
---@param a number
---@param thickness? number
---@param txd? string
---@param txn? string
function utils.drawWorldLine(fromPos, toPos, r, g, b, a, thickness, txd, txn)
    thickness = thickness or 0.0

    if thickness <= 0.0 or not txd or not txn then
        DrawLine(fromPos.x, fromPos.y, fromPos.z, toPos.x, toPos.y, toPos.z, r, g, b, a)
        return
    end

    local camPos = GetFinalRenderedCamCoord()
    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = camPos - fromPos
    local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
    local right = norm(cross(up, forward))
    local halfW = thickness * 0.5

    local bottomLeft = fromPos - (right * halfW)
    local bottomRight = fromPos + (right * halfW)
    local topLeft = toPos - (right * halfW)
    local topRight = toPos + (right * halfW)

    DrawTexturedPoly(
        topRight.x, topRight.y, topRight.z,
        topLeft.x, topLeft.y, topLeft.z,
        bottomRight.x, bottomRight.y, bottomRight.z,
        r, g, b, a,
        txd, txn,
        1.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.0, 1.0, 0.0
    )

    DrawTexturedPoly(
        topLeft.x, topLeft.y, topLeft.z,
        bottomLeft.x, bottomLeft.y, bottomLeft.z,
        bottomRight.x, bottomRight.y, bottomRight.z,
        r, g, b, a,
        txd, txn,
        0.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        1.0, 1.0, 0.0
    )
end

---@param worldPos vector3
---@param width number
---@param height number
---@param r number
---@param g number
---@param b number
---@param a number
---@param txd string
---@param txn string
function utils.drawWorldSpriteBottomCenter(worldPos, width, height, r, g, b, a, txd, txn)
    SetDrawOrigin(worldPos.x, worldPos.y, worldPos.z, 0)
    DrawSprite(txd, txn, 0.0, -(height * 0.5), width, height, 0.0, r, g, b, a)
    ClearDrawOrigin()
end

-- function utils.drawTexturedQuad(pos, width, height, r, g, b, a, txd, txn)
--     local camPos = GetFinalRenderedCamCoord()
--     local halfW = width / 2
--     local halfH = height / 2
--
--     local up = vec3(0.0, 0.0, 1.0)
--     local toCamera = camPos - pos
--     local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
--     local right = norm(cross(up, forward))
--
--     local topLeft = pos - (right * halfW) + (up * halfH)
--     local topRight = pos + (right * halfW) + (up * halfH)
--     local bottomLeft = pos - (right * halfW) - (up * halfH)
--     local bottomRight = pos + (right * halfW) - (up * halfH)
--
--     DrawTexturedPoly(
--         bottomRight.x, bottomRight.y, bottomRight.z,
--         topRight.x, topRight.y, topRight.z,
--         bottomLeft.x, bottomLeft.y, bottomLeft.z,
--         r, g, b, a,
--         txd, txn,
--         1.0, 1.0, 0.0,
--         1.0, 0.0, 0.0,
--         0.0, 1.0, 0.0
--     )
-- end

return utils
