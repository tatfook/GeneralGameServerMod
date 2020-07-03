--[[
Title: ConnectionBase
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
NPL.load("Mod/GeneralGameServerMod/Server/NetServerHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketTypes");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local NetServerHandler = commonlib.gettable("Mod.GeneralGameServerMod.Server.NetServerHandler");
local Connection = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionBase"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection"));
local defaultNeuronFile = "Mod/GeneralGameServerMod/Common/Connection.lua";
local moduleName = "Mod.GeneralGameServerMod.Common.Connection";
local nextNid = 100;

Connection.default_neuron_file = defaultNeuronFile;

-- 服务端初始化方式
function Connection:Init(nid, net_handler)
	self:SetNid(nid);
	self:SetNetHandler(net_handler);
	return self;
end

-- 客户端初始化方式
function Connection:InitByIpPort(ip, port, net_handler)
	nextNid = nextNid + 1;
	local nid = tostring(nextNid);
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
	Log:Std("DEBUG", moduleName, "---------------------send packet: %d--------------------", packet:GetPacketId());
	Log:Std("DEBUG", moduleName, packet);
	return self._super.AddPacketToSendQueue(self, packet);
end

-- 接受数据包
function Connection:OnNetReceive(msg)
	local packet = PacketTypes:GetNewPacket(msg.id);
	
	Log:Std("DEBUG", moduleName, "---------------------recv packet: %d--------------------", packet:GetPacketId());
	Log:Std("DEBUG", moduleName, msg);

	if(packet) then
		packet:ReadPacket(msg);
		packet:ProcessPacket(self.net_handler);
	else
		if (self.net_handler.handleMsg) then
			self.net_handler:handleMsg(msg);
		else 
			Log:Info("invalid msg");
			Log:Info(msg);
		end
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
