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
print("====================dsd=============")

local Config = NPL.load("./Config.lua");
local Packets = NPL.load("../Common/Packets.lua");
local Connection = NPL.load("../Common/Connection.lua");

local ControlServer = commonlib.inherit(Connection, NPL.export());

local servers = {};                         -- 服务器信息集
local ServerAliveDuration = 60 * 5;         -- 5min

if (__rts__:GetName() == "main") then
    _G.SERVERS = servers;                       -- 导出全局变量中
end

function ControlServer:ctor()
    self:SetNetHandler(self);
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

    -- GGS.INFO(servers);

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
    
    -- GGS.INFO.If(IsDevEnv, server);
    -- GGS.INFO.If(IsDevEnv, servers);
end

-- 处理服务器信息上报
function ControlServer:handleServerInfo(serverInfo)
    -- GGS.INFO.If(IsDevEnv, "ControlServer:handleServerInfo", serverInfo);

    local server = self:GetServer(true);

    server.isControlServer = if_else(serverInfo.isControlServer == nil, false, serverInfo.isControlServer);
    server.isWorkerServer = if_else(serverInfo.isWorkerServer == nil, true, serverInfo.isWorkerServer);
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
        local isAlive = svr.isControlServer or ((curTick - svr.lastTick) < ServerAliveDuration); -- 控制节点无需心跳检测
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
    local worldKey, threadName = nil, nil;
    local clientCountPerRate = 20;                             -- 单个分值对应的世界人数
    local worldRate = -1;                                      -- 世界评分 评分越大优先选取
    for key, svr in pairs(servers) do
        local isAlive = svr.isControlServer or ((curTick - svr.lastTick) < ServerAliveDuration);   -- 控制节点无需心跳检测
        -- 忽略已挂服务器或超负荷服务器
        if (isAlive and svr.totalClientCount < svr.maxClientCount) then 
            -- 优先找已存在的世界 且世界人数未满 世界人数最少
            for key, world in pairs(svr.worlds) do
                if (world.worldId == worldId and world.worldName == worldName 
                    and world.clientCount < world.maxClientCount 
                    and svr.threads[world.threadName].clientCount < svr.threadMaxClientCount) then
                    -- 对可选择的世界进行评分
                    local curWorldRate = world.clientCount > (world.maxClientCount - clientCountPerRate) and 0 or math.ceil(world.clientCount / clientCountPerRate);
                    -- 优先选世界人数较多且未进入上限缓冲区的世界    
                    if (worldRate < curWorldRate) then
                        worldRate = curWorldRate;
                        server = svr;
                        worldKey = key;
                        threadName = world.threadName;
                    end
                end
            end
            -- 选出压力最小的工作主机 
            workerServer = (svr.isWorkerServer and not svr.isControlServer and (not workerServer or workerServer.totalClientCount > svr.totalClientCount)) and svr or workerServer;
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
    local worldName = packetWorldServer.worldName or "";
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
    local worldKey = world.worldKey;
    server.lastTick = os.time();         -- 上次发送时间
    if (world.clientCount == 0) then
        server.worlds[worldKey] = nil;   -- 世界无人清除世界信息
    else
        server.worlds[world.worldKey] = server.worlds[world.worldKey] or {}; 
        commonlib.partialcopy(server.worlds[world.worldKey], world);
    end                                          
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


--[[
`GET http://ggs.keepwork.com:9000/`
-- 服务集
{
    -- NID 为连接ID
    [NID] = {
        -- 单服务对象
        isControlServer: true,               -- 是否是控制节点
        defaultThreadName: "WorkerThread1",  -- 默认分配线程
        outerPort: 9000,                     -- 外网端口
        lastTick:1624676230,                 -- 上次心跳时间戳
        totalWorldCount:0,                   -- 世界数
        threadMaxClientCount:200,            -- 单线程支持的最大用户数
        totalClientCount:0,                  -- 用户数
        worldServers:{                       -- 世界所在线程集
            worldkey1: {                     -- 世界key
                threadName:"WorkerThread3",  -- 所仔线程
                worldKey:"worldkey1"         -- 世界key
            },
            worldkey2: {
                threadName:"WorkerThread1",
                worldKey:"worldkey2"
            },
            worldkey3:{
                threadName: "WorkerThread2",
                worldKey:"worldkey3"
            }
        },
        innerIp:"127.0.0.1",                 -- 内网IP
        threadCount:3,                       -- 线程数
        threads:{                            -- 线程集
            main:{                           -- 线程名  主线程
                clientCount:0,               -- 线程用户数
                threadName:"main"            -- 线程名
            },
            WorkerThread1:{
                clientCount:0,
                threadName:"WorkerThread1"
            },
            WorkerThread3:{
                clientCount:0,
                threadName:"WorkerThread3"
            },
            WorkerThread2:{
                clientCount:0,
                threadName:"WorkerThread2"
            }
        },
        maxClientCount:100,                 -- 支持最大用户数据
        innerPort:9000,                     -- 内网端口
        worlds:{                            -- 世界集
            127.0.0.1_9000_WorkerThread1_0_WorldName_GI_: {       -- 世界KEY
                clientCount:1,              -- 世界用户数
                worldName:"WorldName_GI",   -- 世界名
                worldId:"0",                -- 世界ID
                maxClientCount:10,          -- 世界支持的最大用户数
                worldKey:"127.0.0.1_9000_WorkerThread1_0_WorldName_GI_", 世界KEY
                threadName:"WorkerThread1"  -- 世界所在线程
        },                          
        outerIp:"127.0.0.1",                -- 外网IP
        isWorkerServer:true                 -- 是否是工作线程
    }
}

-- UI
服务器列表
外网IP, 外网端口, 内网IP, 内网端口, 线程数, 用户数, 支持最大用户数, 是否启动,   操作(重启, 停止)
单服务器-线程列表
线程名, 世界数, 支持最大世界数, 用户数, 支持最大用户数
单服务器-世界列表
世界KEY, 所属线程名, 用户数, 最大用户数
--]]
