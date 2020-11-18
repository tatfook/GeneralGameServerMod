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
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local ControlServer = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.ControlServer"));

local servers = {};  -- 服务器信息集
local ServerAliveDuration = 60 * 5;  -- 5min

function ControlServer:ctor()
    self:SetNetHandler(self);
end

function ControlServer:GetWorldManager()
    return WorldManager;
end

-- 获取统计信息
function ControlServer:GetStatisticsInfo()
    local totalClientCount = 0;
    local totalWorldCount = 0;
    local worldClientCounts = {};
    local totalServerCount = 0;
    local serverClientCounts = {};
    for svrkey, svr in pairs(servers) do
        if (not serverClientCounts[svrkey]) then
            serverClientCounts[svrkey] = 0;
            totalServerCount = totalServerCount + 1;
        end

        for _, thread in pairs(svr.threads) do
            totalClientCount = totalClientCount + thread.clientCount;
            serverClientCounts[svrkey] = serverClientCounts[svrkey] + thread.clientCount;
        end

        for worldkey, world in pairs(svr.worlds) do
            if (not worldClientCounts[worldkey]) then
                worldClientCounts[worldkey] = 0;
                totalWorldCount = totalWorldCount + 1;
            end

            worldClientCounts[worldkey] = worldClientCounts[worldkey] + world.clientCount;
        end

    end

    return {
        totalClientCount = totalClientCount,              -- 存在线客户端数
        totalWorldCount = totalWorldCount,                -- 存在的世界数
        totalServerCount = totalServerCount,              -- 存在服务数
        worldClientCounts = worldClientCounts,            -- 每个世界客户端数
        serverClientCounts = serverClientCounts,          -- 每个服务器客户端数
    }
end

function ControlServer:GetServer(isNewNotExist)
    local nid = self:GetNid();
    if (not servers[nid] and isNewNotExist) then servers[nid] = {} end
    return servers[nid];
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
    end
    for i = 1, server.threadCount do resetThread(GGS.WorkerThreadName  .. tostring(i)) end
    resetThread("main");   -- 重置主线程
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
    end
    local minThreadClientCount, defaultThreadName = nil, "main";
    for threadName, thread in pairs(server.threads) do
        if(threadName ~= "main") then  -- 避免选择主线程
            if (not minThreadClientCount or minThreadClientCount > thread.clientCount) then
                minThreadClientCount = thread.clientCount;
                defaultThreadName = threadName;
            end
        end
    end
    server.defaultThreadName = defaultThreadName; -- 默认线程名 取数量最小的线程
    
    -- GGS.DEBUG(server);
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
    server.worldServers = serverInfo.worldServers or {};                     -- 自定义世界服
    server.worlds = server.worlds or {};                                     -- 世界信息
    server.threads = server.threads or {};                                   -- 线程信息
    server.lastTick = os.time();                                             -- 上次发送时间
    
    self:UpdateServerInfo();

    return server;
end

-- 通过指定世界key查找世界服
function ControlServer:SelectWorldServerByWorldKey(worldKey)
    if (not worldKey) then return end

    local curTick = os.time();
    for key, svr in pairs(servers) do
        local isAlive = (curTick - svr.lastTick) < ServerAliveDuration; 
        if (isAlive) then 
            local worldServer = svr.worldServers[worldKey];
            if (worldServer) then return {ip = svr.outerIp, port = svr.outerPort, worldKey = worldKey, threadName = worldServer.threadName} end
            local world = svr.worlds[worldKey];
            if (world) then return {ip = svr.outerIp, port = svr.outerPort, worldKey = worldKey, threadName = world.threadName} end
        end
    end
    return ;
end

-- 通过指定世界key查找世界服
function ControlServer:SelectWorldServerByWorldIdAndName(worldId, worldName)
    -- 优先选择已存在世界的服务器
    -- 其次选择客户端最少的服务器
    -- 最后选择控制服务器
    local server, workerServer, controlServer = nil, nil, nil; -- 设置最大值
    local curTick = os.time();
    local worldKey, worldClientCount, threadName = nil, nil, nil;
    for key, svr in pairs(servers) do
        local isAlive = (curTick - svr.lastTick) < ServerAliveDuration; 
        -- 忽略已挂服务器或超负荷服务器
        if (isAlive and svr.totalClientCount < svr.maxClientCount) then 
            -- 优先找已存在的世界 且世界人数未满 世界人数最少
            for key, world in pairs(svr.worlds) do
                if (world.worldId == worldId and world.worldName == worldName 
                    and world.clientCount < world.maxClientCount 
                    and svr.threads[world.threadName].clientCount < svr.threadMaxClientCount
                    and (not worldClientCount or worldClientCount > world.clientCount)) then
                    worldClientCount = world.clientCount;
                    server = svr;
                    worldKey = key;
                    threadName = world.threadName;
                end
            end
            -- 选出压力最小的工作主机 
            workerServer = (svr.isWorkerServer and (not workerServer or workerServer.totalClientCount > svr.totalClientCount)) and svr or workerServer;
            -- 选出压力最小的控制主机
            controlServer = (svr.isControlServer and (not controlServer or controlServer.totalClientCount > svr.totalClientCount)) and svr or controlServer;
        end
    end
    -- 当autowoldkey不存在优先选工作节点
    server = server or workerServer or controlServer;
    
    -- 若找不到服务器则反回空
    if (not server) then return end

    -- 返回查找结果
    return {
        worldKey = worldKey,
        ip = server.outerIp,
        port = server.outerPort,
        threadName = threadName or server.defaultThreadName,
    }
end

-- 处理客户端请求连接世界的服务器
function ControlServer:handleWorldServer(packetWorldServer)
    local worldId = packetWorldServer.worldId;
    local worldName = packetWorldServer.worldName;
    local worldKey = packetWorldServer.worldKey;
    GGS.INFO.Format("客户端接入请求, worldId = %s, worldName = %s, worldKey = %s", worldId, worldName, worldKey);
    local worldServer = self:SelectWorldServerByWorldKey(worldKey) or self:SelectWorldServerByWorldIdAndName(worldId, worldName);

    if (worldServer) then
        packetWorldServer.ip = worldServer.ip;
        packetWorldServer.port = worldServer.port;
        packetWorldServer.worldKey = worldServer.worldKey;
        packetWorldServer.threadName = worldServer.threadName;
        GGS.INFO.Format("客户端接入响应, worldId = %s, worldName = %s, worldKey = %s, ip = %s, port = %s, threadName = %s", worldId, worldName, packetWorldServer.worldKey, packetWorldServer.ip, packetWorldServer.port, packetWorldServer.threadName);
    else 
        GGS.WARN.Format("无可用服务 worldId = %s, worldName = %s, worldKey = %s", worldId, worldName, worldKey);
    end

    self:AddPacketToSendQueue(packetWorldServer);
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
    return server;
end

-- 处理通用数据包
function ControlServer:handleGeneral(packetGeneral)
    local action = packetGeneral.action;
    if (action == "ServerList") then 
        packetGeneral.data = self:GetAvailableServers();
        self:AddPacketToSendQueue(packetGeneral);
    elseif (action == "ServerInfo") then
        local server = self:handleServerInfo(packetGeneral.data);
        self:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "ServerInfo", data = server}));
        self:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "ServerList", data = self:GetAvailableServers()}));
    elseif (action == "WorldInfo") then
        local server = self:handleWorldInfo(packetGeneral.data);
    elseif (action == "StatisticsInfo") then
        self:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "StatisticsInfo", data = self:GetStatisticsInfo()}));
    end
end

-- 连接丢失
function ControlServer:handleDisconnection()
    servers[self:GetNid()] = nil;
end

NPL.this(function() 
	ControlServer:OnActivate(msg);
end);