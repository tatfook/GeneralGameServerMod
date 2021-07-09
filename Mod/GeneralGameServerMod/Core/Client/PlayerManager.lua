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
PlayerManager:Property("UserVisible", true, "IsUserVisible");                        -- 玩家是否可见
PlayerManager:Property("OfflineUserVisible", true, "IsOfflineUserVisible");          -- 离线玩家是否可见   

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
    
    -- 存在同名旧玩家且不为当前对象则先移除
    local oldplayer = self.players[username];
    if (oldplayer ~= entityPlayer) then self:RemovePlayer(oldplayer) end
    entityPlayer:Attach();
    
    -- 添加新玩家
    -- if (self:IsVisible(entityPlayer)) then 
    --     entityPlayer:Attach();
    -- else
    --     entityPlayer:Destroy();
    -- end
    self.players[username] = entityPlayer;
    entityPlayer:SetVisible(self:IsUserVisible());
end

function PlayerManager:RemovePlayer(entityPlayer)
    if (type(entityPlayer) == "string") then entityPlayer = self.players[entityPlayer] end
    if (not entityPlayer) then return end
    local username = entityPlayer:GetUserName();
    entityPlayer:Destroy();
    self.players[username] = nil;
end

function PlayerManager:GetPlayerByUserName(username)
    return self.players[username or ""];
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
    if (not self:GetMainPlayer()) then return false end
    local areaSize = math.floor(self:GetAreaSize() or 0);
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

-- 隐藏离线用户
function PlayerManager:HideOfflinePlayers()
    self:SetOfflineUserVisible(false);
    for _, player in pairs(self.players) do 
        if (not player:IsOnline()) then
            player:SetVisible(false);
        end
    end
end

-- 显示离线用户
function PlayerManager:ShowOfflinePlayers()
    self:SetOfflineUserVisible(true);
    for _, player in pairs(self.players) do 
        player:SetVisible(true);
    end
end

-- 隐藏离线用户
function PlayerManager:HideAllPlayers()
    self:SetUserVisible(false);
    for _, player in pairs(self.players) do 
        player:SetVisible(false);
    end
end

-- 显示离线用户
function PlayerManager:ShowAllPlayers()
    for _, player in pairs(self.players) do 
        player:SetVisible(true);
    end
    self:SetUserVisible(true);
end
