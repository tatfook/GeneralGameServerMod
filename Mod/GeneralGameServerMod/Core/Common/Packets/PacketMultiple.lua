--[[
Title: PacketMultiple
Author(s): wxa
Date: 2020/7/13
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketMultiple.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketMultiple");
local packet = Packets.PacketMultiple:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
local PacketMultiple = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketMultiple"));

function PacketMultiple:ctor()
end

function PacketMultiple:Init(packets, action)
	self.action = action;
    self.packets = packets;
	return self;
end

function PacketMultiple:WritePacket()
	local msg = PacketMultiple._super.WritePacket(self);
	local packets = msg.packets;
	if(packets) then
		for i=1, #packets do
			packets[i] = packets[i]:WritePacket();
		end
	end
	return msg;
end

-- 需重写读包函数
function PacketMultiple:ReadPacket(msg)
	PacketMultiple._super.ReadPacket(self, msg);
	local packets = self.packets;
	if (packets) then
		for i=1, #packets do
			local packet = PacketTypes:GetNewPacket(packets[i].id);
			if (packet) then packet:ReadPacket(packets[i]); end
			packets[i] = packet;
		end
	end
end

-- Passes this Packet on to the NetHandler for processing.
function PacketMultiple:ProcessPacket(net_handler)
	if(net_handler.handleMultiple) then
		return net_handler:handleMultiple(self);
	end

	local packets = self.packets;
	if(packets) then
		for i=1, #packets do
			local packet = packets[i];
			if(packet) then
				packet:ProcessPacket(net_handler);
			else
				net_handler:handleMsg(packet);
			end
		end
	end
end