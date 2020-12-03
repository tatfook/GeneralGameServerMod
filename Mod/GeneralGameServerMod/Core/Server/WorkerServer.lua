--[[
Title: Cluster
Author(s): wxa
Date: 2020/6/22
Desc: 集群
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua");
local WorkerServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorkerServer");
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorldManager.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
local WorkerServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorkerServer"));

WorkerServer:Property("ServerList", {});                    -- 服务器列表
WorkerServer:Property("ServerInfo", {});                    -- 服务器信息
WorkerServer:Property("StatisticsInfo", {});                -- 统计信息

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
function WorkerServer:Init()
    if (__rts__:GetName() ~= "main") then return end 

    if (self.inited) then return end
    self.inited = true;

    -- 定时上报服务器信息
    self.SendServerInfoTimer = commonlib.Timer:new({callbackFunc = function(timer)
        self:SendServerInfo();
    end});

    -- 连接控制器
    self.connection = Connection:new():Init({ip = self.controlServerIp, port = self.controlServerPort, netHandler = self});
    self.connection:SetDefaultNeuronFile("Mod/GeneralGameServerMod/Core/Server/ControlServer.lua");
    local function ConnectControlServer()
        self.connection:Connect(5, function(success)
            if (success) then
                GGS.INFO.Format("成功连接控制服务");
                -- 推送服务器信息到控制器
                self.SendServerInfoTimer:Change(0, 1000 * 60 * 2);                                     -- 每2分钟上报一次 
            else
                GGS.INFO.Format("无法连接控制服务, 2 分钟后重连...");
                commonlib.Timer:new({callbackFunc = ConnectControlServer}):Change(2 * 60 * 1000);      -- 两分钟后重连
            end
        end)
    end

    ConnectControlServer();
end

-- 发送服务器信息
function WorkerServer:SendServerInfo()
    if (__rts__:GetName() ~= "main") then return self:SendMsgToMainThread({action = "SendServerInfo"}) end

    self.connection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({
        action = "ServerInfo",
        data = {
            isWorkerServer = true,                                       -- 是否是工作线程
            innerIp = self.innerIp,                                      -- 内网IP 
            innerPort = self.innerPort,                                  -- 内网Port
            outerIp = self.outerIp,                                      -- 外网IP
            outerPort = self.outerPort,                                  -- 外网Port 
            maxClientCount = Config.Server.maxClientCount,               -- 服务器最大客户端数
            threadCount = Config.Server.threadCount,                     -- 服务器的线程数
            threadMaxClientCount = Config.Server.threadMaxClientCount;   -- 单个线程最大客户端数
            worldServers = Config.WorldServers,                          -- 世界服
        }
    }));
end

-- 发送世界信息
function WorkerServer:SendWorldInfo(world)
    if (__rts__:GetName() ~= "main") then return self:SendMsgToMainThread({action = "SendWorldInfo", data = world}) end
    
    self.connection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "WorldInfo", data  = world}));
end

-- 更新统计信息
function WorkerServer:UpdateStatisticsInfo()
    if (__rts__:GetName() ~= "main") then return self:SendMsgToMainThread({action = "UpdateStatisticsInfo"}) end

    self.connection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "StatisticsInfo"}));
end

-- 处理通用数据包
function WorkerServer:handleGeneral(packetGeneral)
    local action = packetGeneral.action;
    local data = packetGeneral.data;
    if (action == "ServerList") then 
        self:SetServerList(data);
	self:SendMsgToWorkerThread({action="SetServerList", data = data});
    elseif (action == "ServerInfo") then
        self:SetServerInfo(data);
        self:SendMsgToWorkerThread({action="SetServerInfo", data = data});
    elseif (action == "StatisticsInfo") then
        self:SetStatisticsInfo(data);
        self:SendMsgToWorkerThread({action="SetStatisticsInfo", data = data});
    end
end

-- 连接丢失
function WorkerServer:handleErrorMessage(text, connection)
    GGS.INFO.Format("断开与控制服务器的连接");
end

-- 工作线程转主线程发送信息
function WorkerServer:SendMsgToMainThread(msg)
	NPL.activate("(main)Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua", msg);
end

-- 信息同步至工作线程
function WorkerServer:SendMsgToWorkerThread(msg)
    local serverinfo = self:GetServerInfo();
    if (type(serverinfo) ~= "table" or type(serverinfo.threads) ~= "table" or __rts__:GetName() ~= "main") then return end
    for threadName, _ in pairs(serverinfo.threads) do 
        if (threadName ~= "main") then
            NPL.activate(string.format("(%s)Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua", threadName), msg);
        end
    end
end

-- 单列化
WorkerServer:InitSingleton():Init();

-- 激活函数
local function activate()
	local action = msg and msg.action;
    local data = msg and msg.data;

    if (action == "SendServerInfo") then 
        return WorkerServer:SendServerInfo();
    elseif (action == "UpdateStatisticsInfo") then
        return WorkerServer:UpdateStatisticsInfo();
    elseif (action == "SendWorldInfo") then
        return WorkerServer:SendWorldInfo(data);
    elseif (action == "SetServerInfo") then
        return WorkerServer:SetServerInfo(data);
    elseif (action == "SetServerList") then
        return WorkerServer:SetServerList(data)
    elseif (action == "SetStatisticsInfo") then
        return WorkerServer:SetStatisticsInfo(data);
    end
end

NPL.this(activate);
