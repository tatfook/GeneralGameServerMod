
--[[
Title: WorldManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/GeneralGameServer.lua");
local GeneralGameServer = commonlib.gettable("GeneralGameServerMod.Core.Server.GeneralGameServer");
GeneralGameServer.Start();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorldManager.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local WorkerServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorkerServer");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager");
local GeneralGameServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.GeneralGameServer");

-- local ThreadHelper = NPL.load("./ThreadHelper.lua");

function GeneralGameServer:ctor() 
    self.isStart = false;
end

function GeneralGameServer:LoadNetworkSettings()
	local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", true);
	att:SetField("IdleTimeout", false);
	att:SetField("IdleTimeoutPeriod", 1200000);
	NPL.SetUseCompression(true, true);
	att:SetField("CompressionLevel", -1);
	-- att:SetField("CompressionThreshold", 1024*16);
	att:SetField("CompressionThreshold", 1024*4);
	
	att:SetField("UDPIdleTimeoutPeriod", 1200000);
	att:SetField("UDPCompressionLevel", -1);
	att:SetField("UDPCompressionThreshold", 1024*16);
	-- npl message queue size is set to really large
	__rts__:SetMsgQueueSize(500);

	-- 暴露接口文件
	NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Common/Connection.lua", 401);
	NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Server/NetServerHandler.lua", 402);
	NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Server/ControlServer.lua", 403);  
	-- NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Server/ThreadHelper.lua", 404);
	for i, publicFile in ipairs(Config.PublicFiles) do NPL.AddPublicFile(publicFile, 500 + i) end
end

-- 启动服务
function GeneralGameServer:Start() 
	if (self.isStart) then return end;
	-- 初始化
	-- ThreadHelper:Init();

    -- 设置系统属性
    self:LoadNetworkSettings();

	-- 启动服务
	local listenIp = Config.Server.listenIp;
	local listenPort = Config.Server.listenPort;
	if (Config.Server.isControlServer) then
		listenIp = listenIp or Config.ControlServer.innerIp or Config.ControlServer.outerIp;
		listenPort = listenPort or Config.ControlServer.innerPort or Config.ControlServer.outerPort;
	else
		listenIp = listenIp or Config.WorkerServer.innerIp or Config.WorkerServer.outerIp;
		listenPort = listenPort or Config.WorkerServer.innerPort or Config.WorkerServer.outerPort;
	end

    NPL.StartNetServer(listenIp, tostring(listenPort));

    GGS.INFO.Format(string.format("服务器启动: listenIp: %s, listenPort: %s", listenIp, listenPort));
	
	local threadCount = Config.Server.threadCount;
	for i = 1, threadCount do 
		local threadName = GGS.GetWorkerThreadName(i);
		NPL.CreateRuntimeState(threadName, 0):Start(); 
		-- NPL.activate(string.format("(%s)Mod/GeneralGameServerMod/Core/Server/ThreadHelper.lua", threadName), {action = "Init"});
	end

	self.isStart = true;
end

function GeneralGameServer:Tick() 
	WorldManager:Tick();
end

