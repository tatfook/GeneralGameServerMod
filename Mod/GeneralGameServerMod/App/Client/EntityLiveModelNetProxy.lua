--[[
Title: EntityLiveModelNetProxy
Author(s): wxa
Date: 2020/6/15
Desc: 活动模型同步
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/Client/EntityLiveModelNetProxy.lua");
local EntityLiveModelNetProxy = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.EntityLiveModelNetProxy");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
local EntityLiveModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel");

local EntityLiveModelNetProxy = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.EntityLiveModelNetProxy");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");

local EntityLiveModelMap = {};
local IsCanSyncMap = {};

local function SyncEntityLiveModel(entity, action)
    if (IsCanSyncMap[entity] == false) then return end 

    local key = entity:GetKey();
    EntityLiveModelMap[key] = EntityLiveModelMap[key] or entity;
    if (action == "delete") then 
        EntityLiveModelMap[key] = nil; 
        IsCanSyncMap[entity] = nil;
    end 
    if (type(AppGeneralGameClient.GetClientDataHandler) ~= "function") then return end 
    local data_handler = AppGeneralGameClient:GetClientDataHandler();
    if (not data_handler) then return end 
    local packet = entity:SaveToXMLNode();
    local data = {packet = packet, key = key, cmd = "SyncEntityLiveModel", action = action};
    data_handler:SendData(data);
end

function EntityLiveModelNetProxy:SendData(data)
    if (type(AppGeneralGameClient.GetClientDataHandler) ~= "function") then return end 
    local data_handler = AppGeneralGameClient:GetClientDataHandler();
    if (not data_handler) then return end 
    data.cmd = "SyncEntityLiveModel";
    data_handler:SendData(data);
end

function EntityLiveModelNetProxy:HandleSyncEntityLiveModelData(data)
    local key = data.attr.key;
    local entity = EntityLiveModelMap[key];
    if (data.action == "delete") then
        EntityLiveModelMap[key] = nil;
        if (entity) then
            entity:Destroy();
            IsCanSyncMap[entity] = nil;            
        end 
        return ;
    end
    if (not entity) then
        entity = EntityLiveModel:new();
        IsCanSyncMap[entity] = false;
        entity:init():Attach();
    else 
        IsCanSyncMap[entity] = false;
    end

    entity:LoadFromXMLNode(data);
	local obj = entity:GetInnerObject();
    if(obj) then
        obj:SetPosition(entity:GetPosition());
        obj:UpdateTileContainer();
    end
    EntityLiveModelMap[entity:GetKey()] = entity;
    IsCanSyncMap[entity] = true;
end 


function EntityLiveModelNetProxy:HandleSyncEntityLiveModelListData(data)
    local list = data.packet or {};
    for _, item in pairs(list) do
        self:HandleSyncEntityLiveModelData(item);
    end
end 

function EntityLiveModelNetProxy:OnLogin()
    self:SendData({action = "pull_all"});
end

function EntityLiveModelNetProxy:OnRecvData(data)
    if (type(data) ~= "table" or data.cmd ~= "SyncEntityLiveModel") then return end 

    if (data.action == "create" or data.action == "update" or data.action == "delete") then return self:HandleSyncEntityLiveModelData(data.packet) end 

    if (data.action == "pull_all") then return self:HandleSyncEntityLiveModelListData(data) end 

    return true;
end

function EntityLiveModelNetProxy:EntityLiveModelMap()
    return EntityLiveModelMap;
end

setmetatable(EntityLiveModelNetProxy, {
    __call = function(_, entity)
        entity:Connect("valueChanged", nil, function()
            SyncEntityLiveModel(entity, "update");
        end);
        entity:Connect("facingChanged", nil, function()
            SyncEntityLiveModel(entity, "update");
        end);
        entity:Connect("scalingChanged", nil, function()
            SyncEntityLiveModel(entity, "update");
        end);
        entity:Connect("beforeDestroyed", nil, function()
            SyncEntityLiveModel(entity, "delete");
        end);
        SyncEntityLiveModel(entity, "create");
    end
});