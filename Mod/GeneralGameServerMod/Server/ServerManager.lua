--[[
Title: Cluster
Author(s): wxa
Date: 2020/6/22
Desc: 集群
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/Cluster.lua");
local Cluster = commonlib.gettable("GeneralGameServerMod.Server.Cluster");
Cluster.GetSingleton();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local ServerManager = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.ServerManager"));

-- 单列模式
local g_instance;
function ServerManager.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = ServerManager:new();
		return g_instance;
	end
end

-- 构造函数
function Cluster:ctor()   
    -- 服务器集
    self.serverList = commonlib.UnorderedArraySet:new();           
    -- 连接列表
    self.controlServerConnectList = commonlib.UnorderedArraySet:new();

    -- 服务器对象
    self.serverList.add({
        isControlServer = false, -- 是否为工作服务
        isWorkerServer = true,   -- 是否为控制服务
        innerIp = "127.0.0.1",   -- 内网IP 
        innerPort = "9000",      -- 内网Port
        outerIp = "127.0.0.1",   -- 外网IP
        outerPort = "9000",      -- 外网Port 
        isSelf = true,           -- 是否是当前服务器
    });
end

-- 初始化函数
function Cluster:Init() 
end

-- 获取本服务器的server对象
function Cluster:GetSelfServer()
    for i = 0, #(self.serverList) do
        local server = self.serverList[i];
        if (server.isSelf) then
            return true;
        end
    end
end

-- 获取控制服务列表
function Cluster:GetControlServerList()
    local list = {}
    for i = 0, #(self.serverList) do
        local server = self.serverList[i];
        if (server.isControlServer) then
            list[#list + 1] = server;
        end
    end
    return list;
end

-- 连接控制Server
function Cluster:ConnectControlServer()
    local controlServerList = self:GetControlServerList[1];
    for index, server in ipairs(controlServerList) then
        local connection = Connection:new():Init(server.innerIp, server.innerPort, self);
        connection:connect(5, function() 
            self.controlServerConnectList.add(connection);
            server.connection = connection;
        end)
    end
end

