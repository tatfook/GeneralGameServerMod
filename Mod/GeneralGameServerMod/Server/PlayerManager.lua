--[[
Title: PlayerManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界玩家
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/PlayerManager.lua");
local PlayerManager = commonlib.gettable("GeneralGameServerMod.Server.PlayerManager");

-------------------------------------------------------
]]

-- 文件加载
NPL.load("Mod/GeneralGameServerMod/Server/Player.lua");

-- 对象获取
local Player = commonlib.gettable("GeneralGameServerMod.Server.Player");

-- 对象定义
local PlayerManager = commonlib.inherit(nil, commonlib.gettable("GeneralGameServerMod.Server.PlayerManager"));


function PlayerManager:ctor()
    self.playerList = commonlib.UnorderedArraySet:new();
end

function PlayerManager:Init(world)
    self.world = world;  -- 所属世界

    return self;
end

-- 创建用户 若用户已存在则踢出系统
function PlayerManager:CreatePlayer(username, netHandler)
    local duplicated_players;
    local username_lower_cased = string.lower(username);
    for i = 1, #(self.playerList) do
        local player = self.playerList[i];
        if (string.lower(player:GetUserName() or "") == username_lower_cased) then
			duplicated_players = duplicated_players or {};
			duplicated_players[#duplicated_players+1] = player;
        end
    end

    if(duplicated_players) then
		for i=1, #(duplicated_players) do
			local player = duplicated_players[i];
			player:KickPlayerFromServer("You logged in from another location");
		end
	end
    
    local player = Player:new():Init(username);
    player:SetNetHandler(netHandler);

    return player;
end

function PlayerManager:AddPlayer(player)
    self.playerList:add(player);
end

function PlayerManager:RemovePlayer(player)
    self.playerList:removeByValue(player);
end

