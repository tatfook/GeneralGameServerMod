
--[[
Title: World
Author(s): wxa
Date: 2020/6/10
Desc: 世界对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/World.lua");
local World = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.World");
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Server/PlayerManager.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local PlayerManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.PlayerManager");
local World = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.World"));

-- 一个世界对象, 应该包含世界的所有数据
function World:ctor()
    -- 实体ID 所有需要同步的实体都需从此分配
    self.nextEntityId = 0;

    -- 玩家管理器
    self.playerManager = PlayerManager:new():Init(self);
    
    -- 方块管理器
    -- self.blockManager = BlockManager:new();
end

-- 世界初始化
function World:Init(worldId, parallelWorldName, worldKey)
    self.worldId = worldId;
    self.parallelWorldName = parallelWorldName;
    self.key = worldKey;

    return self;
end

-- 设置世界key
function World:SetWorldKey(key)
    self.key = key;
end

-- 获取世界key
function World:GetWorldKey()
    return self.key;
end

-- 获取世界的平行世界名
function World:GetParallelWorldName()
    return self.parallelWorldName;
end

-- 获取世界实体ID
function World:GetNextEntityId()
    self.nextEntityId = self.nextEntityId + 1;
    if (self.nextEntityId > Config.maxEntityId) then
        self.nextEntityId = 0;
    end
    return self.nextEntityId;
end

-- 获取世界用户数
function World:GetClientCount() 
    return self:GetPlayerManager():GetPlayerCount();
end

-- 获取世界在线用户数
function World:GetOnlineClientCount() 
    return self:GetPlayerManager():GetOnlinePlayerCount();
end

-- 获取世界的玩家管理器
function World:GetPlayerManager()
    return self.playerManager;
end

-- 获取方块管理器
function World:GetBlockManager() 
    return self.blockManager;
end

-- 移除断开链接的用户
function World:RemoveInvalidPlayer()
    self:GetPlayerManager():RemoveInvalidPlayer();
end

-- 获取调试信息
function World:GetDebugInfo()
    local playerList = self:GetPlayerManager():GetPlayerList();
    local players = {};

    for i = 1, #playerList do 
        local player = playerList[i];
        players[#players + 1] = {
            entityId = player.entityId,
            username = player.username,
            state = player.state,
            lastTick = player.lastTick;
        }
    end

    return {
        players = players,
        worldKey = self:GetWorldKey(),
        worldId = self.worldId,
        parallelWorldName = self.parallelWorldName,
        playerCount = #playerList,
        onlinePlayerCount = self:GetPlayerManager():GetOnlinePlayerCount(),
    }
end
