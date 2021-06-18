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
NPL.load("(gl)script/ide/timer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/World.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local World = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.World");

-- 对象定义
local WorldManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager"));

-- 世界管理对象
function WorldManager:ctor()
    self.worldMap = {};

    self.worldKeyPrefix = string.format("%s_%s_%s", Config.WorkerServer.outerIp, Config.WorkerServer.outerPort, __rts__:GetName());
end

-- 初始化
function WorldManager:Init()
    -- 定时器
    local tickDuratin = 1000 * 60 * 2; 
	commonlib.Timer:new({callbackFunc = function(timer)
		self:Tick();
	end}):Change(tickDuratin, tickDuratin); -- 两分钟触发一次
end

-- 生成世界KEY
function WorldManager:GenerateWorldKey(worldId, worldName, no)
    return string.format("%s_%s_%s_%s", self.worldKeyPrefix, worldId, worldName or "", no or "");
end

-- 世界Key是否可用
function WorldManager:IsAvailableWorldKey(worldKey)
    local world = self.worldMap[worldKey];
    if (world and world:GetOnlineClientCount() >= world:GetMaxClientCount()) then
        return false;
    end
    return true;
end

-- 获取世界KEY
function WorldManager:GetWorldKey(worldId, worldName, no, IsAvailableWorldKey)        
    local worldKey = self:GenerateWorldKey(worldId, worldName, no);

    -- 优先使用自定义识别函数
    local isAvailable = self:IsAvailableWorldKey(worldKey); 
    if (type(IsAvailableWorldKey) == "function") then isAvailable = IsAvailableWorldKey(worldKey) end
    if (not isAvailable) then return self:GetWorldKey(worldId, worldName, (no or 0) + 1, IsAvailableWorldKey) end

    return worldKey;
end

-- 获取指定世界
function WorldManager:GetWorld(worldId, worldName, worldType, isNewNoExist, worldKey)
    if (not worldKey or not string.find(worldKey, self:GenerateWorldKey(worldId, worldName), 1, true)) then
        worldKey = self:GetWorldKey(worldId, worldName);
    end
    if (not self.worldMap[worldKey] and isNewNoExist) then
        self.worldMap[worldKey] = World:new():Init(worldId, worldName, worldType, worldKey);
    end
    return self.worldMap[worldKey];
end

-- 获取世界
function WorldManager:GetWorldByKey(worldKey)
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

-- 获取总用户数
function WorldManager:GetOnlineClientCount() 
    local count = 0;
    for worldKey, world in pairs(self.worldMap) do 
        count = count + world:GetOnlineClientCount();
    end
    return count;
end

-- 获取世界和用户数
function WorldManager:GetWorldClientCount()
    local totalWorldCount, totalClientCount, totalWorldClientCounts = 0, 0, {};
    for worldKey, world in pairs(self.worldMap) do 
        local count = world:GetOnlineClientCount();
        totalWorldClientCounts[worldKey] = count;
        totalWorldCount = totalWorldCount + 1;
        totalClientCount = totalClientCount + count;
    end
    return totalWorldCount, totalClientCount, totalWorldClientCounts;
end


-- 获取世界信息
function WorldManager:GetWorldInfo(worldKey)
    local world = self:GetWorldByKey(worldKey);
    return world and world:GetWorldInfo();
end

-- 获取所有世界信息
function WorldManager:GetAllWorldInfo()
    local worlds = {};
    for worldKey, world in pairs(self.worldMap) do 
        worlds[worldKey] = world:GetWorldInfo();
    end
    return worlds;
end


-- timer function
local deleted = {};  -- 删除无用户的世界
function WorldManager:Tick()
    deleted = {};
    for worldKey, world in pairs(self.worldMap) do 
        if (world:IsCanDelete() == 0) then
            table.insert(deleted, worldKey);
        else
            world:Tick();
        end
    end  

    for i = 1, #deleted do
        self.worldMap[deleted[i]] = nil;
    end
end

-- 初始化成单列模式
WorldManager:InitSingleton():Init();