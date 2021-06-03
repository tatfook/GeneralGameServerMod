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
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")

-- local EntityNPCOnline NPL.load("../../Game/Entity/EntityNPCOnline.lua");

local EntityAPI = NPL.export()

local function CreateNPC(CodeEnv, ...)
    local npc = EntityNPCOnline:Create(...)
    npc:Attach()
    table.insert(CodeEnv.__entities__, npc)
    return npc
end

function CreateEntity(bx, by, bz, path, canBeCollied)
    NPL.load("scrtip/Truck/Game/Entity/EntityCustom.lua")
    local EntityCustom = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCustom")
    local entity = EntityCustom:Create({bx = bx, by = by, bz = bz, mModel = path or "", mEnablePhysics = canBeCollied})
    table.insert(CodeEnv.__entities__, entity)
    return entity
end

setmetatable(
    EntityAPI,
    {
        __call = function(_, CodeEnv)
            CodeEnv.GetAllEntities = EntityManager.GetAllEntities
            CodeEnv.GetEntityById = EntityManager.GetEntityById
            CodeEnv.GetEntitiesInBlock = EntityManager.GetEntitiesInBlock
            CodeEnv.GetPlayer = EntityManager.GetPlayer
            CodeEnv.CreateNPC = function(...)
                return CreateNPC(CodeEnv, ...)
            end
            CodeEnv.CreateEntity = function(bx, by, bz, path, canBeCollied)
                return CreateEntity(CodeEnv, bx, by, bz, path, canBeCollied)
            end
        end
    }
)
