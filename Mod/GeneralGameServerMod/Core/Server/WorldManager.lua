--[[
Title: WorldManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorldManager.lua");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager");
WorldManager.GetSingleton();
-------------------------------------------------------
]]

-- 文件加载
NPL.load("Mod/GeneralGameServerMod/Core/Server/World.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
-- 对象获取
local World = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.World");

-- 对象定义
local WorldManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager"));

-- 生成世界KEY
function WorldManager:GenerateWorldKey(worldId, paralelWorldName)
    return string.format("%s_%s", worldId, paralelWorldName or "");
end

-- 世界管理对象
function WorldManager:ctor()
    self.worldMap = {};
end

-- 获取世界KEY
function WorldManager:GetWorldKey(worldId, paralelWorldName, no)        
    local worldKey = self:GenerateWorldKey(worldId, paralelWorldName);
    if (no) then
        worldKey = string.format("%s_%s", worldKey, no);
    end

    local world = self.worldMap[worldKey];
    if (world and world:GetClientCount() >= Config.World.maxClientCount) then
        return self:GetWorldKey(worldId, paralelWorldName, (no or 0) + 1);
    end

    return worldKey;
end

-- 获取指定世界
function WorldManager:GetWorld(worldId, paralelWorldName, isNewNoExist)
    local worldKey = self:GetWorldKey(worldId, paralelWorldName);
    if (not self.worldMap[worldKey] and isNewNoExist) then
        self.worldMap[worldKey] = World:new():Init(worldId, paralelWorldName, worldKey); 
    end
    return self.worldMap[worldKey];
end

-- 世界是否存在
function WorldManager:IsExistWorld(worldKey)
    return self.worldMap[worldKey] and true or false;
end

-- 获取世界数
function WorldManager:GetWorldCount()
    local count = 0;
    for key, val in pairs(self.worldMap) do 
        count = count + 1;
    end
    return count;
end

-- 获取总用户数
function WorldManager:GetClientCount() 
    local count = 0;
    for worldKey, world in pairs(self.worldMap) do 
        count = count + world:GetClientCount();
    end
    return count;
end

-- 获取世界和用户数
function WorldManager:GetWorldClientCount()
    local totalWorldCount, totalClientCount, totalWorldClientCounts = 0, 0, {};
    for worldKey, world in pairs(self.worldMap) do 
        local count = world:GetClientCount();
        totalWorldClientCounts[worldKey] = count;
        totalWorldCount = totalWorldCount + 1;
        totalClientCount = totalClientCount + count;
    end
    return totalWorldCount, totalClientCount, totalWorldClientCounts;
end

-- 尝试删除世界
function WorldManager:TryRemoveWorld(world)
    if (not world or not world:isa(World) or world:GetClientCount() > 0) then 
        return false; 
    end

    self.worldMap[world:GetWorldKey()] = nil;
    
    return true;
end

-- timer function
function WorldManager:Tick()
    for worldKey, world in pairs(self.worldMap) do 
        world:RemoveInvalidPlayer();
    end  
end

-- 初始化成单列模式
WorldManager:InitSingleton();