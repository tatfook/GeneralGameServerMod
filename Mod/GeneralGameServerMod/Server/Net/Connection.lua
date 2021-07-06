--[[
Title: Connection
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
local Connection = NPL.load("Mod/GeneralGameServerMod/Server/Net/Connection.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/event_mapping.lua");

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Connection = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local __event_emitter__ = EventEmitter:new();       -- 事件触发器
local __remote_file__ = "Mod/GeneralGameServerMod/Client/Net/Connection.lua";
local __local_file__ = "Mod/GeneralGameServerMod/Server/Net/Connection.lua";
local __nid_thread_map__ = {};
local __is_connected__ = {};                        -- 是否已连接

Connection:Property("ThreadName", "gl");
Connection:Property("RemoteNeuronFile", __remote_file__);   -- 对端处理文件
Connection:Property("LocalNeuronFile", __local_file__);    -- 本地处理文件
Connection:Property("ConnectionClosed", false, "IsConnectionClosed");                           -- 是否已关闭

CommonLib.AddPublicFile(__local_file__);

local function GetConnectionKey(connection)
	local nid = connection:GetNid();
	return string.format("%s_%s", tostring(nid), tostring(connection));
end

local function RegisterConnectionEvent(connection)
	local key = GetConnectionKey(connection);
	__event_emitter__:RegisterEventCallBack("__connected__", connection.__on_connected__, key);
	__event_emitter__:RegisterEventCallBack("__msg__", connection.__on_receive__, key);
	__event_emitter__:RegisterEventCallBack("__disconnected__", connection.__on_disconnected__, key);
end

local function RemoveConnectionEvent(connection)
	local key = GetConnectionKey(connection);
	__event_emitter__:RemoveEventCallBack("__connected__", connection.__on_connected__, key);
	__event_emitter__:RemoveEventCallBack("__msg__", connection.__on_receive__, key);
	__event_emitter__:RemoveEventCallBack("__disconnected__", connection.__on_disconnected__, key);
end

function Connection:ctor()
	self.__on_connected__ = function(msg)
		local nid = msg and (msg.nid or msg.tid);
		if (nid ~= self:GetNid()) then return end
		-- 触发回调
		self:OnConnected(msg);
	end

	self.__on_receive__ = function(msg)
		local nid = msg and (msg.nid or msg.tid);
		if (nid ~= self:GetNid()) then return end
		self:OnReceive(msg);
	end

	self.__on_disconnected__ = function(msg)
		local nid = msg and (msg.nid or msg.tid);
		if (nid ~= self:GetNid()) then return end
		self:OnDisconnected(msg);
	end
end

function Connection:Init(nid)
	self:SetNid(nid);
	return self;
end

function Connection:SetNid(nid)
	RemoveConnectionEvent(self);
	self.__nid__ = nid;
	RegisterConnectionEvent(self);
end

function Connection:GetNid()
	return self.__nid__;
end

function Connection:Disconnect()
	AllConnections[self:GetNid()] = nil;
    self:SetConnectionClosed(true);
	self:OnDisconnected();
end

-- 关闭连接
function Connection:Close(reason)
	NPL.reject({["nid"] = self:GetNid(), ["reason"] = reason});
	self:Disconnect();
	self:OnClose();
end

-- send message immediately to c++ queue
-- @param msg: the raw message table {id=packet_id, .. }. 
-- @param neuronfile: should be nil. By default, it is this file. 
function Connection:Send(data, neuronfile)
	if (self:IsConnectionClosed()) then return end
	local address = self:GetRemoteAddress(neuronfile);
	local ret = NPL.activate(address, {__cmd__ = "__msg__", __file__ = self:GetLocalNeuronFile(), __data__ = data});
	if(ret ~= 0) then
		LOG.std(nil, "warn", "Connection", "unable to send to %s.", self:GetNid());
		self:Close("发包失败");
	end
end

-- 发送消息
function Connection:OnSend(msg, neuronfile)
	return msg, neuronfile;
end

-- 接受消息
function Connection:OnReceive(msg)
end

-- 链接关闭
function Connection:OnClose()
end

-- 新链接
function Connection:OnConnected()
end

-- 连接断开
function Connection:OnDisconnected()
end

-- 获取连接
function Connection:GetConnectionByNid(nid)
	return AllConnections[nid];
end

function Connection:OnActivate(msg)
	-- 链接ID不存在
    local nid = msg and (msg.nid or msg.tid);
	if (not nid) then return end
	-- 获取连接
	-- local connection = __all_connections__[nid];
    -- -- 链接已存在 直接处理消息
	-- if(connection) then 
	-- 	if (msg.__cmd__ == "__init__") then
	-- 		echo(msg);
	-- 		if (msg.__thread_name__) then connection:SetThreadName(msg.__thread_name__) end
	-- 		if (msg.__file__) then connection:SetRemoteNeuronFile(msg.__file__) end
	-- 	else
	-- 		return connection:OnReceive(msg);
	-- 	end
	-- end
	-- 新建连接
	connection = self:new():Init(nid);
	__is_connected__[nid] = true;
	__event_emitter__:TriggerEventCallBack("__connected__", msg);
	-- 通知主线程
	NPL.activate(string.format("(main)%s", __local_file__), {__cmd__ = "ConnectionEstablished", __thread_name__ = __rts__:GetName(), __nid__ = connection:GetNid()});
	-- 触发连接回调
	connection:OnConnected();
end

NPL.this(function() 
	local nid = msg and (msg.nid or msg.tid);
	local __cmd__ = msg and msg.__cmd__;
	if (nid) then return Connection:OnActivate(msg) end
	
	echo(msg)
	if (__cmd__ == "ConnectionEstablished") then
		__nid_thread_map__[msg.__nid__] = msg.__thread_name__; 
	elseif (__cmd__ == "ConnectionDisconnected") then
		__is_connected__[nid] = false;
		__event_emitter__:TriggerEventCallBack("__on_disconnected__", msg);
	else 
	end
end);

-- c++ callback function. 
CommonLib.OnNetworkEvent(function(msg) 
	local nid = msg.nid or msg.tid;
	local threadName = __nid_thread_map__[nid] or "main";
	if(msg.code == NPLReturnCode.NPL_ConnectionDisconnected) then
		-- 链接断开
        NPL.activate(string.format("(%s)%s", threadName, __local_file__), {__cmd__ = "ConnectionDisconnected", __nid__ = nid});
	elseif (msg.code == NPLReturnCode.NPL_ConnectionEstablished) then
        -- 链接建立 客户端才会触发此事件
	end
end);