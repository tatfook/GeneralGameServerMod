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
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");
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
	
	GGS.INFO.Format("===============================================GGS[%s] init===========================================", GGS.IsServer and "server" or "client");

	-- 启动插件
	if (GGS.IsServer) then
		-- server
		local GeneralGameServer = NPL.load("Mod/GeneralGameServerMod/Core/Server/GeneralGameServer.lua");
		GeneralGameServer:Start();
	else
		-- client
		NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameCommand.lua");
		local GeneralGameCommand = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameCommand");
		GeneralGameCommand:init();
		
		-- command
		NPL.load("Mod/GeneralGameServerMod/Command/Command.lua");
		-- GI
		NPL.load("Mod/GeneralGameServerMod/GI/GI.lua");
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
	-- local GeneralGameCommand = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameCommand");
	-- local generalGameClient = GeneralGameCommand:GetGeneralGameClient();
	-- if (generalGameClient and generalGameClient.handleMouseEvent) then
	-- 	generalGameClient:handleMouseEvent(event);
	-- end
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
if (GGS.IsServer) then
	NPL.this(activate);
end