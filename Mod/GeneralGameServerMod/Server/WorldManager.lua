--[[
Title: WorldManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/WorldManager.lua");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Server.WorldManager");
WorldManager.GetSingleton();
-------------------------------------------------------
]]

-- 文件加载
NPL.load("Mod/GeneralGameServerMod/Server/World.lua");

-- 对象获取
local World = commonlib.gettable("Mod.GeneralGameServerMod.Server.World");

-- 对象定义
local WorldManager = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.WorldManager"));

-- 世界管理对象
function WorldManager:ctor()
    self.worldMap = {};
end

-- 单列模式
local g_instance;
function WorldManager.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = WorldManager:new();
		return g_instance;
	end
end

-- 获取指定世界
function WorldManager:GetWorldById(worldId, isNewNoExist)
    if (not self.worldMap[worldId] and isNewNoExist) then
        self.worldMap[worldId] = World:new(); 
    end
    return self.worldMap[worldId];
end

-- 世界是否存在
function WorldManager:IsExistWorld(worldId)
    return self.worldMap[worldId] and true or false;
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
    for worldId, world in pairs(self.worldMap) do 
        count = count + world:GetClientCount();
    end
    return count;
end

-- 获取世界和用户数
function WorldManager:GetWorldClientCount()
    local totalWorldCount, totalClientCount, totalWorldClientCounts = 0, 0, {};
    for worldId, world in pairs(self.worldMap) do 
        local count = world:GetClientCount();
        totalWorldClientCounts[worldId] = count;
        totalWorldCount = totalWorldCount + 1;
        totalClientCount = totalClientCount + count;
    end
    return totalWorldCount, totalClientCount, totalWorldClientCounts;
end

-- 尝试删除世界
function WorldManager:TryRemoveWorld(worldId)
    local world = self:GetWorldById(worldId);
    if (not world or world:GetClientCount() > 0) then
        return false;
    end
    self.worldMap[worldId] = nil;
    return true;
end

-- timer function
function WorldManager:Tick()
    for worldId, world in pairs(self.worldMap) do 
        world:RemoveInvalidPlayer();
    end  
end
