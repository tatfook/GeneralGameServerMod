--[[
Title: Connection
Author(s): wxa
Date: 2020/6/12
Desc: connection
use the lib:
-------------------------------------------------------
local Connection = NPL.load("Mod/GeneralGameServerMod/CommonLib/Connection.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/System.lua");

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local Connection = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local __neuron_file__ = "Mod/GeneralGameServerMod/CommonLib/Connection.lua";
local __nid_thread_map__ = {};                      -- 连接线程映射表
local __all_connections__ = {};                     -- 所有连接
local __main_thread_name__ = "main";                -- 主线程名
-- local __event_emitter__ = EventEmitter:new();       -- 事件触发器

Connection:Property("Nid");                                     -- 连接标识符

-- 公开接口文件
CommonLib.AddPublicFile(__neuron_file__);

function Connection:ctor()
	self.__timer__ = commonlib.Timer:new();
	self.__event_emitter__ = EventEmitter:new();       -- 事件触发器
	self.__all_virtual_connection__ = {};              -- 关联的虚拟链接
end

-- 初始化
function Connection:Init(nid)
	__all_connections__[nid] = self;
	self:SetNid(nid);

	-- 通知主线程
	NPL.activate(string.format("(%s)%s", __main_thread_name__, __neuron_file__), {__cmd__ = "__connected__", __thread_name__ = __rts__:GetName(), __nid__ = self:GetNid()});

	return self;
end

-- 连接是否关闭
function Connection:IsClose()
	return self:GetNid() == nil;
end

function Connection:AddVirtualConnection(virtual_connection)
	self.__all_virtual_connection__[virtual_connection] = virtual_connection;
end

function Connection:RemoveVirtualConnection(virtual_connection)
	self.__all_virtual_connection__[virtual_connection] = nil;
end

function Connection:GetVirtualConnectionCount()
	local count = 0;
	for _ in pairs(self.__all_virtual_connection__) do count = count + 1 end
	return count;
end

-- 关闭连接
function Connection:Close(reason)
	-- 断开链接
	NPL.reject({["nid"] = self:GetNid(), ["reason"] = reason});
	-- 置空链接
	__all_connections__[self:GetNid()] = nil;
	-- 置空链接标识符
	self:SetNid(nil);
	-- 触发回调
	self:HandleClosed();
end

-- 获取地址
function Connection:GetRemoteAddress(threadname, neuronfile)
	return string.format("(%s)%s:%s", threadname or __main_thread_name__, self:GetNid(), neuronfile or __neuron_file__);
end

-- 发送消息
function Connection:Send(msg, threadname, neuronfile, callback)
	if (not self:GetNid()) then return end
	local address = self:GetRemoteAddress(threadname, neuronfile);
	-- print("Connection:Send", address);
	local result = NPL.activate(address, msg);
	if (result ~= 0) then
		local timeout = 500;
		local function OnTimer()
			if (not self:GetNid()) then return end
			timeout = timeout + timeout;
			address = self:GetRemoteAddress(threadname, neuronfile);
			result = NPL.activate(address, msg);
			if (result ~= 0) then 
				self.__timer__:Change(timeout);
			else 
				self.__timer__.callbackFunc = nil;
				self.__timer__:Change(nil);
				if (type(callback) == "function") then callback() end
			end
		end
		self.__timer__.callbackFunc = OnTimer;
		self.__timer__:Change(timeout);
	else
		if (type(callback) == "function") then callback() end
	end
end

-- 链接关闭
function Connection:OnClosed(...)
	self.__event_emitter__:RegisterEventCallBack("__closed__", ...)
end

-- 链接关闭
function Connection:OffClosed(...)
	self.__event_emitter__:RemoveEventCallBack("__closed__", ...)
end

function Connection:HandleClosed(...)
	self.__event_emitter__:TriggerEventCallBack("__closed__", ...)
end

-- 连接断开
function Connection:OnDisconnected(...)
	self.__event_emitter__:RegisterEventCallBack("__disconnected__", ...)
end

function Connection:OffDisconnected(...)
	self.__event_emitter__:RemoveEventCallBack("__disconnected__", ...)
end

-- 处理链接断开
function Connection:HandleDisconnected(msg)
	self.__event_emitter__:TriggerEventCallBack("__disconnected__", msg);
end

-- 接受消息
function Connection:OnMsg(...)
	self.__event_emitter__:RegisterEventCallBack("__msg__", ...);
end

function Connection:OffMsg(...)
	self.__event_emitter__:RemoveEventCallBack("__msg__", ...);
end

-- 处理消息
function Connection:HandleMsg(msg)
	self.__event_emitter__:TriggerEventCallBack("__msg__", msg);
end

-- 获取连接
function Connection:GetConnectionByNid(nid)
	__all_connections__[nid] = __all_connections__[nid] or Connection:new():Init(nid);
	return __all_connections__[nid];
end

function Connection:OnActivate(msg)
	local nid = msg and (msg.nid or msg.tid);
	if (nid) then return self:GetConnectionByNid(nid):HandleMsg(msg) end

	local __cmd__ = msg and msg.__cmd__;
	if (__cmd__ == "__connected__") then
		__nid_thread_map__[msg.__nid__] = msg.__thread_name__; 
	elseif (__cmd__ == "__disconnected__") then
		self:GetConnectionByNid(msg.__nid__):HandleDisconnected(msg);
	else 
	end
end

-- 激活函数
NPL.this(function() 
	Connection:OnActivate(msg);
end);

-- 注册主线程网络消息回调
CommonLib.OnNetworkEvent(function(msg) 
	local nid = msg and (msg.nid or msg.tid);
	if (not nid) then return end 

	if(msg.code == NPLReturnCode.NPL_ConnectionDisconnected) then
		NPL.activate(string.format("(%s)%s",  __nid_thread_map__[nid] or __main_thread_name__, __neuron_file__), {__cmd__ = "__disconnected__", __nid__ = nid});
	elseif (msg.code == NPLReturnCode.NPL_ConnectionEstablished) then
        -- 链接建立 客户端才会触发此事件
	end
end);
