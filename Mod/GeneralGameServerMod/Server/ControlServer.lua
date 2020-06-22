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
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local ControlServer = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.ControlServer"));

local servers = {};  -- 服务器信息集

function ControlServer:ctor()
    
end

function ControlServer:Init(nid)
    self.connection = Connection:new():Init(nid, self);
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

    servers[connectionId] = server;
end

-- 处理客户端请求连接世界的服务器
function ControlServer:handleWorldServer(packetWorldServer)
    local worldId = packetWorldServer.worldId;
    -- 优先选择已存在世界的服务器
    -- 其次选择客户端最少的服务器
    -- 最后选择控制服务器
    local server, controlServer = nil, nil; -- 设置最大值
    local workerServerMaxClientCount = tonumber(Config.Server.maxClientCount) or Config.maxClientCount;
    local controlServerMaxClientCount = tonumber(Config.Server.maxClientCount) or Config.maxClientCount;
    local worldMaxClientCount = tonumber(Config.World.maxClientCount) or Config.worldMaxClientCount;
    for key, svr in pairs(servers) do
        if (svr.totalWorldClientCounts[worldId]) then
            if (svr.totalWorldClientCounts[worldId] < worldMaxClientCount) then
                server = svr;
            else
                server, controlServer = nil, nil;  -- 单世界人数太多
            end
            break;
        end
        if (svr.isWorkerServer and svr.maxClientCount < workerServerMaxClientCount) then
            server = server or svr;
            if (server.totalClientCount > svr.totalClientCount) then
                server = svr;
            end
        end
        if (svr.isControlServer and svr.maxClientCount < controlServerMaxClientCount) then
            controlServer = controlServer or svr;
            if (controlServer.totalClientCount > svr.totalClientCount) then 
                controlServer = svr;
            end
        end
    end
    server = server or controlServer;
    if (server) then
        packetWorldServer.ip = server.outerIp;
        packetWorldServer.port = server.outerPort;
    else 
        Log:Warn("世界ID: %d 无可用服务", worldId);
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