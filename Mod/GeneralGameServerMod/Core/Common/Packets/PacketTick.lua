--[[
Title: PacketTick
Author(s): wxa
Date: 2020/6/16
Desc: 心跳包
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketBlock.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTick");
local packet = Packets.PacketTick:new():Init();
-------------------------------------------------------
]]

local Packet = NPL.load("./Packet.lua");
local PacketTick = commonlib.inherit(Packet, NPL.export());

local PacketId = 107;
function PacketTick:GetPacketId()
    return PacketId;
end

function PacketTick:ctor()
end

function PacketTick:Init()
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketTick:ProcessPacket(net_handler)
	if(net_handler.handleTick) then
		net_handler:handleTick(self);
	end
end