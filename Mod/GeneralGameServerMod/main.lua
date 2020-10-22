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
GameLogic.RunCommand("/ggs connect -dev -u=xiaoyao 0");   

-- server
GeneralGameServerMod:init();
------------------------------------------------------------
]]

--  全局变量初始化
local GeneralGameClients = {};
local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";
local servermode = ParaEngine.GetAppCommandLineByParam("servermode","false") == "true";

_G.IsDevEnv = true and IsDevEnv;
-- _G.IsDevEnv = false;
local Debug = NPL.load("Mod/GeneralGameServerMod/Core/Common/Debug.lua");

_G.GGS = {
	-- 环境识别
	IsDevEnv = IsDevEnv,
	IsServer = servermode,
	
	-- DEBUG 调试类以及调试函数
	Debug = Debug,
	DEBUG = Debug.GetModuleDebug("DEBUG"),
	INFO = Debug.GetModuleDebug("INFO"),
	WARN = Debug.GetModuleDebug("WARN"),
	ERROR= Debug.GetModuleDebug("ERROR"),
	FATAL= Debug.GetModuleDebug("FATAL"),
	-- 业务逻辑DEBUG
	PlayerLoginLogoutDebug = Debug.GetModuleDebug("PlayerLoginLogoutDebug"),   -- 玩家登录登出日志
	NetDebug = Debug.GetModuleDebug("NetDebug"),                               -- 发送接收数据包日志
	BlockSyncDebug = Debug.GetModuleDebug("BlockSyncDebug"),                   -- 方块同步日志
	AreaSyncDebug = Debug.GetModuleDebug("AreaSyncDebug"),                     -- 区域同步日志
	-- 配置
	MaxEntityId =  1000000,                                                    -- 服务器统一分配的最大实体ID数
	-- 注册主客户端类
	RegisterClientClass = function(appName, clientClass)
		GeneralGameClients[appName] = clientClass;
	end,
	GetClientClass = function(appName)
		return GeneralGameClients[appName];
	end,
};

NPL.load("(gl)script/ide/System/System.lua");
local GeneralGameServerMod = commonlib.inherit(commonlib.gettable("Mod.ModBase"), commonlib.gettable("Mod.GeneralGameServerMod"));
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
	GGS.INFO.Format("===============================================GGS[%s] init===========================================", servermode and "server" or "client");

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