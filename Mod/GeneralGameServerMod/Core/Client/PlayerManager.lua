--[[
Title: PlayerManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界玩家
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/PlayerManager.lua");
local PlayerManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.PlayerManager");
-------------------------------------------------------
]]

local PlayerManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.PlayerManager"));

PlayerManager:Property("World");            -- 玩家管理器所属世界
PlayerManager:Property("MainPlayer");       -- 主玩家
PlayerManager:Property("AreaSize");         -- 玩家可视区域

function PlayerManager:ctor()
    self.players = {};   -- 玩家集
end

function PlayerManager:Init(world)
    self:SetWorld(world);
    return self;
end

function PlayerManager:AddPlayer(entityPlayer)
    if (not entityPlayer) then return end
    local username = entityPlayer:GetUserName();
    if (not username) then return end;

    -- 不可见添加
    -- if (not self:IsVisible(entityPlayer)) then return end

    -- 存在同名旧玩家则先移除
    local oldplayer = self.players[username];
    if (oldplayer) then self:RemovePlayer(oldplayer) end
    
    -- 添加新玩家
    entityPlayer:Attach();
    self.players[username] = entityPlayer;
end

function PlayerManager:RemovePlayer(entityPlayer)
    if (type(entityPlayer) == "string") then entityPlayer = self.players[entityPlayer] end
    if (not entityPlayer) then return end
    local username = entityPlayer:GetUserName();
    entityPlayer:Destroy();
    self.players[username] = nil;
end

function PlayerManager:GetPlayerByUserName(username)
    for key, player in pairs(self.players) do 
        if (key == username) then
            return player;
        end
    end
end

function PlayerManager:GetPlayerByEntityId(entityId)
    for key, player in pairs(self.players) do 
        if (player.entityId == entityId) then
            return player;
        end
    end
end

-- 是否玩家是否可见
function PlayerManager:IsVisible(player)
    local playerBX, playerBY, playerBZ = player:GetBlockPos();
    return self:IsInnerVisibleArea(playerBX, playerBY, playerBZ);
end

-- 是否在可视区
function PlayerManager:IsInnerVisibleArea(bx, by, bz)
    local areaSize = self:GetAreaSize();
    if (not areaSize or areaSize == 0) then return true end
    local mainPlayerBX, mainPlayerBY, mainPlayerBZ = self:GetMainPlayer():GetBlockPos();
    return math.abs(bx - mainPlayerBX) <= areaSize and math.abs(bz - mainPlayerBZ) <= areaSize;
end

-- 获取所有玩家
function PlayerManager:GetPlayers()
    return self.players;
end

-- 移除所有玩家
function PlayerManager:ClearPlayers()
    for key, player in pairs(self.players) do 
        player:Destroy();
    end
    self.players = {};
end
