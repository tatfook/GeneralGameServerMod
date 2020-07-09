--[[
Title: PacketPlayerEntityInfo
Author(s): wxa
Date: 2020/6/15
Desc: 玩家实体包列表
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerLogin.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketPlayerEntityInfoList");
local packet = Packets.PacketPlayerEntityInfoList:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerEntityInfo.lua");
local PacketPlayerEntityInfo = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketPlayerEntityInfo");
local PacketPlayerEntityInfoList = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketPlayerEntityInfoList"));

function PacketPlayerEntityInfoList:ctor()
end

function PacketPlayerEntityInfoList:Init(entityInfoList)
    self.playerEntityInfoList = entityInfoList or {};
	return self;
end

-- virtual: read packet from network msg data
function PacketPlayerEntityInfoList:ReadPacket(msg)
	self.playerEntityInfoList = {};
    for i = 1, #(msg.playerEntityInfoList or {}) do
		self.playerEntityInfoList[i] = PacketPlayerEntityInfo:new():Init();
		self.playerEntityInfoList[i]:ReadPacket(msg.playerEntityInfoList[i]);
	end
end

-- virtual: By default, the packet itself is used as the raw message. 
-- @return a packet to be send. 
function PacketPlayerEntityInfoList:WritePacket()
	for i = 1, #(self.playerEntityInfoList or {}) do
		self.playerEntityInfoList[i] = (self.playerEntityInfoList[i]):WritePacket();
	end
	return self._super.WritePacket(self);
end
-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerEntityInfoList:ProcessPacket(net_handler)
	if(net_handler.handlePlayerEntityInfoList) then
		net_handler:handlePlayerEntityInfoList(self);
	end
end
