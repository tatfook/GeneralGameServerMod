--[[
Title: PacketBlock
Author(s): wxa
Date: 2020/6/16
Desc: 方块同步
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketBlock.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketBlock");
local packet = Packets.PacketBlock:new():Init();
-------------------------------------------------------
]]

local Packet = NPL.load("./Packet.lua");
local PacketBlock = commonlib.inherit(Packet, NPL.export());

function PacketBlock:GetPacketId()
    return 104;
end

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
		local packet = self:GetPacket(self.blockEntityPacketData.id);
		if (packet) then 
			packet:ReadPacket(self.blockEntityPacketData); 
			self.blockEntityPacket = packet;
			self.blockEntityPacketData = nil;
		end
	end

	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketBlock:ProcessPacket(net_handler)
	if(net_handler.handleBlock) then
		net_handler:handleBlock(self);
	end
end
