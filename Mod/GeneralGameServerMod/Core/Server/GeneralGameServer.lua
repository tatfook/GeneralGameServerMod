
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

local ThreadHelper = NPL.load("./ThreadHelper.lua");
local WorkerServer = NPL.load("./WorkerServer.lua");

local Config = NPL.load("./Config.lua");
local GeneralGameServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local __server_info__ = {};
local __is_server_info_change__ = false;

ThreadHelper:OnChange(function()
	__is_server_info_change__ = true;
end);

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
	if (Config.Server.isControlServer) then NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Server/ControlServer.lua", 403) end
	NPL.AddPublicFile("Mod/GeneralGameServerMod/Server/Net/Net.lua", 406);

	-- NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua", 404);
	for i, publicFile in ipairs(Config.PublicFiles) do NPL.AddPublicFile(publicFile, 450 + i) end
end

-- 启动服务
function GeneralGameServer:Start() 
	if (self.isStart) then return end;

    -- 设置系统属性
    self:LoadNetworkSettings();

	-- 启动服务
	local listenIp = Config.Server.listenIp;
	local listenPort = Config.Server.listenPort;

	if (Config.Server.isControlServer) then
		listenIp = listenIp or Config.ControlServer.innerIp or Config.ControlServer.outerIp;
		listenPort = listenPort or Config.ControlServer.innerPort or Config.ControlServer.outerPort;
		__server_info__.innerIp, __server_info__.innerPort = Config.ControlServer.innerIp, Config.ControlServer.innerPort;
		__server_info__.outerIp, __server_info__.outerPort = Config.ControlServer.outerIp, Config.ControlServer.outerPort;
	else
		listenIp = listenIp or Config.WorkerServer.innerIp or Config.WorkerServer.outerIp;
		listenPort = listenPort or Config.WorkerServer.innerPort or Config.WorkerServer.outerPort;
		__server_info__.innerIp, __server_info__.innerPort = Config.WorkerServer.innerIp, Config.ControlServer.innerPort;
		__server_info__.outerIp, __server_info__.outerPort = Config.WorkerServer.outerIp, Config.ControlServer.outerPort;
	end
	__server_info__.__all_thread_info__ = ThreadHelper:GetAllThreadInfo();

    NPL.StartNetServer(listenIp, tostring(listenPort));

    GGS.INFO.Format(string.format("服务器启动: listenIp: %s, listenPort: %s", listenIp, listenPort));

	local threadCount = Config.Server.threadCount;
	for i = 1, threadCount do 
		local threadName = GGS.GetWorkerThreadName(i);
		ThreadHelper:StartWorkerThread(threadName);
		-- NPL.CreateRuntimeState(threadName, 0):Start(); 
	end

	-- 主循环
	commonlib.Timer:new({callbackFunc = function() GeneralGameServer:Tick() end}):Change(1000, 1000 * 10);
	
	self.isStart = true;
end

function GeneralGameServer:PushServerInfo()
	if (not __is_server_info_change__) then return end 
	__is_server_info_change__ = false;

	System.os.GetUrl({
		method = "POST",
		url = IsDevEnv and "http://api-rls.kp-para.cn/ggs-manager/node/state" or "https://api.keepwork.com/ggs-manager/node/state", 
		json = true, 
		form = __server_info__,
	}, function(err, msg, data)
	end);
end

function GeneralGameServer:Tick()
	self:PushServerInfo();
end

GeneralGameServer:InitSingleton();
