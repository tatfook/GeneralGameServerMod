--[[
Title: Cluster
Author(s): wxa
Date: 2020/6/22
Desc: 服务器控制器处理程序
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/ControlServer.lua");
local ControlServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.ControlServer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorldManager.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
local ControlServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.ControlServer"));

local servers = {};  -- 服务器信息集
local ServerAliveDuration = 1000 * 60 * 5;  -- 5min

function ControlServer:ctor()
end

function ControlServer:Init(nid)
    self.connection = Connection:new():Init(nid, self);
end

function ControlServer:GetWorldManager()
    return WorldManager;
end

-- 处理服务器信息上报
function ControlServer:handleServerInfo(packetServerInfo)
    local connectionId = self.connection:GetId();
    local server = servers[connectionId] or {};

    server.isControlServer = packetServerInfo.isWorkerServer == nil and false or packetServerInfo.isWorkerServer;
    server.isWorkerServer = packetServerInfo.isWorkerServer == nil and true or packetServerInfo.isWorkerServer;
    server.maxClientCount = packetServerInfo.maxClientCount or Config.Server.maxClientCount;
    server.totalWorldCount = packetServerInfo.totalWorldCount or 0;
    server.totalClientCount = packetServerInfo.totalClientCount or 0;
    server.totalWorldClientCounts = packetServerInfo.totalWorldClientCounts or 0;
    server.innerIp = packetServerInfo.innerIp or server.innerIp;                   -- 内网IP 
    server.innerPort = packetServerInfo.innerPort or server.innerPort;             -- 内网Port
    server.outerIp = packetServerInfo.outerIp or server.outerPort;                 -- 外网IP
    server.outerPort = packetServerInfo.outerPort or server.outerPort;             -- 外网Port 
    server.lastTick = os.time();                                                   -- 上次发送时间
    servers[connectionId] = server;

    -- 将可用的服务器信息返回给server
    self.connection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "ServerWorldList", data = self:GetAvailableServers()}));
end

-- 处理客户端请求连接世界的服务器
function ControlServer:handleWorldServer(packetWorldServer)
    local worldId = packetWorldServer.worldId;
    local worldName = packetWorldServer.worldName;
    local worldKey = self:GetWorldManager():GenerateWorldKey(worldId, worldName);
    local worldKeyLength = string.len(worldKey);
    -- 优先选择已存在世界的服务器
    -- 其次选择客户端最少的服务器
    -- 最后选择控制服务器
    local server, workServer, controlServer = nil, nil, nil; -- 设置最大值
    local serverMaxClientCount = Config.Server.maxClientCount;
    local curTick = os.time();
    local realWorldKey, worldClientCount = worldKey, nil;
    for key, svr in pairs(servers) do
        local isAlive = (curTick - svr.lastTick) < ServerAliveDuration; 
        -- 忽略已挂服务器或超负荷服务器
        if (isAlive and svr.totalClientCount < svr.maxClientCount) then 
            -- 优先找已存在的世界 且世界人数未满 世界人数最少
            for key, count in pairs(svr.totalWorldClientCounts) do
                if (string.sub(key, 1, worldKeyLength) == worldKey and (not worldClientCount or worldClientCount > count)) then
                    worldClientCount = count;
                    server = svr;
                    realWorldKey = key;
                end
            end
            -- 选出压力最小的工作主机 
            workServer = (svr.isWorkerServer and (not workServer or workServer.totalClientCount > svr.totalClientCount)) and svr or workServer;
            -- 选出压力最小的控制主机
            controlServer = (svr.isControlServer and (not controlServer or controlServer.totalClientCount > svr.totalClientCount)) and svr or controlServer;
        end
    end
    server = server or workServer or controlServer;
    if (server) then
        packetWorldServer.ip = server.outerIp;
        packetWorldServer.port = server.outerPort;
        -- packetWorldServer.worldKey = realWorldKey;
    else 
        GGS.WARN.Format("世界key: %s 无可用服务", worldKey);
    end

    self.connection:AddPacketToSendQueue(packetWorldServer);
end

-- 获取可用的服务器列表
function ControlServer:GetAvailableServers()
    local curTick, aliveDuration = os.time(), 1000 * 60 * 5;
    local serverList= {};
    for key, svr in pairs(servers) do
        local isAlive = (curTick - svr.lastTick) < ServerAliveDuration; 
        if (isAlive) then
            serverList[#serverList + 1] = svr;
        else
            GGS.WARN.Format("服务不可用: ip = %s, port = %s", svr.outerIp, svr.outerPort)
        end
    end
    return serverList;
end

-- 处理通用数据包
function ControlServer:handleGeneral(packetGeneral)
    local action = packetGeneral.action;
    if (action == "ServerWorldList") then 
        packetGeneral.data = self:GetAvailableServers();
        self.connection:AddPacketToSendQueue(packetGeneral);
    end
end

-- 连接丢失
function ControlServer:handleErrorMessage(text, connection)
    local connectionId = self.connection:GetId();
    servers[connectionId] = nil;
end

-- 激活函数
local function activate()
	local msg = msg;
	local id = msg.nid or msg.tid;

    if (not id) then
        return;
    end

    local connection = Connections:GetConnection(id)
    if(connection) then
        connection:OnNetReceive(msg);
    else
        ControlServer:new():Init(id)
    end
end

NPL.this(activate);