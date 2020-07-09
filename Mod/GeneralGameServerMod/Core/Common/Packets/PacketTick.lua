--[[
Title: PacketTick
Author(s): wxa
Date: 2020/6/28
Desc: 维护长链接
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketTick.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketTick");
local packet = Packets.PacketTick:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");

local PacketTick = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTick"));

function PacketTick:ctor()
end

function PacketTick:Init(packet)
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketTick:ProcessPacket(net_handler)
	if(net_handler.handleTick) then
		net_handler:handleTick(self);
	end
end
