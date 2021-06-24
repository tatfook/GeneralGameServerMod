--[[
Title: EntityAPI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local EntityAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/EntityAPI.lua");
------------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EntityNPC = NPL.load("../../Game/Entity/EntityNPC.lua", IsDevEnv);

local EntityAPI = NPL.export()


local function CreateNPC(CodeEnv, ...)
    local npc = EntityNPC:Create(...)
    npc:Attach()
    table.insert(CodeEnv.__entities__, npc)
    return npc
end

local function getEntity(id)
    if type(id) == "table" then
        return id
    end
    return EntityManager.GetEntityById(id)
end

-- local function SetEntityHeadOnText(id, str, color, font)
--     local e = getEntity(id)
--     if not e or not str then
--         return
--     end
--     local name = e:GetHeadonObject("name")
--     if not name then
--         HeadonUtility.initHeadonObjects(e, {"name"})
--         name = e:GetHeadonObject("name")
--     end
--     name:setText(str)
--     if color then
--         name:setColor(color)
--     end

--     if font then
--         name:setFont(font)
--     end
-- end

-- local function GetEntityHeadOnObject(id, name)
--     local e = getEntity(id)
--     if not e or not name then
--         return
--     end
--     local o = e:GetHeadonObject(name)
--     if not o then
--         o = HeadonObject:new():init(e:GetInnerObject())
--         e:AddHeadonObject(name, o)
--     end
--     return o
-- end

local function EnableEntityPicked(id, enable)
    local e = getEntity(id)
    if e then
        local o = e:GetInnerObject()
        if o then
            o:SetAttribute(0x8000, not enable)
        end
    end
end

local function GetEntityBlockPos(id)
    local e = getEntity(id)
    if e then
        return e:GetBlockPos()
    end
end

local function SetEntityBlockPos(id, x, y, z)
    local e = getEntity(id)
    if e then
        return e:TeleportToBlockPos(x, y, z)
    end
end

local function GetEntityDirection(id)
    local e = getEntity(id)
    local facing = e:GetFacing()
    local sin = math.sin(facing)
    local cos = math.cos(facing)
    return {cos, 0, -sin}
end

setmetatable(
    EntityAPI,
    {
        __call = function(_, CodeEnv)
            CodeEnv.GetAllEntities = EntityManager.GetAllEntities
            CodeEnv.GetEntityById = EntityManager.GetEntityById
            CodeEnv.GetEntitiesInBlock = EntityManager.GetEntitiesInBlock
            CodeEnv.GetEntityBlockPos = GetEntityBlockPos
            CodeEnv.SetEntityBlockPos = SetEntityBlockPos
            CodeEnv.EnableEntityPicked = EntityManager.EnableEntityPicked
            CodeEnv.CreateNPC = function(...) return CreateNPC(CodeEnv, ...) end
        end
    }
)
