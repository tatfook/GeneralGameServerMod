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
    self.connection = Connection:new():Init(nid, nil, self);
end

function ControlServer:GetWorldManager()
    return WorldManager;
end

function ControlServer:GetServer(isNewNotExist)
    local connectionId = self.connection:GetId();
    if (not servers[connectionId] and isNewNotExist) then servers[connectionId] = {} end
    return servers[connectionId];
end

function ControlServer:UpdateServerInfo()
    local server = self:GetServer(true);
    if (not server) then return end
    server.totalWorldCount = 0;
    server.totalClientCount = 0;

    local function resetThread(threadName)
        local thread = server.threads[threadName] or {};
        thread.clientCount = 0;
        thread.threadName = threadName;
        server.threads[threadName] = thread;
        server.thread = server.thread or thread;
    end
    for i = 1, server.threadCount do resetThread("T" .. tostring(i)) end
    resetThread("main");   -- 重置主线程

    local thread = nil;  
    for worldKey, world in pairs(server.worlds) do
        server.totalWorldCount = server.totalWorldCount + 1;
        server.totalClientCount = server.totalClientCount + world.clientCount;
        local worldThread = server.threads[world.threadName];
        if (not worldThread) then
            GGS.ERROR.Format("线程不存在: %s", world.threadName);
            worldThread = {clientCount = 0, threadName = world.threadName};
            server.threads[world.threadName] = worldThread;
        end
        worldThread.clientCount = worldThread.clientCount + world.clientCount;
        if (not thread or thread.clientCount > worldThread.clientCount) then thread = worldThread end
    end

    server.thread = thread or server.thread; -- 默认线程 取数量最小的线程
end

-- 处理服务器信息上报
function ControlServer:handleServerInfo(serverInfo)
    local server = self:GetServer(true);

    server.isControlServer = serverInfo.isWorkerServer == nil and false or serverInfo.isWorkerServer;
    server.isWorkerServer = serverInfo.isWorkerServer == nil and true or serverInfo.isWorkerServer;
    server.maxClientCount = serverInfo.maxClientCount or Config.Server.maxClientCount;
    server.threadCount = serverInfo.threadCount or Config.Server.threadCount;
    server.threadMaxClientCount = serverInfo.threadMaxClientCount or Config.Server.threadMaxClientCount;
    server.innerIp = serverInfo.innerIp or server.innerIp;                   -- 内网IP 
    server.innerPort = serverInfo.innerPort or server.innerPort;             -- 内网Port
    server.outerIp = serverInfo.outerIp or server.outerPort;                 -- 外网IP
    server.outerPort = serverInfo.outerPort or server.outerPort;             -- 外网Port 
    server.worlds = serverInfo.worlds or {};                                 -- 世界信息
    server.threads = server.threads or {};                                   -- 线程信息
    server.lastTick = os.time();                                             -- 上次发送时间
    
    self:UpdateServerInfo();

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
    local server, workerServer, controlServer = nil, nil, nil; -- 设置最大值
    local serverMaxClientCount = Config.Server.maxClientCount;
    local curTick = os.time();
    local realWorldKey, worldClientCount, threadName = worldKey, nil, nil;
    for key, svr in pairs(servers) do
        local isAlive = (curTick - svr.lastTick) < ServerAliveDuration; 
        -- 忽略已挂服务器或超负荷服务器
        if (isAlive and svr.totalClientCount < svr.maxClientCount) then 
            -- 优先找已存在的世界 且世界人数未满 世界人数最少
            for key, world in pairs(svr.worlds) do
                if (string.sub(key, 1, worldKeyLength) == worldKey
                    and world.clientCount < world.worldMaxClient 
                    and svr.threads[world.threadName].clientCount < svr.threadMaxClientCount
                    and (not worldClientCount or worldClientCount > world.clientCount)) then
                    worldClientCount = world.clientCount;
                    server = svr;
                    realWorldKey = key;
                    threadName = world.threadName;
                end
            end
            -- 选出压力最小的工作主机 
            workerServer = (svr.isWorkerServer and (not workerServer or workerServer.totalClientCount > svr.totalClientCount)) and svr or workerServer;
            -- 选出压力最小的控制主机
            controlServer = (svr.isControlServer and (not controlServer or controlServer.totalClientCount > svr.totalClientCount)) and svr or controlServer;
        end
    end
    server = server or workerServer or controlServer;
    if (server) then
        packetWorldServer.ip = server.outerIp;
        packetWorldServer.port = server.outerPort;
        packetWorldServer.worldKey = realWorldKey;
        packetWorldServer.threadName = threadName or (server.thread and server.thread.threadName) or "main";
        GGS.DEBUG.Format("客户端接入请求, worldId = %s, worldName = %s, worldKey = %s, ip = %s, port = %s, threadName = %s", worldId, worldName, realWorldKey, server.outerIp, server.outerPort, packetWorldServer.threadName);
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

-- 处理世界信息上传
function ControlServer:handleWorldInfo(world)
    local server = self:GetServer();
    if (not server or not world) then return end;

    server.lastTick = os.time();                                                   -- 上次发送时间
    server.worlds[world.worldKey] = server.worlds[world.worldKey] or {}; 
    commonlib.partialcopy(server.worlds[world.worldKey], world);
    self:UpdateServerInfo();
end

-- 处理通用数据包
function ControlServer:handleGeneral(packetGeneral)
    local action = packetGeneral.action;
    if (action == "ServerWorldList") then 
        packetGeneral.data = self:GetAvailableServers();
        self.connection:AddPacketToSendQueue(packetGeneral);
    elseif (action == "ServerInfo") then
        self:handleServerInfo(packetGeneral.data);
    elseif (action == "WorldInfo") then
        self:handleWorldInfo(packetGeneral.data);
    end
end

-- 连接丢失
function ControlServer:handleErrorMessage(text, connection)
    local connectionId = self.connection:GetId();
    servers[connectionId] = nil;
end

-- 激活函数
local function activate()
    if (not msg) then return end
	local id = msg.nid or msg.tid;
    if (not id) then return end

    local connection = Connections:GetConnection(id)
    if(connection) then
        connection:OnNetReceive(msg);
    else
        ControlServer:new():Init(id)
    end
end

NPL.this(activate);