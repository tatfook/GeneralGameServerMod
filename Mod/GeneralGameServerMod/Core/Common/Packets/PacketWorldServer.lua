--[[
Title: PacketWorldServer
Author(s): wxa
Date: 2020/6/22
Desc: 世界服务选择包
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketWorldServer.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketWorldServer");
local packet = Packets.PacketWorldServer:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");

local PacketWorldServer = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketWorldServer"));

function PacketWorldServer:ctor()
end

function PacketWorldServer:Init(packet)
	-- client
	self.worldId = packet.worldId;
	self.worldName = packet.worldName;

	-- server
	self.ip = packet.ip;
	self.port = packet.port;
	self.worldKey = packet.worldKey;
	self.threadName = packet.threadName;

	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketWorldServer:ProcessPacket(net_handler)
	if(net_handler.handleWorldServer) then
		net_handler:handleWorldServer(self);
	end
end
