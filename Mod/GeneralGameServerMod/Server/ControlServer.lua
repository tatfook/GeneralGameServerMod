--[[
Title: Cluster
Author(s): wxa
Date: 2020/6/22
Desc: 服务器控制器处理程序
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/ControlServer.lua");
local ControlServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.ControlServer");
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");NPL.load("Mod/GeneralGameServerMod/Server/WorldManager.lua");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Server.WorldManager");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local ControlServer = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.ControlServer"));

local servers = {};  -- 服务器信息集

function ControlServer:ctor()
    WorldManager.GetSingleton();
    
end

function ControlServer:Init(nid)
    self.connection = Connection:new():Init(nid, self);
end

function ControlServer:GetWorldManager()
    return WorldManager.GetSingleton();
end

-- 处理服务器信息上报
function ControlServer:handleServerInfo(packetServerInfo)
    local connectionId = self.connection:GetId();
    local server = servers[connectionId] or {};

    server.isControlServer = packetServerInfo.isWorkerServer == nil and false or packetServerInfo.isWorkerServer;
    server.isWorkerServer = packetServerInfo.isWorkerServer == nil and true or packetServerInfo.isWorkerServer;
    server.totalWorldCount = packetServerInfo.totalWorldCount or 0;
    server.totalClientCount = packetServerInfo.totalClientCount or 0;
    server.totalWorldClientCounts = packetServerInfo.totalWorldClientCounts or 0;
    server.innerIp = packetServerInfo.innerIp or server.innerIp;                   -- 内网IP 
    server.innerPort = packetServerInfo.innerPort or server.innerPort;             -- 内网Port
    server.outerIp = packetServerInfo.outerIp or server.outerPort;                 -- 外网IP
    server.outerPort = packetServerInfo.outerPort or server.outerPort;             -- 外网Port 
    server.lastTick = ParaGlobal.timeGetTime();                                    -- 上次发送时间
    servers[connectionId] = server;
end

-- 处理客户端请求连接世界的服务器
function ControlServer:handleWorldServer(packetWorldServer)
    local worldId = packetWorldServer.worldId;
    local parallelWorldName = packetWorldServer.parallelWorldName;
    local worldKey = self:GetWorldManager():GenerateWorldKey(worldKey, parallelWorldName);
    -- 优先选择已存在世界的服务器
    -- 其次选择客户端最少的服务器
    -- 最后选择控制服务器
    local server, controlServer = nil, nil; -- 设置最大值
    local serverMaxClientCount = tonumber(Config.Server.maxClientCount) or Config.maxClientCount;
    local worldMaxClientCount = tonumber(Config.World.maxClientCount) or Config.worldMaxClientCount;
    local curTick, aliveDuration = ParaGlobal.timeGetTime(), 1000 * 60 * 5;
    for key, svr in pairs(servers) do
        local isAlive = (curTick - svr.lastTick) < aliveDuration; 
        if (not isAlive) then
            Log:Warn("服务不可用: ip = %s, port = %s", svr.outerIp, svr.outerPort);
        end
        -- 忽略已挂服务器或超负荷服务器
        if (isAlive and svr.totalClientCount < serverMaxClientCount) then 
            -- 优先找已存在的世界 且世界人数未满
            if (svr.totalWorldClientCounts[worldKey] and svr.totalWorldClientCounts[worldKey] < worldMaxClientCount) then
                server = svr;
                break; -- 找到退出循环
            end
            -- 工作主机 
            server = (svr.isWorkerServer and (not server or server.totalClientCount > svr.totalClientCount)) and svr or server;
            -- 控制主机
            controlServer = (svr.isControlServer and (not controlServer or controlServer.totalClientCount > svr.totalClientCount)) and svr or controlServer;
        end
    end
    server = server or controlServer;
    if (server) then
        packetWorldServer.ip = server.outerIp;
        packetWorldServer.port = server.outerPort;
    else 
        Log:Warn("世界key: %s 无可用服务", worldKey);
    end

    self.connection:AddPacketToSendQueue(packetWorldServer);
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