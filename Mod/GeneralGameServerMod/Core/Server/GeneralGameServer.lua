
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
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/ControlServer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Common.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorldManager.lua");
local Common = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Common");
local ControlServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.ControlServer");
local WorkerServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorkerServer");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager");
local GeneralGameServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.GeneralGameServer");

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
	att:SetField("CompressionThreshold", 1024*16);
	
	att:SetField("UDPIdleTimeoutPeriod", 1200000);
	att:SetField("UDPCompressionLevel", -1);
	att:SetField("UDPCompressionThreshold", 1024*16);
	-- npl message queue size is set to really large
	__rts__:SetMsgQueueSize(5000);
end

-- 启动服务
function GeneralGameServer:Start() 
	if (self.isStart) then return end;
	
	Common:Init(true);
	
    -- 设置系统属性
    self:LoadNetworkSettings();

	-- 启动服务
	local listenIp = Config.Server.listenIp;
	local listenPort = Config.Server.listenPort;
	if (Config.Server.isControlServer) then
		listenIp = listenIp or Config.Server.ControlServer.innerIp or Config.Server.ControlServer.outerIp;
		listenPort = listenPort or Config.Server.ControlServer.listenPort or Config.Server.ControlServer.listenPort;
	else
		listenIp = listenIp or Config.Server.WorkerServer.innerIp or Config.Server.WorkerServer.outerIp;
		listenPort = listenPort or Config.Server.WorkerServer.listenPort or Config.Server.WorkerServer.listenPort;
	end

    NPL.StartNetServer(listenIp, tostring(listenPort));

    GGS.INFO.Format(string.format("服务器启动: listenIp: %s, listenPort: %s", listenIp, listenPort));

	-- 控制服务
	if (Config.Server.isControlServer) then
		-- 暴露接口文件
		NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Server/ControlServer.lua", 402);
	end

	-- 工作服务
	if (Config.Server.isWorkerServer) then
		-- 初始化成单列模式
		WorkerServer:InitSingleton();
		WorkerServer:Init();
	end

	-- 定时器
	local tickDuratin = 1000 * 60 * 2; 
	self.timer = commonlib.Timer:new({callbackFunc = function(timer)
		self:Tick();
	end});
	
	self.timer:Change(tickDuratin, tickDuratin); -- 两分钟触发一次

	self.isStart = true;
end

function GeneralGameServer:Tick() 
	WorldManager:Tick();
end

