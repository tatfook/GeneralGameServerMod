--[[
Title: ServerManager
Author(s):  wxa
Date: 2021-06-30
Desc: 网络API
use the lib:
------------------------------------------------------------
local ServerManager = NPL.load("Mod/GeneralGameServerMod/Server/Net/ServerManager.lua");
------------------------------------------------------------
]]
local Http = NPL.load("Mod/GeneralGameServerMod/Server/Http/Http.lua");

local VirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua");

local ServerManager = commonlib.inherit(VirtualConnection, NPL.export());
local ServerAliveDuration = 60 * 5;         -- 5min
local __servers__ = {};
function ServerManager:ctor()
end

function ServerManager:GetAllServerInfo()
    return __servers__
end

function ServerManager:GetServerInfo()
    local nid = self:GetNid();
    __servers__[nid] = __servers__[nid] or {__threads__ = {}, __last_heartbeat_time__ = os.time()};
    return __servers__[nid];
end

function ServerManager:GetThreadInfo(threadName)
    local __threads__ = self:GetServerInfo().__threads__;
    __threads__[threadName] = __threads__[threadName] or {};
    return __threads__[threadName];
end

function ServerManager:PushWorkerServerInfo(info, connection)
    local server_info = self:GetServerInfo();

    server_info.__connection__ = connection or server_info.__connection__;
    server_info.isControlServer = if_else(info.isControlServer == nil, server_info.isControlServer, info.isControlServer);
    server_info.isWorkerServer = if_else(info.isWorkerServer == nil, server_info.isWorkerServer, info.isWorkerServer);
    server_info.maxClientCount = info.maxClientCount or server_info.maxClientCount or 10000;
    server_info.threadMaxClientCount = info.threadMaxClientCount or server_info.threadMaxClientCount or 500;
    server_info.innerIp = info.innerIp or server_info.innerIp;
    server_info.innerPort = info.innerPort or server_info.innerPort;
    server_info.outerIp = info.outerIp or server_info.outerIp;
    server_info.outerPort = info.outerPort or server_info.outerPort;
    server_info.threadList = info.threadList or server_info.threadList;
    self:UpdateServerInfo();
end

function ServerManager:PushWorkerServerThreadInfo(info)
    local thread_info = self:GetThreadInfo(info.__thread_name__);
    commonlib.partialcopy(thread_info, info);
    self:UpdateServerInfo();
end

function ServerManager:UpdateServerInfo()
    local server = self:GetServerInfo();
    server.totalWorldCount = 0;
    server.totalClientCount = 0;

    local function resetThread(threadName)
        local thread = server.__threads__[threadName] or {};
        thread.clientCount = 0;
        thread.__thread_name__ = thread.__thread_name__ or threadName;
        thread.__worlds__ = thread.__worlds__ or {};
        server.__threads__[threadName] = thread;
    end
    -- 重置主线程
    resetThread("main");   
    for _, threadName in ipairs(server.threadList) do resetThread(threadName) end

    for _, thread in pairs(server.__threads__) do
        for worldKey, world in pairs(thread.__worlds__) do
            server.totalWorldCount = server.totalWorldCount + 1;
            server.totalClientCount = server.totalClientCount + world.clientCount;
            thread.clientCount = thread.clientCount + world.clientCount;
        end
    end

    local minThreadClientCount, defaultThreadName = nil, "main";
    for threadName, thread in pairs(server.__threads__) do
        if(threadName ~= "main") then  -- 避免选择主线程
            if (not minThreadClientCount or minThreadClientCount > thread.clientCount) then
                minThreadClientCount = thread.clientCount;
                defaultThreadName = threadName;
            end
        end
    end
    server.defaultThreadName = defaultThreadName; -- 默认线程名 取数量最小的线程
    server.__last_heartbeat_time__ = os.time();

    -- GGS.INFO(server);
end


function ServerManager:HandleMsg(msg)
    if (type(msg) ~= "table" or not msg.__cmd__ or not self:GetNid()) then return end
	local __cmd__, __data__ = msg.__cmd__, msg.__data__;
    -- print("===============ServerManager:HandleMsg==================", __cmd__)
	if (__cmd__ == "__push_worker_server_info__") then
        self:PushWorkerServerInfo(__data__, self);
    elseif (__cmd__ == "__push_worker_server_thread_info__") then
        self:PushWorkerServerThreadInfo(__data__);
	end
end

NPL.this(function() 
    ServerManager:OnActivate(msg);
end);

-- 通过指定世界key查找世界服
local function SelectWorldServerByWorldKey(worldKey)
    if (not worldKey) then return end
    local cur_time = os.time();
    for key, svr in pairs(__servers__) do
        local isAlive = svr.isControlServer or ((cur_time - svr.__last_heartbeat_time__) < ServerAliveDuration); -- 控制节点无需心跳检测
        if (isAlive) then 
            -- local worldServer = svr.worldServers[worldKey];
            -- if (worldServer) then return {ip = svr.outerIp, port = svr.outerPort, worldKey = worldKey, threadName = worldServer.threadName} end
            for threadName, thread in pairs(svr.__threads__) do
                if (thread.__worlds__[worldKey]) then return {ip = svr.outerIp, port = svr.outerPort, worldKey = worldKey, threadName = threadName} end
            end
        end
    end
    return ;
end

-- 通过指定世界key查找世界服
local function SelectWorldServerByWorldIdAndName(worldId, worldName)
    -- 优先选择已存在世界的服务器
    -- 其次选择客户端最少的服务器
    -- 最后选择控制服务器
    local server, workerServer, controlServer = nil, nil, nil; -- 设置最大值
    local curTick = os.time();
    local selectWorldKey, selectThreadName = nil, nil;
    local clientCountPerRate = 20;                             -- 单个分值对应的世界人数
    local worldRate = -1;                                      -- 世界评分 评分越大优先选取
    for key, svr in pairs(__servers__) do
        local isAlive = svr.isControlServer or ((curTick - svr.__last_heartbeat_time__) < ServerAliveDuration);   -- 控制节点无需心跳检测
        -- 忽略已挂服务器或超负荷服务器
        if (isAlive and svr.totalClientCount < svr.maxClientCount) then 
            -- 优先找已存在的世界 且世界人数未满 世界人数最少
            for threadName, thread in pairs(svr.__threads__) do
                if (thread.clientCount < svr.threadMaxClientCount) then
                    for key, world in pairs(thread.__worlds__) do
                        if (tostring(world.worldId) == tostring(worldId) and world.worldName == worldName and world.clientCount < world.maxClientCount) then
                            -- 对可选择的世界进行评分
                            local curWorldRate = world.clientCount > (world.maxClientCount - clientCountPerRate) and 0 or math.ceil(world.clientCount / clientCountPerRate);
                            -- 优先选世界人数较多且未进入上限缓冲区的世界    
                            if (worldRate < curWorldRate) then
                                worldRate = curWorldRate;
                                server = svr;
                                selectWorldKey = key;
                                selectThreadName = threadName;
                            end
                        end
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
        worldKey = selectWorldKey,
        ip = server.outerIp,
        port = server.outerPort,
        threadName = selectThreadName or server.defaultThreadName,
    }
end

-- 处理客户端请求连接世界的服务器
local function SelectWorldServer(params)
    local worldId = params.worldId;
    local worldName = params.worldName or "";
    local worldKey = params.worldKey;
    GGS.INFO.Format("客户端接入请求, worldId = %s, worldName = %s, worldKey = %s", worldId, worldName, worldKey);
    local worldServer = SelectWorldServerByWorldKey(worldKey) or SelectWorldServerByWorldIdAndName(worldId, worldName);

    if (worldServer) then
        GGS.INFO.Format("客户端接入响应, worldId = %s, worldName = %s, worldKey = %s, ip = %s, port = %s, threadName = %s", worldId, worldName, worldServer.worldKey, worldServer.ip, worldServer.port, worldServer.threadName);
    else 
        GGS.WARN.Format("无可用服务 worldId = %s, worldName = %s, worldKey = %s", worldId, worldName, worldKey);
    end

    return worldServer;
end

Http:Get("/api/v0/__server_manager__/__select_world_server__", function(ctx)
    ctx:Send(SelectWorldServer(ctx:GetParams()));
end);