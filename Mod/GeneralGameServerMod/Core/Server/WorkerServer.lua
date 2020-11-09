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
    self.connection = Connection:new():InitByIpPort(self.controlServerIp, self.controlServerPort, nil, self);
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

-- 获取服务器最大客户端数
function WorkerServer:GetMaxClientCount()
    return Config.WorkerServer.maxClientCount or Config.Server.maxClientCount;
end

function WorkerServer:SendMsgToMainThread(msg)
	NPL.activate("(gl)Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua", msg);
end

-- 发送服务器信息
function WorkerServer:SendServerInfo()
    if (__rts__:GetName() ~= "main") then return self:SendMsgToMainThread({action = "SendServerInfo"}) end

    self.connection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({
        action = "ServerInfo",
        data = {
            isWorkerServer = true,
            worlds = WorldManager:GetAllWorldInfo(),               -- 所有世界信息
            innerIp = self.innerIp,                                -- 内网IP 
            innerPort = self.innerPort,                            -- 内网Port
            outerIp = self.outerIp,                                -- 外网IP
            outerPort = self.outerPort,                            -- 外网Port 
            maxClientCount = Config.Server.maxClientCount,         -- 服务器最大客户端数
            threadCount = Config.Server.threadCount,               -- 服务器的线程数
            threadMaxClientCount = Config.Server.threadMaxClientCount; -- 单个线程最大客户端数
        }
    }));
end

-- 发送世界信息
function WorkerServer:SendWorldInfo(worldKey)
    if (__rts__:GetName() ~= "main") then return self:SendMsgToMainThread({action = "SendWorldInfo", worldKey = worldKey}) end

    local world = WorldManager:GetWorldInfo(worldKey);
    if (not world) then return end

    self.connection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({
        action = "WorldInfo", 
        data  = world
    }));
end

-- 处理通用数据包
function WorkerServer:handleGeneral(packetGeneral)
    local action = packetGeneral.action;
    if (action == "ServerWorldList") then 
        self:SetServerList(packetGeneral.data);
    end
end

-- 连接丢失
function WorkerServer:handleErrorMessage(text, connection)
    GGS.INFO.Format("断开与控制服务器的连接");
end

-- 激活函数
local function activate()
	local action = msg and msg.action;

    if (action == "SendServerInfo") then 
        return WorkerServer:SendServerInfo();
    elseif (action == "SendWorldInfo") then
        return WorkerServer:SendWorldInfo(msg.worldKey);
    end

end

NPL.this(activate);