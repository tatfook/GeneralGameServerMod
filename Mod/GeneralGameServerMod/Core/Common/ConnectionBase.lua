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

local AllConnections = {};
local NextConnectionId = 0;

ConnectionBase:Property("ConnectionId", 0);
ConnectionBase:Property("Nid");
ConnectionBase:Property("ThreadName", "gl");
ConnectionBase:Property("DefaultNeuronFile", "Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua");
ConnectionBase:Property("NetHandler");
ConnectionBase:Property("ConnectionClosed", false, "IsConnectionClosed");

function ConnectionBase:ctor()
    NextConnectionId = NextConnectionId + 1;
    self:SetConnectionId(NextConnectionId);
end

function ConnectionBase:Init(opts)
    if (type(opts) ~= "table") then return self end
    if (opts.threadName) then self:SetThreadName(opts.threadName) end
    if (opts.defaultNeuronFile) then self:SetDefaultNeuronFile(opts.defaultNeuronFile) end
    if (opts.netHandler) then self:SetNetHandler(opts.netHandler) end
    
    if (opts.nid) then 
        self:SetNid(opts.nid);
        AllConnections[self:GetNid()] = self;
    end

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
					self:OnError("ConnectionNotEstablished");
				end	
			else
				-- connected 
				self.is_connecting = nil;
				callback_func(true)
			end
		end})
		mytimer:Change(10, nil);
		return 0;
	end
end

-- inform the netServerHandler about an error.
-- @param text: this is usually "OnConnectionLost" from ServerListener. or "ConnectionNotEstablished" from client
function ConnectionBase:OnError(type, reason)
    local netHandler = self:GetNetHandler();
	if(netHandler and netHandler.handleErrorMessage) then
		netHandler:handleErrorMessage(type, reason);
	end
end

-- send message immediately to c++ queue
-- @param msg: the raw message table {id=packet_id, .. }. 
-- @param neuronfile: should be nil. By default, it is this file. 
function ConnectionBase:Send(msg, neuronfile)
    if (self:IsConnectionClosed()) then return end
	local address = self:GetRemoteAddress(neuronfile);
    if(NPL.activate(address, self:OnSend(msg)) ~= 0) then
        LOG.std(nil, "warn", "Connection", "unable to send to %s.", self:GetNid());
        self:CloseConnection("发包失败");
    end
end

-- 关闭连接
function ConnectionBase:CloseConnection(reason)
    if (self:GetNid()) then 
        NPL.reject({["nid"] = self:GetNid(), ["reason"] = reason});
        AllConnections[self:GetNid()] = nil;
    end
    self:SetConnectionClosed(true);
    connection:OnError("OnConnectionLost", reason);
    self:OnClose();
end

function ConnectionBase:OnSend(msg)
    return msg;
end

function ConnectionBase:OnReceive(msg)
	-- local packet = Packet_Types:GetNewPacket(msg.id);
	-- if(packet) then
	-- 	packet:ReadPacket(msg);
	-- 	packet:ProcessPacket(self.net_handler);
	-- else
	-- 	self.net_handler:handleMsg(msg);
	-- end
end

function ConnectionBase:OnClose()
end

-- 网络事件
commonlib.setfield("ConnectionBase_", ConnectionBase);
NPL.RegisterEvent(0, "_n_Connections_network", ";ConnectionBase_.OnNetworkEvent();");
-- c++ callback function. 
function ConnectionBase.OnNetworkEvent()
    local nid = msg.nid or msg.tid;
    local msg_code = msg.code;
    local msg_msg = msg.msg or "网络事件触发";
    local connection = AllConnections[nid];
    if (not connection) then return end

    if(msg_code == NPLReturnCode.NPL_ConnectionDisconnected) then
        connection:CloseConnection("OnConnectionLost: " .. msg_msg);
	end
end

-- 连接回调
function ConnectionBase.OnConnection(id)
end

function ConnectionBase.OnActivate(msg)
	local id = msg.nid or msg.tid;
    if (not id) then return end

    local connection = AllConnections[id];
    if(connection) then
        connection:OnReceive(msg);
    else 
        ConnectionBase.OnConnection(id);
    end
end

local function activate()
    ConnectionBase.OnActivate(msg);
end

NPL.this(activate);
