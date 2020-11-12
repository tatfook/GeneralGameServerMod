--[[
Title: ConnectionBase
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua");
local ConnectionBase = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.ConnectionBase");
-------------------------------------------------------
]]

local ConnectionBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local ConnectionThread = {};  -- 链接所在线程
local AllConnections = {};    -- 线程所有链接
local NextConnectionId = 0;

ConnectionBase:Property("ConnectionId", 0);
ConnectionBase:Property("Nid", "");
ConnectionBase:Property("ThreadName", "gl");
ConnectionBase:Property("DefaultNeuronFile", "Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua");
ConnectionBase:Property("ConnectionClosed", false, "IsConnectionClosed");

function ConnectionBase:ctor()
    NextConnectionId = NextConnectionId + 1;
	self:SetConnectionId(NextConnectionId);
end

-- get ip address. return nil or ip address
function ConnectionBase:GetIPAddress()
	return NPL.GetIP(self:GetNid());
end

function ConnectionBase:Init(opts)
    if (type(opts) ~= "table") then return self end
    if (opts.threadName) then self:SetThreadName(opts.threadName) end
    if (opts.defaultNeuronFile) then self:SetDefaultNeuronFile(opts.defaultNeuronFile) end
    
    if (opts.nid) then 
        self:SetNid(opts.nid);
    elseif (opts.ip and opts.port) then
        self:SetNid("ggs_" .. tostring(self:GetConnectionId()));
        NPL.AddNPLRuntimeAddress({host = tostring(opts.ip), port = tostring(opts.port), nid = self:GetNid()});
    end

    AllConnections[self:GetNid()] = self;

    return self;
end

function ConnectionBase:GetRemoteAddress(neuronfile)
	return string.format("(%s)%s:%s", self:GetThreadName() or "gl", self:GetNid() or "", neuronfile or self:GetDefaultNeuronFile());
end

local ping_msg = {url = "ping",};
-- this function is only called for a client to establish a connection with remote server.
-- on the server side, accepted connections never need to call this function. 
-- @param timeout: the number of seconds to timeout. if 0, it will just ping once. 
-- @param callback_func: a function(bSuccess) end.  If this function is provided, this function is asynchronous. 
function ConnectionBase:Connect(timeout, callback_func)
	if(self.is_connecting) then return end
	self.is_connecting = true;
	local address = self:GetRemoteAddress();
	if(not callback_func) then
		-- if no call back function is provided, this function will be synchronous. 
		if( NPL.activate_with_timeout(timeout or 1, address, ping_msg) ~=0 ) then
			self.is_connecting = nil;
			LOG.std("", "warn", "Connection", "failed to connect to server %s", self:GetNid());
		else
			self.is_connecting = nil;
			LOG.std("", "warn", "Connection", "connection with %s is established", self:GetNid());	
			self:SetConnectionClosed(false);
			return 0;
		end
	else
		-- if call back function is provided, we will do asynchronous connect. 
		local intervals = {100, 300,500, 1000, 1000, 1000, 1000}; -- intervals to try
		local try_count = 0;
		
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			try_count = try_count + 1;
			if(NPL.activate(address, ping_msg) ~=0) then
				if(intervals[try_count]) then
					timer:Change(intervals[try_count], nil);
				else
					-- timed out. 
					self.is_connecting = nil;
					callback_func(false);
					self:CloseConnection("ConnectionNotEstablished");
				end	
			else
				-- connected 
				self.is_connecting = nil;
				self:SetConnectionClosed(false);
				callback_func(true)
			end
		end})
		mytimer:Change(10, nil);
		return 0;
	end
end

-- send message immediately to c++ queue
-- @param msg: the raw message table {id=packet_id, .. }. 
-- @param neuronfile: should be nil. By default, it is this file. 
function ConnectionBase:Send(msg, neuronfile)
    self:OnSend(msg, neuronfile);
end

-- 关闭连接
function ConnectionBase:CloseConnection(reason)
	NPL.reject({["nid"] = self:GetNid(), ["reason"] = reason});
	AllConnections[self:GetNid()] = nil;
    self:SetConnectionClosed(true);
    self:OnClose(reason);
end

-- 发送消息
function ConnectionBase:OnSend(msg, neuronfile)
    if (self:IsConnectionClosed()) then return end
	local address = self:GetRemoteAddress(neuronfile);
    if(NPL.activate(address, msg) ~= 0) then
        LOG.std(nil, "warn", "Connection", "unable to send to %s.", self:GetNid());
        self:CloseConnection("发包失败");
    end
end

-- 接受消息
function ConnectionBase:OnReceive(msg)
end

-- 链接关闭
function ConnectionBase:OnClose()
end

-- 新链接
function ConnectionBase:OnConnection()
	NPL.activate("(main)Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua", {action = "ConnectionEstablished", threadName = __rts__:GetName(), ConnectionNid = nid});
end

-- 获取连接
function ConnectionBase:GetConnectionByNid(nid)
	return AllConnections[nid];
end

-- 网络事件
commonlib.setfield("ConnectionBase_", ConnectionBase);
NPL.RegisterEvent(0, "_n_Connections_network", ";ConnectionBase_.OnNetworkEvent();");
-- NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua", 400);

-- c++ callback function. 
function ConnectionBase.OnNetworkEvent()
    local nid = msg.nid or msg.tid;
	local threadName = ConnectionThread[nid] or "main";
	if(msg.code == NPLReturnCode.NPL_ConnectionDisconnected) then
		NPL.activate(string.format("(%s)Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua", threadName), {action = "ConnectionDisconnected", ConnectionNid = nid});
	else
	end
end

function ConnectionBase:OnActivate(msg)
	local nid = msg and (msg.nid or msg.tid);
	if (not nid) then return end
	local connection = AllConnections[nid];
    if(connection) then return connection:OnReceive(msg) end
	
	self:new():Init({nid=nid}):OnConnection();
end


NPL.this(function() 
	local nid = msg and (msg.nid or msg.tid);
	local action = msg and msg.action;
	local threadName = __rts__:GetName();

	if (nid) then return ConnectionBase:OnActivate(msg) end

	if (action == "ConnectionEstablished") then
		ConnectionThread[msg.ConnectionNid] = msg.threadName; 
	elseif (action == "ConnectionDisconnected") then
		local connection = AllConnections[msg.ConnectionNid];
		if (connection) then connection:CloseConnection("链接断开") end
	end
end);
