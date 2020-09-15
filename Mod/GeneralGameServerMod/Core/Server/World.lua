
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
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local PlayerManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.PlayerManager");
local World = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.World"));

World:Property("WorldKey");            -- 世界key
World:Property("WorldId");             -- 世界id
World:Property("WorldType");           -- 世界类型
World:Property("WorldName");           -- 世界名
World:Property("PlayerManager");       -- 玩家管理器

-- 一个世界对象, 应该包含世界的所有数据
function World:ctor()
    -- 实体ID 所有需要同步的实体都需从此分配
    self.nextEntityId = 0;
end

-- 世界初始化
function World:Init(worldId, WorldName, worldType, worldKey)
    self:SetWorldId(worldId);
    self:SetWorldName(WorldName);
    self:SetWorldKey(worldKey);
    self:SetWorldType(worldType or "World");

    -- 玩家管理器
    self:SetPlayerManager(PlayerManager:new():Init(self));
    return self;
end

-- 获取世界实体ID
function World:GetNextEntityId()
    self.nextEntityId = self.nextEntityId + 1;
    if (self.nextEntityId > GGS.MaxEntityId) then
        self.nextEntityId = 0;
    end
    return self.nextEntityId;
end

-- 获取配置
function World:GetConfig()
    return Config[self:GetWorldType()] or Config.World;
end

-- 获取支持的最大玩家数
function World:GetMaxClientCount()
    return self:GetConfig().maxClientCount;
end

-- 获取支持的最小玩家数
function World:GetMinClientCount()
    return self:GetConfig().minClientCount;
end

-- 获取世界用户数
function World:GetClientCount() 
    return self:GetPlayerManager():GetPlayerCount();
end

-- 获取世界在线用户数
function World:GetOnlineClientCount() 
    return self:GetPlayerManager():GetOnlinePlayerCount();
end

-- 是否是平行世界
function World:IsParaWorld()
    return self:GetWorldType() == "ParaWorld";
end

-- 家园
function World:IsParaWorldMini()
    return self:GetWorldType() == "ParaWorldMini";
end

-- 是否支持玩家自己定义自己的可视距离, 默认为false
function World:IsEnablePlayerSelfAreaSize()
    return self:GetConfig().isEnablePlayerSelfAreaSize;
end

-- Tick
function World:Tick()
    self:GetPlayerManager():Tick();
end

-- 获取调试信息
function World:GetDebugInfo()
    local allPlayers = self:GetPlayerManager():GetPlayers();
    local players = {};

    for key, player in pairs(allPlayers) do 
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
        worldId = self:GetWorldId(),
        worldType = self:GetWorldType(),
        worldName = self:GetWorldName(),
        playerCount = self:GetPlayerManager():GetPlayerCount(),
        onlinePlayerCount = self:GetPlayerManager():GetOnlinePlayerCount(),
        config = self:GetConfig(),
    }
end
