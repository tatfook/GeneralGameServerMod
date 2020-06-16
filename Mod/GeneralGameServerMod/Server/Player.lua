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

local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
-- 对象定义
local Player = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.Player"));

-- 构造函数
function Player:ctor() 
    self.packetPlayerEntityInfo = nil;
end

function Player:Init(entityId, username)
    self.entityId = entityId;
    self.username = username or tostring(entityId);

    return self;
end

function Player:GetUserName() 
    return self.username;
end

function Player:SetPlayerEntityInfo(entityInfo)
    local isNew = false;
    if not self.packetPlayerEntityInfo then
        self.packetPlayerEntityInfo = Packets.PacketPlayerEntityInfo:new():Init();
        isNew = true;
    end

    for key, val in pairs(entityInfo) do
        if (val ~= nil and key ~= "id" and key ~= "cmd") then
            self.packetPlayerEntityInfo[key] = entityInfo[key];
        end
    end

    return isNew;
end

function Player:GetPlayerEntityInfo()
    return self.packetPlayerEntityInfo;
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