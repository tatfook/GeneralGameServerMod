--[[
Title: PacketTick
Author(s): wxa
Date: 2020/6/28
Desc: 通用数据包
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketGeneral.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketGeneral");
local packet = Packets.PacketGeneral:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");

local PacketGeneral = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketGeneral"));

function PacketGeneral:ctor()
end

function PacketGeneral:Init(packet)
    self.action = packet.action;
    self.data = packet.data;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketGeneral:ProcessPacket(net_handler)
	if (self.action == "DATA" and type(net_handler.handleData) == "function") then
		net_handler:handleData(self.data);
	elseif(net_handler.handleGeneral) then
		net_handler:handleGeneral(self);
	end
end

function PacketGeneral:GetDataPacket(data)
	return PacketGeneral:new():Init({
		action = "DATA",
		data = data,
	})
end

function PacketGeneral:GetReloginPacket(data)
	return PacketGeneral:new():Init({
		action = "RELOGIN",
		data = data,
	})
end

function PacketGeneral:IsReloginPacket()
	return self.action == "RELOGIN";
end
