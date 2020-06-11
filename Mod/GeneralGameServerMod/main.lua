
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
	if(event.keyname == "DIK_SPACE") then
		LOG.std(nil, "info", "DemoEntity", "OnWorldLoad");
		return true;
	end
end