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

local Config = NPL.load("./Config.lua");
local Packets = NPL.load("../Common/Packets.lua");
local Connection = NPL.load("../Common/Connection.lua");

local WorkerServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

WorkerServer:Property("ServerList", {});                    -- 服务器列表
WorkerServer:Property("ServerInfo", {});                    -- 服务器信息
WorkerServer:Property("StatisticsInfo", {});                -- 统计信息
WorkerServer:Property("MainThread", false, "IsMainThread"); -- 是否是主线程

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

    self.isControlServer = Config.Server.isControlServer;
    self.isWorkerServer = Config.Server.isWorkerServer;

    self:SetMainThread(__rts__:GetName() == "main");
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
    self.connection = Connection:new():Init({ip = self.controlServerIp, port = self.controlServerPort, netHandler = self, remoteNeuronFile = "Mod/GeneralGameServerMod/Core/Server/ControlServer.lua"});
    local function ConnectControlServer()
        print("==============ConnectControlServer================")
        self.connection:Connect(5, function(success)
            if (success) then
                GGS.INFO.Format("成功连接控制服务, controlServerIp = %s controlServerPort = %s", self.controlServerIp, self.controlServerPort);
                -- 推送服务器信息到控制器
                self.SendServerInfoTimer:Change(0, IsDevEnv and 1000 * 10 or 1000 * 60 * 2);           -- 每2分钟上报一次 
            else
                GGS.INFO.Format("无法连接控制服务, 2 分钟后重连... , controlServerIp = %s controlServerPort = %s", self.controlServerIp, self.controlServerPort);
                commonlib.Timer:new({callbackFunc = ConnectControlServer}):Change(2 * 60 * 1000);      -- 两分钟后重连
            end
        end)
    end

    ConnectControlServer();
end

-- 发送服务器信息
function WorkerServer:SendServerInfo()
    if (__rts__:GetName() ~= "main") then return self:SendMsgToMainThread({action = "SendServerInfo"}) end

    -- GGS.INFO.If(IsDevEnv, "WorkerServer upload server info");
    self.connection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({
        action = "ServerInfo",
        data = {
            isWorkerServer = self.isWorkerServer,                        -- 是否是工作线程
            isControlServer = self.isControlServer,                      -- 是否是工作线程
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
local UpdateStatisticsInfoCallBack = nil
function WorkerServer:UpdateStatisticsInfo(callback)
    UpdateStatisticsInfoCallBack = callback;

    if (__rts__:GetName() ~= "main") then return self:SendMsgToMainThread({action = "UpdateStatisticsInfo"}) end
    self.connection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "StatisticsInfo"}));
end

-- 处理通用数据包
function WorkerServer:handleGeneral(packetGeneral)
    local action = packetGeneral.action;
    local data = packetGeneral.data;
    -- GGS.INFO(__rts__:GetName(), action, data);
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
function WorkerServer:handleDisconnection(text, connection)
    GGS.INFO.Format("与控制服务器的断开连接, 尝试重连...");
    self.connection:Connect(nil, function()
        GGS.INFO.Format("成功重新接入控制服务器");
    end)
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
        WorkerServer:SetStatisticsInfo(data);
        if (type(UpdateStatisticsInfoCallBack) == "function") then
            UpdateStatisticsInfoCallBack();
        end
    end
end

NPL.this(activate);