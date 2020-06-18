--[[
Title: GeneralGameServerMod
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界模块入口文件
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/main.lua");
local GeneralGameServerMod = commonlib.gettable("Mod.GeneralGameServerMod");
GeneralGameServerMod:init();
------------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameCommand.lua");

local GeneralGameCommand = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameCommand");
local GeneralGameServerMod = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.GeneralGameServerMod"));


function GeneralGameServerMod:ctor()
end

-- virtual function get mod name

function GeneralGameServerMod:GetName()
	return "GeneralGameServerMod"
end

-- virtual function get mod description 

function GeneralGameServerMod:GetDesc()
	return "GeneralGameServerMod is a plugin in paracraft"
end

function GeneralGameServerMod:init()
	LOG.std(nil, "info", "GeneralGameServerMod", "plugin initialized");

	GeneralGameCommand:init();
end

function GeneralGameServerMod:OnLogin()
end
-- called when a new world is loaded. 

function GeneralGameServerMod:OnWorldLoad()
end
-- called when a world is unloaded. 

function GeneralGameServerMod:OnLeaveWorld()
end

function GeneralGameServerMod:OnDestroy()
end

function GeneralGameServerMod:handleKeyEvent(event)
end