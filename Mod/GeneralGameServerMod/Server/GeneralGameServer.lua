
--[[
Title: WorldManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/GeneralGameServer.lua");
local GeneralGameServer = commonlib.gettable("GeneralGameServerMod.Server.GeneralGameServer");
GeneralGameServer.Start();
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Common.lua");
NPL.load("Mod/GeneralGameServerMod/Server/WorkerServer.lua");
NPL.load("Mod/GeneralGameServerMod/Server/ControlServer.lua");
local ControlServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.ControlServer");
local WorkerServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.WorkerServer");
local Common = commonlib.gettable("Mod.GeneralGameServerMod.Common.Common");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local GeneralGameServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.GeneralGameServer");

function GeneralGameServer:ctor() 
    self.isStart = false;
end

function GeneralGameServer:LoadNetworkSettings()
	local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", false);
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
	
	-- 通用初始化
	Common:Init(true);

    -- 设置系统属性
    self:LoadNetworkSettings();

    -- 启动服务
    NPL.StartNetServer(Config.Server.listenIp, tostring(Config.Server.listenPort));

    Log:Info("服务器启动");

	-- 控制服务
	if (Config.Server.isControlServer) then
		-- ControlServer.GetSingleton():Init();
		-- 暴露接口文件
		NPL.AddPublicFile("Mod/GeneralGameServerMod/Server/ControlServer.lua", 402);
	end
	-- 工作服务
	if (Config.Server.isWorkerServer) then
		WorkerServer.GetSingleton():Init();
	end
    self.isStart = true;
end
