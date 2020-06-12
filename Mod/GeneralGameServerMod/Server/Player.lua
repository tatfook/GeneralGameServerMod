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

-- 对象定义
local Player = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.Player"));

-- 构造函数
function Player:ctor() 
end

function Player:Init(playerId, username)
    self.playerId = playerId;
    self.username = username or tostring(playerId);

    return self;
end

function Player:GetUserName() 
    return self.username;
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