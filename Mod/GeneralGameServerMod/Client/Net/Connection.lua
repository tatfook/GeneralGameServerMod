--[[
Title: Connection
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
local Connection = NPL.load("Mod/GeneralGameServerMod/Client/Net/Connection.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/event_mapping.lua");

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local Connection = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local __remote_file__ = "Mod/GeneralGameServerMod/Server/Net/Connection.lua";
local __local_file__ = "Mod/GeneralGameServerMod/Client/Net/Connection.lua";

Connection:Property("ThreadName", "gl");
Connection:Property("RemoteNeuronFile", __remote_file__);   -- 对端处理文件
Connection:Property("LocalNeuronFile", __local_file__);     -- 本地处理文件

local __event_emitter__ = EventEmitter:new();       -- 事件触发器
local __is_connected__ = {};                        -- 是否已连接
local __is_connecting__ = {};                       -- 是否正在连接

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

function Connection:Init(opts)
    if (type(opts) ~= "table") then return self end
    if (opts.threadName) then self:SetThreadName(opts.threadName) end
    if (opts.remoteNeuronFile) then self:SetRemoteNeuronFile(opts.remoteNeuronFile) end
    if (opts.localNeuronFile) then self:SetLocalNeuronFile(opts.localNeuronFile) end
    
    if (opts.nid) then 
        self:SetNid(opts.nid);
    elseif (opts.ip and opts.port) then
		self:SetIpAndPort(opts.ip, opts.port);
	end

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

function Connection:SetIpAndPort(ip, port)
	self:SetNid(CommonLib.AddNPLRuntimeAddress(ip, port));
end

function Connection:GetRemoteAddress(neuronfile)
	return string.format("(%s)%s:%s", self:GetThreadName() or "gl", self:GetNid() or "", neuronfile or self:GetRemoteNeuronFile());
end

local __connect_packet__ = {__cmd__ = "__init__", __file__ = __local_file__};
function Connection:Connect(callback)
	local nid = self:GetNid();
	-- 地址不存在
	if (not nid) then return end
	-- 已处于链接状态
	if (__is_connected__[nid]) then return callback() end
	-- 正在连接中
	if (__is_connecting__[nid]) then return table.insert(__is_connecting__[nid], #(__is_connecting__[nid]), callback) end
	-- 标记连接中
	__is_connecting__[nid] = {callback};

	local address = self:GetRemoteAddress(__remote_file__);
	local timeout, max_timeout = 10, 1000 * 60 *2;

	commonlib.Timer:new({callbackFunc = function(timer)
		if(NPL.activate(address, __connect_packet__) == 0) then
			-- 标记连接成功
			__is_connected__[nid] = true;

			-- 触发连接回调
			for _, func in ipairs(__is_connecting__) do 
				if (type(func) == "function") then func() end 
			end

			-- 取消连接中标志
			__is_connecting__[nid] = nil;
			return ;
		end
		timeout = math.min(timeout + timeout, max_timeout);
		timer:Change(timeout, nil);
	end}):Change(timeout, nil);
end

function Connection:Disconnect()
	AllConnections[self:GetNid()] = nil;
	self:OnDisconnected();
end

-- 关闭连接
function Connection:Close(reason)
	NPL.reject({["nid"] = self:GetNid(), ["reason"] = reason});
	__event_emitter__:TriggerEventCallBack("__on_disconnected", {nid = self:GetNid()});
end

function Connection:Send(data, neuronfile)
	if (not self:IsConnected()) then return end
	local address = self:GetRemoteAddress(neuronfile);
	local ret = NPL.activate(address, {__cmd__ = "__msg__", __file__ = self:GetLocalNeuronFile(), __data__ = data});
	if(ret ~= 0) then LOG.std(nil, "warn", "Connection", "unable to send to %s.", self:GetNid()) end
end

function Connection:IsConnected()
	return __is_connected__[self:GetNid()];
end

-- 发送消息
function Connection:OnSend(msg, neuronfile)
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

NPL.this(function() 
	__event_emitter__:TriggerEventCallBack("__on_msg__", msg);
end);

-- c++ callback function. 
CommonLib.OnNetworkEvent(function(msg) 
	local nid = msg.nid or msg.tid;
	echo(msg);
	if(msg.code == NPLReturnCode.NPL_ConnectionDisconnected) then
		print("------------NPL_ConnectionDisconnected---------")
		__event_emitter__:TriggerEventCallBack("__on_disconnected__", msg);
	elseif (msg.code == NPLReturnCode.NPL_ConnectionEstablished) then
		print("------------NPL_ConnectionEstablished---------")
		__event_emitter__:TriggerEventCallBack("__on_connected__", msg);
	end
end);

-- NPL_OK = 0, 
-- NPL_Error, 
-- NPL_ConnectionNotEstablished,
-- NPL_QueueIsFull,
-- NPL_StreamError,
-- NPL_RuntimeState_NotExist,
-- NPL_FailedToLoadFile,
-- NPL_RuntimeState_NotReady,
-- NPL_FileAccessDenied,
-- NPL_ConnectionEstablished,
-- NPL_UnableToResolveName,
-- NPL_ConnectionTimeout,
-- NPL_ConnectionDisconnected,
-- NPL_ConnectionAborted,
-- NPL_Command,
-- NPL_WrongProtocol