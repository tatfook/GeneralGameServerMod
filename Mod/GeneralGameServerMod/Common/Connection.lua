--[[
Title: ConnectionBase
Author(s): wxa
Date: 2014/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/ConnectionBase.lua");
local ConnectionBase = commonlib.gettable("Mod.GeneralGameServerMod.Common.ConnectionBase");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
NPL.load("Mod/GeneralGameServerMod/Server/ServerListener.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Packets/ConnectionBase.lua");

local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketTypes");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local ServerListener = commonlib.gettable("Mod.GeneralGameServerMod.Server.ServerListener");
local Connection = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionBase"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection"));

Connection.default_neuron_file = "Mod/GeneralGameServerMod/Common/Connection.lua";

function Connection:Init(nid, net_handler)
	self:SetNid(nid);
	self:SetNetHandler(net_handler);
	return self;
end


function Connection:AddPacketToSendQueue(packet)
	-- LOG.debug("---------------------send packet: %d--------------------", packet:GetPacketId());
	-- LOG.debug(packet);
	return self._super.AddPacketToSendQueue(self, packet);
end

function Connection:OnNetReceive(msg)
	local packet = PacketTypes:GetNewPacket(msg.id);
	if(packet) then
		packet:ReadPacket(msg);
		packet:ProcessPacket(self.net_handler);
	else
		self.net_handler:handleMsg(msg);
	end
end

local function activate()
	local msg = msg;
	local id = msg.nid or msg.tid;

	-- LOG.debug("---------------------recv packet--------------------");
	-- LOG.debug(msg);

	if(id) then
		local connection = Connections:GetConnection(id);
		if(connection) then
			connection:OnNetReceive(msg);
		elseif(msg.tid) then
			-- this is an incoming connection. let the server listener to handle it. 
			ServerListener:OnAcceptIncomingConnection(msg);
		end
	end
end

NPL.this(activate);
