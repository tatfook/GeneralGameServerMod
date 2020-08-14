--[[
Title: PacketBlock
Author(s): wxa
Date: 2020/6/16
Desc: 方块同步
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketBlock.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketBlock");
local packet = Packets.PacketBlockInfoList:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
local PacketBlock = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketBlock"));

function PacketBlock:ctor()
end

function PacketBlock:Init(packet)
	self.blockIndex = packet.blockIndex;
	self.blockId = packet.blockId;
	self.blockData = packet.blockData;
	self.blockFlag = packet.blockFlag;
	self.blockEntityPacket = packet.blockEntityPacket;

	return self;
end

function PacketBlock:WritePacket()
	local msg = PacketBlock._super.WritePacket(self);

	if (msg.blockEntityPacket) then
		msg.blockEntityPacketData = msg.blockEntityPacket:WritePacket();   -- 旧数据包这里不会包含Id
		msg.blockEntityPacketData.id = msg.blockEntityPacket:GetPacketId();
		msg.blockEntityPacket = nil;
	end

	return msg;
end

-- 需重写读包函数
function PacketBlock:ReadPacket(msg)
	PacketBlock._super.ReadPacket(self, msg);

	if (self.blockEntityPacketData) then
		local packet = PacketTypes:GetNewPacket(self.blockEntityPacketData.id);
		if (packet) then 
			packet:ReadPacket(self.blockEntityPacketData);
		end
		self.blockEntityPacket = packet;
		self.blockEntityPacketData = nil;
	end

	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketBlock:ProcessPacket(net_handler)
	if(net_handler.handleBlock) then
		net_handler:handleBlock(self);
	end
end
