--[[
Title: NetEntity
Author(s):  wxa
Date: 2021-06-01
Desc: Net 玩家实体类
use the lib:
------------------------------------------------------------
local NetEntity = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/NetEntity.lua");
------------------------------------------------------------
]]

local Entity = require("Entity");
local Net = require("Net");

local NetEntity = inherit(Entity, module("NetEntity"));

local NET_ENTITY_SYNC = "NET_ENTITY_SYNC";
local NET_ENTITY_DESTROY = "NET_ENTITY_DESTROY";

function NetEntity:ctor()

end

function NetEntity:Init(opts)
    NetEntity._super.Init(self, opts);
    return self;
end

function NetEntity:Destroy()
    NetEntity._super.Destroy(self);
    Net:Send({
        action = NET_ENTITY_DESTROY,
        __key__ = self.__key__,
    });
end

function NetEntity:SendSyncData()
    Net:Send({
        action = NET_ENTITY_SYNC,
        data = self:GetSyncData(),
    });
end

local function NetEntityRecvSyncData(data)
    (GetEntityByKey(data.__key__) or NetEntity:new():Init()):SetSyncData(data);    
end

-- 收到数据
Net:OnRecv(function(msg)
    local action = msg.action;
    if (action == NET_ENTITY_SYNC) then return NetEntityRecvSyncData(msg.data) end
    if (action == NET_ENTITY_DESTROY) then return DestroyEntityByKey() end 
end);



