--[[
Title: ConnectionBase
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/NetServerHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local NetServerHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.NetServerHandler");
local Connection = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection"));
local defaultNeuronFile = "Mod/GeneralGameServerMod/Core/Common/Connection.lua";
local moduleName = "Mod.GeneralGameServerMod.Core.Common.Connection";
local nextNid = 100;

Connection.default_neuron_file = defaultNeuronFile;

local function NetLog(...)
	local debug = GGS.Debug.GetNetDebug();
	debug(...);
end

-- 服务端初始化方式
function Connection:Init(nid, net_handler)
	self:SetNid(nid);
	self:SetNetHandler(net_handler);
	return self;
end

-- 客户端初始化方式
function Connection:InitByIpPort(ip, port, net_handler)
	nextNid = nextNid + 1;
	local nid = "ggs_" .. tostring(nextNid);
	NPL.AddNPLRuntimeAddress({host = tostring(ip), port = tostring(port), nid = nid});
	
	return self:Init(nid, net_handler, neuron_file);
end

-- 获取连接ID
function Connection:GetId() 
	return self.id;
end

-- inform the netServerHandler about an error.
-- @param text: this is usually "OnConnectionLost" from ServerListener. or "ConnectionNotEstablished" from client
function Connection:OnError(text)
	if(self.net_handler and self.net_handler.handleErrorMessage) then
		self.net_handler:handleErrorMessage(text, self);
	end
end

function Connection:AddPacketToSendQueue(packet)
	NetLog(string.format("---------------------send packet: %d--------------------", packet:GetPacketId()), packet:WritePacket());
	-- Log:Std("DEBUG", moduleName, "---------------------send packet: %d--------------------", packet:GetPacketId());
	-- Log:Std("DEBUG", moduleName, packet:WritePacket());

	return Connection._super.AddPacketToSendQueue(self, packet);
end

-- 接受数据包
function Connection:OnNetReceive(msg)
	-- 处理数据包前回调
	if (self.net_handler and self.net_handler.OnBeforeProcessPacket) then
		self.net_handler:OnBeforeProcessPacket(msg);
	end

	local packet = PacketTypes:GetNewPacket(msg.id);
	NetLog(string.format("---------------------recv packet: %s--------------------", packet and packet:GetPacketId() or msg.id), msg);
	-- Log:Std("DEBUG", moduleName, "---------------------recv packet: %d--------------------", packet and packet:GetPacketId() or msg.id);
	-- Log:Std("DEBUG", moduleName, msg);
	
	if(packet) then
		packet:ReadPacket(msg);
		packet:ProcessPacket(self.net_handler);
	else
		Log:Info("invalid packet");
		if (self.net_handler.handleMsg) then
			self.net_handler:handleMsg(msg);
		else 
			Log:Info("invalid msg");
			Log:Info(msg);
		end
	end

	-- 处理数据包后回调
	if (self.net_handler and self.net_handler.OnAfterProcessPacket) then
		self.net_handler:OnAfterProcessPacket(packet or msg);
	end
end

local function activate()
	local msg = msg;
	local id = msg.nid or msg.tid;

	local connection = Connections:GetConnection(id);
	if (connection) then
		connection:OnNetReceive(msg);
	else 
		NetServerHandler:new():Init(id);
	end
end

NPL.this(activate);
