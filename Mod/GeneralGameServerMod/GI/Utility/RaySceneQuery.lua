local RaySceneQuery = commonlib.inherit(nil, NPL.export())
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")

function RaySceneQuery:init(ox, oy, oz, dx, dy, dz)
    self.origin = {ox, oy, oz}
    self.direction = {dx, dy, dz}
end

function RaySceneQuery:setDirection(dx, dy, dz)
    self.direction = {dx, dy, dz}
end

function RaySceneQuery:setOrigin(ox, oy, oz)
    self.origin = {ox, oy, oz}
end

function RaySceneQuery:setMaxDistance(dist)
    self.maxDistance = dist
end

function RaySceneQuery:setMask(mask)
    self.mask = mask
end

function RaySceneQuery:useBlockPos(value)
    self.isUsingBlockPos = value
end

local function queryBlock(o, d, result, dist, mask)
    ParaTerrain.Pick(o[1], o[2], o[3], d[1], d[2], d[3], dist, result, mask or 0x85) -- 0x85 means to discard liquid block
    if not result or not result.blockX then
        return
    end

    result.block_id = ParaTerrain.GetBlockTemplateByIdx(result.blockX, result.blockY, result.blockZ)
    if result.block_id <= 0 then
        return
    end
end

local function queryPoint(o, d, result, dist)
    local pt = ParaScene.Pick(o[1], o[2], o[3], d[1], d[2], d[3], dist, "point")
    if (not pt:IsValid()) then
        return
    end

    local x, y, z = pt:GetPosition()
    local blockX, blockY, blockZ = BlockEngine:block(x, y + 0.1, z) -- tricky we will slightly add 0.1 to y value.

    local eye_pos = {0, 0, 0}
    eye_pos = ParaCamera.GetAttributeObject():GetField("Eye position", eye_pos)
    local length = math.sqrt((eye_pos[1] - x) ^ 2 + (eye_pos[2] - y) ^ 2 + (eye_pos[3] - z) ^ 2)

    if (not result.length or (result.length >= dist) or (result.length > length)) then
        result.length = length
        result.x, result.y, result.z = x, y, z
        result.blockX, result.blockY, result.blockZ = blockX, blockY - 1, blockZ
        result.side = 5
        result.block_id = nil
        local entityName = pt:GetName()
        if (not entityName) then
            return
        end

        local bx, by, bz = entityName:match("^(%d+),(%d+),(%d+)$")
        if (not bx) then
            return
        end

        bx = tonumber(bx)
        by = tonumber(by)
        bz = tonumber(bz)
        local entity = BlockEngine:GetBlockEntity(bx, by, bz)
        if (not entity) then
            return
        end

        result.entity = entity
        result.block_id = result.block_id or entity:GetBlockId()
        result.blockY = blockY -- restore blockY-1 in case terrain point is picked.
    end
end

local function queryObject(o, d, result, dist)
    local obj_filter
    local obj = ParaScene.Pick(o[1], o[2], o[3], d[1], d[2], d[3], result.length or dist, "anyobject")
    if (not obj:IsValid() or obj.name == "_bm_") then
        -- ignore block custom model
        obj = nil
    else
        result.obj = obj
        local x, y, z = obj:GetPosition()
        local eye_pos = {0, 0, 0}
        eye_pos = ParaCamera.GetAttributeObject():GetField("Eye position", eye_pos)
        local length = math.sqrt((eye_pos[1] - x) ^ 2 + (eye_pos[2] - y) ^ 2 + (eye_pos[3] - z) ^ 2)
        result.length = length
        result.x, result.y, result.z = x, y, z
        local blockX, blockY, blockZ = BlockEngine:block(x, y + 0.1, z) -- tricky we will slightly add 0.1 to y value.
        result.blockX, result.blockY, result.blockZ = blockX, blockY - 1, blockZ
        result.side = 5
        result.block_id = nil
        result.entity = EntityManager.GetEntityByObjectID(obj:GetID())
    end
end

function RaySceneQuery:query(bPickBlocks, bPickPoint, bPickObjects)
    local o = self.origin
    local d = self.direction
    if self.isUsingBlockPos then
        o = {BlockEngine:real(o[1], o[2], o[3])}
    end
    local distance = self.maxDistance or 50
    local result = {length = distance}
    if bPickBlocks ~= false then
        queryBlock(o, d, result, distance, self.mask or 0x85)
    end

    -- pick any point (like terrain and phyical mesh)
    if (bPickPoint ~= false) then
        queryPoint(o, d, result, distance)
    end

    -- pick any scene object
    if (bPickObjects ~= false) then
        queryObject(o, d, result, distance)
    end

    return result
end
