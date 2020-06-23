--[[
Title: Cluster
Author(s): wxa
Date: 2020/6/22
Desc: 集群
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/WorkerServer.lua");
local WorkerServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.WorkerServer");
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Server/WorldManager.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Server.WorldManager");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local WorkerServer = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.WorkerServer"));

-- 单列模式
local g_instance;
function WorkerServer.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = WorkerServer:new();
		return g_instance;
	end
end

-- 构造函数
function WorkerServer:ctor()
    local workerServerCfg = Config.WorkerServer;
    local controlServerCfg = Config.ControlServer;

    self.innerIp = workerServerCfg.innerIp;                 -- 内网IP 
    self.innerPort = workerServerCfg.innerPort;             -- 内网Port
    self.outerIp = workerServerCfg.outerIp;                 -- 外网IP
    self.outerPort = workerServerCfg.outerPort;             -- 外网Port 

    self.controlServerIp = controlServerCfg.innerIp;
    self.controlServerPort = controlServerCfg.innerPort;
end

-- 初始化函数
function WorkerServer:Init(server)
    if (self.inited) then return; end
    self.inited = true;

    -- 定时上报服务器信息
    self.SendServerInfoTimer = commonlib.Timer:new({callbackFunc = function(timer)
        self:SendServerInfo();
    end});

    -- 连接控制器
    self.connection = Connection:new():InitByIpPort(self.controlServerIp, self.controlServerPort, self);
    self.connection:SetDefaultNeuronFile("Mod/GeneralGameServerMod/Server/ControlServer.lua");
    self.connection:Connect(5, function(success)
        if (success) then
            Log:Info("成功连接控制服务");
            -- 推送服务器信息到控制器
            self.SendServerInfoTimer:Change(0, 1000 * 60 * 3); -- 每3分钟上报一次 
        else
            Log:Info("无法连接控制服务");
        end
    end)

    
end

-- 发送服务器信息
function WorkerServer:SendServerInfo()
    local worldManager = WorldManager.GetSingleton();
    local totalWorldCount, totalClientCount, totalWorldClientCounts = worldManager:GetWorldClientCount();
    self.connection:AddPacketToSendQueue(Packets.PacketServerInfo:new():Init({
        totalWorldCount = totalWorldCount,
        totalClientCount = totalClientCount,
        totalWorldClientCounts = totalWorldClientCounts,
        innerIp = self.innerIp,                 -- 内网IP 
        innerPort = self.innerPort,             -- 内网Port
        outerIp = self.outerIp,                 -- 外网IP
        outerPort = self.outerPort,             -- 外网Port 
    }));
end

-- 连接丢失
function WorkerServer:handleErrorMessage(text, connection)
    Log:Info("断开与控制服务器的连接");
end

