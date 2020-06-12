--[[
Title: WorldManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/WorldManager.lua");
local WorldManager = commonlib.gettable("GeneralGameServerMod.Server.WorldManager");
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
    -- 世界环境信息
    self.env = {
        texturePack = nil,
	    weather = nil,
	    customBlocks = nil,
    }
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

-- 获取默认世界
local g_default_world;
function WorldManager:GetDefaultWorld() 
    if (g_default_world) then
        return g_default_world;
    else
        g_default_world = World:new();
        return g_default_world;
    end
end


