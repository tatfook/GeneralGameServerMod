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
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EntitySync = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.EntitySync");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");

local __all_sync_key_entity_map__ = {};    -- 所有需要同步的实体
local __is_can_sync_entity_map__  = {};    -- 实体是否可以同步
local __sync_queue_entity_map__ = {};      -- 待同步的实体集

-- 重置数据
local function Reset()
    __all_sync_key_entity_map__ = {};    -- 所有需要同步的实体
    __is_can_sync_entity_map__  = {};    -- 实体是否可以同步
    __sync_queue_entity_map__ = {};      -- 待同步的实体集
end

-- 加载世界之前清除数据
GameLogic.GetFilters():add_filter("OnBeforeLoadWorld", function()
    Reset();
end);

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
    CommonLib.ClearTable(__sync_queue_entity_map__);
end});

-- 添加到同步队列
local function AddEntityToSyncQueue(entity, bDelete)
    if (__is_can_sync_entity_map__[entity] == false) then return end 

    local key = entity:GetKey();
    -- print("---------AddEntityToSyncQueue----------", key)
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
        local EntityClass = EntityManager.GetEntityClass(packet.attr.class);
        entity = EntityClass:new();
        __is_can_sync_entity_map__[entity] = false;
        entity:init():Attach();
    else 
        __is_can_sync_entity_map__[entity] = false;
    end

    if (packet) then entity:LoadFromXMLNode(packet) end 
    
	local obj = entity:GetInnerObject();
    if(obj) then
        obj:SetFacing(entity:GetFacing());
        obj:SetPosition(entity:GetPosition());
        obj:UpdateTileContainer();
    end
    
    __all_sync_key_entity_map__[key] = entity;
    __is_can_sync_entity_map__[entity] = nil;
end 

function EntitySync:HandleSyncEntityListData(data)
    local list = data.packet;
    if (not data.packet) then return end 
    
    local key_map = {};
    for key, packet in pairs(list) do
        key_map[key] = true;
        self:HandleSyncEntityData(key, packet);
    end

    for key in pairs(__all_sync_key_entity_map__) do
        if (not key_map[key]) then
            self:HandleSyncEntityData(key, nil, "delete");
        end
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
        -- entity:SetKey(nil);

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

--[[
Entity 同步逻辑:
1. 需要同步的Entity, 调用EntitySync绑定数据更新回调事件
2. Entity 发生变更, 以Entity对象地址为KEY, 加入同步队列(存在覆盖), 激活同步timerout定时器(100ms)
3. 同步定时器执行同步回调, 打包同步队列里的Entity的信息到服务器缓存并转发至其它玩家, 清空同步队列
4. 收到Entity同步事件, 通过Entity Key找到Entity, 禁用当前Entity同步, 加载同步信息, 更新位置, 恢复当前Entity同步

Entity 初始化逻辑:
1. 加载世界, 清空相关数据集
2. 注册世界里需要同步的Entity信息变更回调
3. ggs connect 登录成功回调执行拉取服务器缓存的Entity信息集并同步至场景. (服务器没有缓存信息时, 保留当前世界Entity集, 否则取服务器Entity集)

## TODO
Entity 数据包未包含类信息, 目前只支持EntityLiveModel(默认类)

主实现文件:
Client: Mod/GeneralGameServerMod/App/Client/EntitySync.lua
Server: Mod/GeneralGameServerMod/App/Server/AppServerDataHandler.lua
]]