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
-- client
GameLogic.RunCommand("/connectGGS -test");    
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Common.lua");
local Common = commonlib.gettable("Mod.GeneralGameServerMod.Common.Common");
local GeneralGameServerMod = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.GeneralGameServerMod"));

local servermode = ParaEngine.GetAppCommandLineByParam("servermode","false") == "true";

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
	LOG.info("GeneralGameServerMod plugin initialized");

	Common:Init(servermode);
	-- 启动插件
	if (servermode) then
		-- server
		NPL.load("Mod/GeneralGameServerMod/Server/GeneralGameServer.lua");
		local GeneralGameServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.GeneralGameServer");
		GeneralGameServer:Start();
	else
		-- client
		NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameCommand.lua");
		local GeneralGameCommand = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameCommand");
		GeneralGameCommand:init();
	end
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


-- 服务端激活函数
local isActivated = false;
local function activate() 
	if (isActivated) then return end;
	isActivated = true;
	-- 只初始化一次
	GeneralGameServerMod:init();
end

if (servermode) then
	NPL.this(activate);
end