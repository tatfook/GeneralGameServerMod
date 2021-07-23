--[[
Title: MySql
Author(s):  wxa
Date: 2021-06-30
Desc: MySql
use the lib:
------------------------------------------------------------
local Server = NPL.load("Mod/GeneralGameServerMod/Server/Net/Server.lua");
------------------------------------------------------------
]]
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local VirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua");
local ThreadHelper = NPL.load("Mod/GeneralGameServerMod/CommonLib/ThreadHelper.lua");

local Server = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function Server:ctor() 
	self.__server__ = {__threads__ = {}};
end

function Server:Init()
end
	
function Server:GetThreadInfo(threadName)
	local __threads__ = self.__server__.__threads__;
	__threads__[threadName] = __threads__[threadName] or {};
	return __threads__[threadName]; 
end

-- 启动服务
function Server:Start(config) 
	if (self.__is_start__) then return end 

	CommonLib.AddPublicFile("Mod/GeneralGameServerMod/Server/Net/Handler.lua");
	CommonLib.AddPublicFile("Mod/GeneralGameServerMod/Server/Net/RPC.lua");
	CommonLib.AddPublicFile("Mod/GeneralGameServerMod/Server/Net/ServerManager.lua");
	
	-- 启动服务
	local ip, port = config.innerIp or config.outerIp, config.innerPort or config.outerPort;
	CommonLib.StartNetServer(ip, port);

	self.__server__.isControlServer = config.isControlServer;
	self.__server__.isWorkerServer = config.isWorkerServer;
	self.__server__.outerIp = config.outerIp;
	self.__server__.outerPort = config.outerPort;
	self.__server__.innerIp = config.innerIp;
	self.__server__.innerPort = config.innerPort;
	self.__server__.maxClientCount = config.maxClientCount;
	self.__server__.threadMaxClientCount = config.threadMaxClientCount;
	self.__server__.threadList = config.threadList;
	self.__is_start__ = true;

	-- 主循环
	CommonLib.SetInterval(1000 * 60 * 2, function() self:Tick() end);

	-- 工作节点则连接控制节点
	if (config.controlIp and config.controlPort) then
		local nid = CommonLib.AddNPLRuntimeAddress(config.controlIp, config.controlPort);
		self.__connection__ = VirtualConnection:new():Init({__nid__ = nid, __remote_neuron_file__ = "Mod/GeneralGameServerMod/Server/Net/ServerManager.lua"});
		self.__connection__:Connect(function()
			print("-----------success connect control server-----------------");
			self:PushWorkerServerInfo();
		end);
	end
end

function Server:Tick()
	self:PushWorkerServerInfo();
end

-- 主线程定时推送服务器信息
function Server:PushWorkerServerInfo()
	if (self.__connection__) then self.__connection__:SendMsg({__cmd__ = "__push_worker_server_info__", __data__ = self.__server__}) end
end

function Server:OnThreadMsg(msg)
    local __from_thread_name__, __to_thread_name__, __cmd__, __data__ = msg.__from_thread_name__, msg.__to_thread_name__, msg.__cmd__, msg.__data__;
	local thread_info = self:GetThreadInfo(__from_thread_name__);
    commonlib.partialcopy(thread_info, __data__);
	thread_info.__thread_name__ = __from_thread_name__;

	if (not self.__connection__ or type(__data__) ~= "table") then return end
	__data__.__thread_name__ = __from_thread_name__;
	self.__connection__:SendMsg({
		__cmd__ = "__push_worker_server_thread_info__",
		__data__ = __data__,
	});
end

Server:InitSingleton():Init();

ThreadHelper:OnMsg(function(msg)
	Server:OnThreadMsg(msg);
end);