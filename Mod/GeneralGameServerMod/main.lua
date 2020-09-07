--[[
Title: GeneralGameServerMod
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界模块入口文件
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/main.lua");
local GeneralGameServerMod = commonlib.gettable("Mod.GeneralGameServerMod");
-- client
local ModManager = commonlib.gettable("Mod.ModManager");
ModManager:AddMod(nil, GeneralGameServerMod);
-- use
GameLogic.RunCommand("/connectGGS -dev -u=xiaoyao 0");   

-- server
GeneralGameServerMod:init();
------------------------------------------------------------
]]

--  全局变量初始化
local GeneralGameClients = {};

_G.IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";
local Debug = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Debug.lua");

_G.GGS = {
	-- 环境识别
	IsDevEnv = IsDevEnv,

	-- DEBUG 调试类以及调试函数
	Debug = Debug,
	DEBUG = Debug.GetModuleDebug("DEBUG"),
	INFO = Debug.GetModuleDebug("INFO"),
	WARN = Debug.GetModuleDebug("WARN"),
	ERROR= Debug.GetModuleDebug("ERROR"),
	FATAL= Debug.GetModuleDebug("FATAL"),

	-- 注册主客户端类
	RegisterClientClass = function(appName, clientClass)
		GeneralGameClients[appName] = clientClass;
	end,
	GetClientClass = function(appName)
		return GeneralGameClients[appName];
	end,
};


NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Common.lua");

local Common = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Common");
local GeneralGameServerMod = commonlib.inherit(commonlib.gettable("Mod.ModBase"), commonlib.gettable("Mod.GeneralGameServerMod"));
local servermode = ParaEngine.GetAppCommandLineByParam("servermode","false") == "true";
local inited = false;

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
	if (inited) then return end;
	inited = true;
	
	Common:Init(servermode);
	-- 启动插件
	if (servermode) then
		-- server
		NPL.load("Mod/GeneralGameServerMod/Core/Server/GeneralGameServer.lua");
		local GeneralGameServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.GeneralGameServer");
		GeneralGameServer:Start();
	else
		-- client
		NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameCommand.lua");
		local GeneralGameCommand = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameCommand");
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

function GeneralGameServerMod:handleMouseEvent(event)
	local GeneralGameCommand = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameCommand");
	local generalGameClient = GeneralGameCommand:GetGeneralGameClient();
	if (generalGameClient and generalGameClient.handleMouseEvent) then
		generalGameClient:handleMouseEvent(event);
	end
end

-- 注册客户端类
function GeneralGameServerMod:RegisterClientClass(appName, clientClass)
	GGS.RegisterClientClass(appName, clientClass);
end

-- 获取客户端类
function GeneralGameServerMod:GetClientClass(appName)
	return GGS.GetClientClass(appName);
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