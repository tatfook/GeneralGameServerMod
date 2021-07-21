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

local __servers__ = {};
function ServerManager:ctor()
end

function ServerManager:GetServerInfo()
    local nid = self:GetNid();
    __servers__[nid] = __servers__[nid] or {__threads__ = {}};
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
    server_info.maxClientCount = info.maxClientCount or server_info.maxClientCount;
    server_info.threadMaxClientCount = info.threadMaxClientCount or server_info.threadMaxClientCount;
    server_info.innerIp = info.innerIp or server_info.innerIp;
    server_info.innerPort = info.innerPort or server_info.innerPort;
    server_info.outerIp = info.outerIp or server_info.outerIp;
    server_info.outerPort = info.outerPort or server_info.outerPort;
    server_info.threadList = info.threadList or server_info.threadList;
end

function ServerManager:PushWorkerServerThreadInfo(info)
    local thread_info = self:GetThreadInfo(info.threadName);
    commonlib.partialcopy(thread_info, info.threadInfo);
end

function ServerManager:HandleMsg(msg)
    if (type(msg) ~= "table" or not msg.__cmd__ or not self:GetNid()) then return end
	local __cmd__, __data__ = msg.__cmd__, msg.__data__;
    -- print("===============ServerManager:HandleMsg==================")
	if (__cmd__ == "__push_worker_server_info__") then
        self:PushWorkerServerInfo(__data__, self);
    elseif (__cmd__ == "__push_worker_server_thread_info__") then
        self:PushWorkerServerThreadInfo(__data__);
	end
end

NPL.this(function() 
    ServerManager:OnActivate(msg);
end);

local function SelectWorkerServer(params)
    return "hello world"
end

Http:Get("/api/v0/__server_manager__/select", function(ctx)
    ctx:Send(SelectWorkerServer(ctx:GetParams()));
end);