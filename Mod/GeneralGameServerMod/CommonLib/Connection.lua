--[[
Title: Connection
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
local Connection = NPL.load("Mod/GeneralGameServerMod/CommonLib/Connection.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/event_mapping.lua");

local CommonLib = NPL.load("./CommonLib.lua");
local Connection = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local ConnectionThread = {};  -- 链接所在线程
local AllConnections = {};    -- 线程所有链接
local NextConnectionId = 0;

Connection:Property("ConnectionId", 0);
Connection:Property("Nid", "");
Connection:Property("ThreadName", "gl");
Connection:Property("RemoteNeuronFile", "Mod/GeneralGameServerMod/CommonLib/Connection.lua");   -- 对端处理文件
Connection:Property("LocalNeuronFile", "Mod/GeneralGameServerMod/CommonLib/Connection.lua");    -- 本地处理文件
Connection:Property("ConnectionClosed", false, "IsConnectionClosed");                           -- 是否已关闭
Connection:Property("SynchronousSend", false, "IsSynchronousSend");                             -- 是否采用同步发送数据包模式
Connection:Property("SynchronousSendTimeout", 3);                                               -- 同步发送超时时间


function Connection:ctor()
    NextConnectionId = NextConnectionId + 1;
	self:SetConnectionId(NextConnectionId);
	self:SetConnectionClosed(true);
end

-- get ip address. return nil or ip address
function Connection:GetIPAddress()
	return NPL.GetIP(self:GetNid());
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

function Connection:SetIpAndPort(ip, port)
	ip = tostring(ip or "127.0.0.1");
	port = tostring(port or "9000");
	local nid = string.format("%s_%s", ip, port);
	NPL.AddNPLRuntimeAddress({host = ip, port = port, nid = nid});
	self:SetNid(nid);
end

function Connection:GetRemoteAddress(neuronfile)
	return string.format("(%s)%s:%s", self:GetThreadName() or "gl", self:GetNid() or "", neuronfile or self:GetRemoteNeuronFile());
end

function Connection:Connect(callback)
	if (self.__connecting__ or not self:IsConnectionClosed()) then return end 
	self.__connecting__ = true;

	local address = self:GetRemoteAddress();
	local data = {thread_name = __rts__:GetName(), neuron_file = self:GetLocalNeuronFile(), action = "__connect__"};
	local timeout, max_timeout = 10, 1000 * 60 *2;

	commonlib.Timer:new({callbackFunc = function(timer)
		if(NPL.activate(address, data) == 0) then
			-- 连接成功放入链接池
			AllConnections[self:GetNid()] = self;
			-- 取消连接中标志
			self.__connecting__ = false;
			-- 标记连接成功
			self:SetConnectionClosed(false);
			-- 回调函数
			callback(true);
			-- 连接成功回调
			self:OnConnected();
			return ;
		end
		timeout = math.min(timeout + timeout, max_timeout);
		timer:Change(timeout, nil);
	end}):Change(timeout, nil);
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
function Connection:Send(msg, neuronfile)
	if (self:IsConnectionClosed()) then return end
	
    msg, neuronfile = self:OnSend(msg, neuronfile);

	local address = self:GetRemoteAddress(neuronfile);
	local ret = 0;
	if (self:IsSynchronousSend()) then
		ret = NPL.activate_with_timeout(self:GetSynchronousSendTimeout(), address, msg);
	else
		ret = NPL.activate(address, msg);
	end

	if(ret ~= 0) then
		LOG.std(nil, "warn", "Connection", "unable to send to %s.", self:GetNid());
		self:CloseConnection("发包失败");
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
	local connection = AllConnections[nid];
    -- 链接已存在 直接处理消息
	if(connection) then return connection:OnReceive(msg) end

	-- 新建连接
	connection = self:new():Init({nid=nid, threadName = msg.thread_name, remoteNeuronFile = msg.neuron_file});
	-- 放入链接池
	AllConnections[connection:GetNid()] = connection;
	-- 通知主线程
	NPL.activate("(main)Mod/GeneralGameServerMod/CommonLib/Connection.lua", {action = "ConnectionEstablished", threadName = __rts__:GetName(), ConnectionNid = self:GetNid()});
	connection:OnConnected();
end

function Connection:handleMsg(msg)
end

NPL.this(function() 
	local nid = msg and (msg.nid or msg.tid);
	local action = msg and msg.action;
	local threadName = __rts__:GetName();
	if (nid) then return Connection:OnActivate(msg) end
	
	if (action == "ConnectionEstablished") then
		ConnectionThread[msg.ConnectionNid] = msg.threadName; 
	elseif (action == "ConnectionDisconnected") then
		local connection = AllConnections[msg.ConnectionNid];
		if (connection) then connection:Close() end
	else 
		Connection:handleMsg(msg);
	end
end);

-- c++ callback function. 
CommonLib.OnNetworkEvent(function(msg) 
	local nid = msg.nid or msg.tid;
	local threadName = ConnectionThread[nid] or "main";
	local connection = AllConnections[nid];
	if(msg.code == NPLReturnCode.NPL_ConnectionDisconnected) then
		-- 链接断开
        NPL.activate(string.format("(%s)Mod/GeneralGameServerMod/CommonLib/Connection.lua", threadName), {action = "ConnectionDisconnected", ConnectionNid = nid});
	elseif (msg.code == NPLReturnCode.NPL_ConnectionEstablished) then
        -- 链接建立
		-- if (connection) then connection:OnConnected() end
	end
end);