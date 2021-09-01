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
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovable.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EntityAPI = NPL.export()

local function getEntity(id)
    if type(id) == "table" then return id end
    return EntityManager.GetEntityById(id)
end

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

local function FindEntities(...)
    return EntityManager.FindEntities(...);
end

local function GetAllEntityCode()
    local entities = FindEntities({category="b", }) or {};
    local list = {};
    for _, entity in ipairs(entities) do
        if (entity.class_name == "EntityCode") then
            table.insert(list, entity);
        end
    end
    return list;
end

local function SetFocus(entity)
    EntityManager.SetFocus(entity);
end

setmetatable(
    EntityAPI,
    {
        __call = function(_, CodeEnv)
            CodeEnv.GetAllEntities = EntityManager.GetAllEntities;
            CodeEnv.GetEntityById = EntityManager.GetEntityById;
            CodeEnv.GetEntitiesInBlock = EntityManager.GetEntitiesInBlock;
            CodeEnv.GetEntityBlockPos = GetEntityBlockPos;
            CodeEnv.SetEntityBlockPos = SetEntityBlockPos;
            CodeEnv.EnableEntityPicked = EntityManager.EnableEntityPicked;
            CodeEnv.FindEntities = FindEntities;
            CodeEnv.GetAllEntityCode = GetAllEntityCode;
            CodeEnv.SetFocus = SetFocus;
        
            local __entity_co_map__ = {};

            CodeEnv.__AddEntity__ = function(entity) 
                CodeEnv.__entities__[entity] = entity;
            
                -- 协程标记
                local __co__ = CodeEnv.__coroutine_running__();
                __entity_co_map__[entity] = __co__;
                CodeEnv.__get_coroutine_data__(__co__).__entities__[entity] = entity;
            end
            
            CodeEnv.__RemoveEntity__ = function(entity)
                CodeEnv.__entities__[entity] = nil;
            
                -- 协程标记
                CodeEnv.__get_coroutine_data__(__entity_co_map__[entity]).__entities__[entity] = nil;
                __entity_co_map__[entity] = nil;
            end

            CodeEnv.__GetAllEntity__ = function() 
                return CodeEnv.__entities__;
            end
            local __entity_list__ = {};
            CodeEnv.__GetEntityList__ = function()
                local size = #__entity_list__;
                for index = 1, size do __entity_list__[index] = nil end
                for _, entity in pairs(CodeEnv.__entities__) do table.insert(__entity_list__, entity) end
                return __entity_list__;
            end


            CodeEnv.__ClearAllEntity__ = function()
                for _, entity in ipairs(CodeEnv.__GetEntityList__()) do
                    entity:Destroy();
                end 
            end
            
            CodeEnv.__Entity__ = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovable");
            CodeEnv.__EntityLight__ = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLight");
        end
    }
)
