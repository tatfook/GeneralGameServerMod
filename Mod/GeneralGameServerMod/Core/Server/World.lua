
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
print("world")
NPL.load("(gl)script/sqlite/sqlite3.lua");
print("world")
NPL.load("Mod/GeneralGameServerMod/Core/Server/PlayerManager.lua");
print("world")
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
print("world")
NPL.load("Mod/GeneralGameServerMod/Core/Server/Track.lua");
print("world")
-- NPL.load("Mod/GeneralGameServerMod/Core/Server/BlockManager.lua");
-- local BlockManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.BlockManager");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local PlayerManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.PlayerManager");
local Track = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Track");
local World = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.World"));

World:Property("WorldKey");            -- 世界key
World:Property("WorldId");             -- 世界id
World:Property("WorldType");           -- 世界类型
World:Property("WorldName");           -- 世界名
World:Property("ThreadName");          -- 线程名
World:Property("PlayerManager");       -- 玩家管理器
World:Property("BlockManager");        -- 玩家管理器
World:Property("Track");               -- 世界轨迹
World:Property("DB");                  -- 数据库
World:Property("EnableAutoDelete", true, "IsEnableAutoDelete");          -- 是否启用自动删除 可用于常驻世界

-- 一个世界对象, 应该包含世界的所有数据
function World:ctor()
    -- 实体ID 所有需要同步的实体都需从此分配
    self.nextEntityId = 0;
end

-- 世界初始化
function World:Init(worldId, WorldName, worldType, worldKey)
    self:SetWorldId(worldId);
    self:SetWorldName(WorldName or "");
    self:SetWorldKey(worldKey);
    self:SetWorldType(worldType or "World");
    
    self:SetThreadName(__rts__:GetName());

    -- 轨迹
    self:SetTrack(Track:new():Init(self));

    -- 玩家管理器
    self:SetPlayerManager(PlayerManager:new():Init(self));

    -- 可编辑世界创建DB
    -- if (self:IsEditable()) then 
    --     self:NewDB();
    --     self:SetBlockManager(BlockManager:new():Init(self));
    -- end

    return self;
end

-- 创建DB
function World:NewDB()
    local pathPrefix = self:GetConfig().storePath or "ggs/db/";
    local filename = pathPrefix .. self:GetWorldKey() .. ".db";
    self:SetDB(sqlite3.open(filename));
end

-- 设置块
function World:SetBlocks(blocks)
    -- if (not self:IsEditable()) then return end
    -- self:GetBlockManager():SetBlocks(blocks);
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

-- 是否可编辑
function World:IsEditable()
    if (IsDevEnv) then return true end
    return self:GetConfig().IsEditable;
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

-- 世界是否可以删除
function World:IsCanDelete()
    if (not self:IsEnableAutoDelete()) then return false end
    return self:GetClientCount() == 0;
end

-- 获取世界信息
function World:GetWorldInfo(worldKey)
    return {
        clientCount = self:GetOnlineClientCount(),
        maxClientCount = self:GetMaxClientCount(),
        threadName = self:GetThreadName(),
        worldKey = self:GetWorldKey(),
        worldId = self:GetWorldId(),
        worldName = self:GetWorldName(),
    }
end

-- 获取调试信息
function World:GetDebugWorldInfo()
    return {
        worldKey = self:GetWorldKey(),
        worldId = self:GetWorldId(),
        worldType = self:GetWorldType(),
        worldName = self:GetWorldName(),
        playerCount = self:GetPlayerManager():GetPlayerCount(),
        onlinePlayerCount = self:GetPlayerManager():GetOnlinePlayerCount(),
        config = self:GetConfig(),
    }
end

function World:GetDebugPlayerInfo()
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

    return players;
end

