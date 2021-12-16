--[[
Title: EntitySync
Author(s): wxa
Date: 2020/6/15
Desc: 活动模型同步
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/Client/EntitySync.lua");
local EntitySync = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.EntitySync");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
local EntityLiveModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel");

local EntitySync = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.EntitySync");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");

local __all_sync_key_entity_map__ = {};    -- 所有需要同步的实体
local __is_can_sync_entity_map__  = {};    -- 实体是否可以同步
local __sync_queue_entity_map__ = {};      -- 待同步的实体集

-- 发送数据
local function SendData(data)
    local data_handler = AppGeneralGameClient:GetClientDataHandler();
    if (not data_handler) then return end 
    data.cmd = "SyncEntityLiveModel";
    data_handler:SendData(data);
end

-- 同步实体
local function SyncEntity(key)
    local entity = __all_sync_key_entity_map__[key];
    local action = entity and "update" or "delete";
    local packet = entity and entity:SaveToXMLNode();
    -- print("======Send=======", key, action);
    SendData({key = key, cmd = "SyncEntityLiveModel", action = action, packet = packet});
end

-- 同步定时器
local __sync_timer__ = commonlib.Timer:new({callbackFunc = function()
    for entity in pairs(__sync_queue_entity_map__) do 
        SyncEntity(entity:GetKey());
    end
end});

-- 添加到同步队列
local function AddEntityToSyncQueue(entity, bDelete)
    if (__is_can_sync_entity_map__[entity] == false) then return end 

    local key = entity:GetKey();
    if (bDelete) then
        __all_sync_key_entity_map__[key] = nil;
        return SyncEntity(key);  -- 删除立即执行
    else
        __all_sync_key_entity_map__[key] = __all_sync_key_entity_map__[key] or entity;
    end

    -- 添加至队列
    __sync_queue_entity_map__[entity] = entity;

    if (not __sync_timer__:IsEnabled()) then
        __sync_timer__:Change(100);
    end
end

function EntitySync:HandleSyncEntityData(key, packet, action)
    local entity = __all_sync_key_entity_map__[key];

    -- print("======Recv=======", key, action);
    if (action == "delete") then
        __all_sync_key_entity_map__[key] = nil;
        if (entity) then
            -- 避免删除触发同步
            __is_can_sync_entity_map__[entity] = false;            
            entity:Destroy();
            __is_can_sync_entity_map__[entity] = nil;            
        end 
        return ;
    end

    if (not entity) then
        entity = EntityLiveModel:new();
        __is_can_sync_entity_map__[entity] = false;
        entity:init():Attach();
    else 
        __is_can_sync_entity_map__[entity] = false;
    end

    entity:LoadFromXMLNode(packet);
	local obj = entity:GetInnerObject();
    if(obj) then
        obj:SetPosition(entity:GetPosition());
        obj:UpdateTileContainer();
    end
    __all_sync_key_entity_map__[key] = entity;
    __is_can_sync_entity_map__[entity] = nil;
end 

function EntitySync:HandleSyncEntityListData(data)
    local list = data.packet or {};
    for key, packet in pairs(list) do
        self:HandleSyncEntityData(key, packet);
    end
end 

function EntitySync:OnLogin()
    SendData({action = "pull_all"});
end

function EntitySync:OnRecvData(data)
    if (type(data) ~= "table" or data.cmd ~= "SyncEntityLiveModel") then return end 

    if (data.action == "create" or data.action == "update" or data.action == "delete") then return self:HandleSyncEntityData(data.key, data.packet, data.action) end 

    if (data.action == "pull_all") then return self:HandleSyncEntityListData(data) end 

    return true;
end

function EntitySync:GetAllEntity()
    return __all_sync_key_entity_map__;
end

setmetatable(EntitySync, {
    __call = function(_, entity)
        -- 保证唯一KEY存在
        entity:SetKey(nil);

        entity:Connect("valueChanged", nil, function()
            AddEntityToSyncQueue(entity);
        end);
        entity:Connect("facingChanged", nil, function()
            AddEntityToSyncQueue(entity);
        end);
        entity:Connect("scalingChanged", nil, function()
            AddEntityToSyncQueue(entity);
        end);
        entity:Connect("beforeDestroyed", nil, function()
            AddEntityToSyncQueue(entity, true);
        end);
        AddEntityToSyncQueue(entity);
    end
});