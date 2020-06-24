--[[
Title: Player
Author(s): wxa
Date: 2020/6/10
Desc: 世界玩家对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/Player.lua");
local Player = commonlib.gettable("GeneralGameServerMod.Server.Player");
Player:new():Init()
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Player = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.Player"));

-- 构造函数
function Player:ctor() 
    self.entityInfo = nil;
    self.dataWatcher = DataWatcher:new();
end

function Player:Init(entityId, username)
    self.entityId = entityId;
    self.username = username or tostring(entityId);

    return self;
end

function Player:GetUserName() 
    return self.username;
end

function Player:SetPlayerEntityInfo(packetPlayerEntityInfo)
    local isNew = false;
    if not self.entityInfo then
        self.entityInfo = {};
        isNew = true;
    end

    -- 元数据为监控对象列表
    local metadata = packetPlayerEntityInfo:GetMetadata();
    for i = 1, #(metadata or {}) do
        local obj = metadata[i];
        self.dataWatcher:AddField(obj:GetId(), obj:GetObject());
    end
    
    for key, val in pairs(packetPlayerEntityInfo) do
        if (val ~= nil and key ~= "id" and key ~= "cmd" and key ~= "data") then
            self.entityInfo[key] = packetPlayerEntityInfo[key];
        end
    end

    return isNew;
end

function Player:GetPlayerEntityInfo()
    return Packets.PacketPlayerEntityInfo:new():Init(self.entityInfo, self.dataWatcher, true);
end

function Player:SetNetHandler(netHandler)
    self.playerNetHandler = netHandler;
end

function Player:KickPlayerFromServer(reason)
    return self.playerNetHandler and self.playerNetHandler:KickPlayerFromServer(reason);
end

function Player:SendPacketToPlayer(packet)
    self.playerNetHandler:SendPacketToPlayer(packet);
end